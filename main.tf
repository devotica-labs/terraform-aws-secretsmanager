locals {
  secrets = local.enabled ? var.secrets : {}

  # Effective per-secret values, computed with explicit null checks (avoid
  # coalesce(null, null) which errors on older Terraform). A null kms_key_id
  # falls through to the AWS-managed key.
  secret_names = {
    for k, v in local.secrets : k => v.name_override != null ? v.name_override : "${local.prefix}/${k}"
  }
  secret_kms = {
    for k, v in local.secrets : k => v.kms_key_id != null ? v.kms_key_id : var.kms_key_id
  }
  secret_recovery = {
    for k, v in local.secrets : k => v.recovery_window_in_days != null ? v.recovery_window_in_days : var.recovery_window_in_days
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

  kms_key_id              = local.secret_kms[each.key]
  recovery_window_in_days = local.secret_recovery[each.key]

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
