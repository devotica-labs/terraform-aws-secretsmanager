locals {
  secrets = local.enabled ? var.secrets : {}

  # Full secret name per key: explicit override, or "<prefix>/<key>".
  secret_names = {
    for k, v in local.secrets : k => coalesce(v.name_override, "${local.prefix}/${k}")
  }

  # Subsets driving the auxiliary resources (all keyed by non-sensitive keys).
  secrets_with_value    = { for k, v in local.secrets : k => v if v.set_initial_value }
  secrets_with_policy   = { for k, v in local.secrets : k => v if v.policy != null }
  secrets_with_rotation = { for k, v in local.secrets : k => v if v.rotation != null }
}

resource "aws_secretsmanager_secret" "this" {
  for_each = local.secrets

  name        = local.secret_names[each.key]
  description = each.value.description

  # Fall back to the module default, then to the AWS-managed key (null).
  kms_key_id              = try(coalesce(each.value.kms_key_id, var.kms_key_id), null)
  recovery_window_in_days = coalesce(each.value.recovery_window_in_days, var.recovery_window_in_days)

  dynamic "replica" {
    for_each = each.value.replica_regions
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = merge(local.base_tags, each.value.tags)
}

# Initial values — bootstrap only; stored in state. Driven by the non-sensitive
# `set_initial_value` flag so the sensitive map never reaches for_each.
resource "aws_secretsmanager_secret_version" "this" {
  for_each = local.secrets_with_value

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = var.secret_values[each.key]
}

resource "aws_secretsmanager_secret_policy" "this" {
  for_each = local.secrets_with_policy

  secret_arn          = aws_secretsmanager_secret.this[each.key].arn
  policy              = each.value.policy
  block_public_policy = var.block_public_policy
}

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = local.secrets_with_rotation

  secret_id           = aws_secretsmanager_secret.this[each.key].id
  rotation_lambda_arn = each.value.rotation.lambda_arn

  rotation_rules {
    automatically_after_days = each.value.rotation.automatically_after_days
    duration                 = each.value.rotation.duration
    schedule_expression      = each.value.rotation.schedule_expression
  }
}
