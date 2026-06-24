# ---------------------------------------------------------------------------
# Provider block — CI-friendly skip flags + non-AWS-shaped placeholder creds.
# ---------------------------------------------------------------------------
provider "aws" {
  region                      = "ap-south-1"
  access_key                  = "not-a-real-aws-key"
  secret_key                  = "not-a-real-aws-secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# Uses local path during development.
# Change to Registry source after first release:
#   source  = "devotica-labs/secretsmanager/aws"
#   version = "~> 0.1"

module "secrets" {
  source = "../.."

  # Names compose to: dvtca-aps1-prod-payments/<key>
  namespace   = "dvtca"
  environment = "aps1"
  stage       = "prod"
  name        = "payments"

  # Default CMK for every secret (a terraform-aws-kms output).
  kms_key_id = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"

  secrets = {
    # Rotated DB master credential.
    "db-master" = {
      description = "Payments DB master credentials (rotated)"
      rotation = {
        lambda_arn               = "arn:aws:lambda:ap-south-1:111122223333:function:rotate-rds"
        automatically_after_days = 30
      }
    }

    # Bootstrap a value once, then manage it out-of-band; replicate to DR region.
    "stripe-key" = {
      description             = "Stripe secret key"
      recovery_window_in_days = 7
      set_initial_value       = true
      replica_regions = [
        { region = "ap-southeast-1" },
      ]
    }

    # Shared read-only with another account via a scoped resource policy.
    "shared-config" = {
      description = "Config shared read-only with the analytics account"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "AllowAnalyticsRead"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::444455556666:root" }
          Action    = ["secretsmanager:GetSecretValue"]
          Resource  = "*"
        }]
      })
    }
  }

  # Bootstrap value for stripe-key (sensitive — stored in state).
  secret_values = {
    "stripe-key" = "sk_test_bootstrap_value_replace_me_1234567890"
  }

  tags = {
    Environment = "production"
    Project     = "payments"
    Owner       = "platform@devotica.com"
    CostCenter  = "PLATFORM"
    ManagedBy   = "Terraform"
    Repo        = "https://github.com/devotica-labs/terraform-aws-secretsmanager"
  }
}
