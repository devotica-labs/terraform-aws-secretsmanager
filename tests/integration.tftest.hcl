# Integration tests — apply + assert + destroy. Requires real AWS credentials.
# Triggered via workflow_dispatch on integration.yml.

provider "aws" {
  region = "ap-south-1"
}

variables {
  namespace = "dvtca"
  stage     = "integ"
  name      = "secrets"

  # recovery_window 0 so the ephemeral secrets delete immediately on teardown.
  recovery_window_in_days = 0

  secrets = {
    "integ-test" = { description = "ephemeral integration-test secret" }
  }

  tags = { Environment = "integration-test", Ephemeral = "true" }
}

run "apply_and_assert" {
  command = apply

  assert {
    condition     = aws_secretsmanager_secret.this["integ-test"].arn != ""
    error_message = "Secret must be created."
  }
  assert {
    condition     = aws_secretsmanager_secret.this["integ-test"].name == "dvtca-integ-secrets/integ-test"
    error_message = "Secret name must compose from the prefix and key."
  }
}
