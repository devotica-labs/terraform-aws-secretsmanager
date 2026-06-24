# Contract tests — naming + key behaviour stay stable across minor/patch versions.

mock_provider "aws" {}

variables {
  namespace = "dvtca"
  stage     = "test"
  name      = "contract"
  secrets = {
    "db-password" = { description = "db" }
  }
}

run "secret_name_composed_from_prefix_and_key" {
  command = plan
  assert {
    condition     = aws_secretsmanager_secret.this["db-password"].name == "dvtca-test-contract/db-password"
    error_message = "Secret name must be <namespace-stage-name>/<key>."
  }
}

run "name_override_bypasses_prefix" {
  command = plan
  variables {
    secrets = {
      "x" = { name_override = "legacy/literal-name" }
    }
  }
  assert {
    condition     = aws_secretsmanager_secret.this["x"].name == "legacy/literal-name"
    error_message = "name_override must be used verbatim."
  }
}

run "per_secret_recovery_window_override" {
  command = plan
  variables {
    secrets = {
      "fast" = { recovery_window_in_days = 7 }
    }
  }
  assert {
    condition     = tostring(aws_secretsmanager_secret.this["fast"].recovery_window_in_days) == "7"
    error_message = "Per-secret recovery_window_in_days must override the default."
  }
}
