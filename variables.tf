# ---------------------------------------------------------------------------
# Secrets to manage (keyed by a short logical name)
# ---------------------------------------------------------------------------
variable "secrets" {
  type = map(object({
    # Full secret name. When null, the name is "<prefix>/<map-key>".
    name_override = optional(string)
    description   = optional(string)

    # Per-secret KMS key (overrides the module-level kms_key_id).
    kms_key_id = optional(string)

    # Per-secret deletion recovery window (overrides recovery_window_in_days).
    recovery_window_in_days = optional(number)

    # Resource policy JSON (e.g. cross-account read access).
    policy = optional(string)

    # Cross-region replicas.
    replica_regions = optional(list(object({
      region     = string
      kms_key_id = optional(string)
    })), [])

    # Lambda-based rotation. Omit to disable rotation for this secret.
    rotation = optional(object({
      lambda_arn               = string
      automatically_after_days = optional(number)
      duration                 = optional(string)
      schedule_expression      = optional(string)
    }))

    # Set true to seed an initial value from `secret_values[<key>]` at create.
    # The value is STORED IN STATE — prefer rotation; use for bootstrap only.
    set_initial_value = optional(bool, false)

    tags = optional(map(string), {})
  }))
  description = "Map of secrets to manage, keyed by a short logical name. The key becomes the secret-name suffix unless `name_override` is set."
  default     = {}

  validation {
    # Ternary (not ||) so the >= / <= comparisons never evaluate against a null
    # — Terraform's || does not short-circuit.
    condition = alltrue([
      for k, v in var.secrets :
      v.recovery_window_in_days == null ? true : (v.recovery_window_in_days == 0 || (v.recovery_window_in_days >= 7 && v.recovery_window_in_days <= 30))
    ])
    error_message = "recovery_window_in_days must be 0 (force delete) or between 7 and 30."
  }
}

variable "secret_values" {
  type        = map(string)
  description = "Optional initial plaintext values, keyed by the same keys as `secrets` (only used where `set_initial_value = true`). STORED IN TERRAFORM STATE — prefer rotation; use for bootstrap only."
  default     = {}
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Module-level defaults (Devotica fintech posture)
# ---------------------------------------------------------------------------
variable "kms_key_id" {
  type        = string
  description = "Default customer-managed KMS key (ARN or ID) used to encrypt all secrets. Per-secret `kms_key_id` overrides it. Null uses the AWS-managed `aws/secretsmanager` key — prefer a CMK from terraform-aws-kms for fintech workloads."
  default     = null
}

variable "recovery_window_in_days" {
  type        = number
  description = "Default deletion recovery window. 0 forces immediate deletion (no recovery); 7-30 keeps the secret recoverable. Devotica defaults to the maximum."
  # Devotica fintech default: longest recovery window so an accidental delete is reversible.
  default = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 (force delete) or between 7 and 30."
  }
}

variable "block_public_policy" {
  type        = bool
  description = "Reject any attached resource policy that would grant public access."
  # Devotica fintech default: never allow a public secret policy.
  default = true
}
