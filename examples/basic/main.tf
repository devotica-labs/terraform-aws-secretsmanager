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

  # Names compose to: dvtca-sandbox-app/<key>
  namespace = "dvtca"
  stage     = "sandbox"
  name      = "app"

  # Encrypt every secret with a workload KMS key (a terraform-aws-kms output).
  kms_key_id = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"

  secrets = {
    "db-password" = { description = "Application database password" }
    "api-key"     = { description = "Third-party API key" }
  }

  tags = {
    Environment = "sandbox"
    Project     = "terraform-aws-secretsmanager"
    Owner       = "platform@devotica.com"
    CostCenter  = "PLATFORM-OSS"
    ManagedBy   = "Terraform"
    Repo        = "https://github.com/devotica-labs/terraform-aws-secretsmanager"
  }
}
