# Plan-only unit tests — no AWS credentials required. No data sources, so an
# empty mock provider suffices.

mock_provider "aws" {}

variables {
  namespace = "dvtca"
  stage     = "test"
  name      = "unit"
  secrets = {
    "alpha" = { description = "a" }
    "beta"  = { description = "b" }
  }
}

run "secrets_created_per_map_entry" {
  command = plan
  assert {
    condition     = length(aws_secretsmanager_secret.this) == 2
    error_message = "One secret per map entry expected."
  }
}

run "recovery_window_default_30" {
  command = plan
  assert {
    condition     = tostring(aws_secretsmanager_secret.this["alpha"].recovery_window_in_days) == "30"
    error_message = "Default recovery window must be 30 days."
  }
}

run "no_aux_resources_by_default" {
  command = plan
  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 0
    error_message = "No secret version without set_initial_value."
  }
  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 0
    error_message = "No rotation without a rotation block."
  }
  assert {
    condition     = length(aws_secretsmanager_secret_policy.this) == 0
    error_message = "No policy without a policy string."
  }
}

run "kms_key_passthrough" {
  command = plan
  variables {
    kms_key_id = "arn:aws:kms:ap-south-1:111122223333:key/abc"
  }
  assert {
    condition     = aws_secretsmanager_secret.this["alpha"].kms_key_id == "arn:aws:kms:ap-south-1:111122223333:key/abc"
    error_message = "Module-level KMS key must encrypt every secret by default."
  }
}

run "per_secret_kms_overrides_module_default" {
  command = plan
  variables {
    kms_key_id = "arn:aws:kms:ap-south-1:111122223333:key/module"
    secrets = {
      "alpha" = { kms_key_id = "arn:aws:kms:ap-south-1:111122223333:key/override" }
    }
  }
  assert {
    condition     = aws_secretsmanager_secret.this["alpha"].kms_key_id == "arn:aws:kms:ap-south-1:111122223333:key/override"
    error_message = "Per-secret kms_key_id must override the module default."
  }
}

run "rotation_resource_when_configured" {
  command = plan
  variables {
    secrets = {
      "rotated" = {
        rotation = {
          lambda_arn               = "arn:aws:lambda:ap-south-1:111122223333:function:rotate"
          automatically_after_days = 30
        }
      }
    }
  }
  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 1
    error_message = "A rotation resource must be created when rotation is configured."
  }
}

run "version_resource_when_initial_value_set" {
  command = plan
  variables {
    secrets = {
      "seeded" = { set_initial_value = true }
    }
    secret_values = {
      "seeded" = "bootstrap-value-1234567890"
    }
  }
  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 1
    error_message = "A version must be created when set_initial_value = true."
  }
}

run "policy_resource_blocks_public_by_default" {
  command = plan
  variables {
    secrets = {
      "shared" = { policy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
    }
  }
  assert {
    condition     = length(aws_secretsmanager_secret_policy.this) == 1
    error_message = "A policy resource must be created when a policy is supplied."
  }
  assert {
    condition     = tostring(aws_secretsmanager_secret_policy.this["shared"].block_public_policy) == "true"
    error_message = "block_public_policy must default to true."
  }
}
