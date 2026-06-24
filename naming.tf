# Native resource naming + tagging.
#
# Composes a prefix from namespace / environment / stage / name joined by a
# delimiter. Each secret's full name is "<prefix>/<map-key>" (unless the
# per-secret `name_override` is set), e.g. "dvtca-prod-payments/db-password".

variable "enabled" {
  type        = bool
  description = "Set to false to make this module a no-op (create nothing)."
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace / org prefix used to compose secret names (e.g. \"dvtca\")."
  default     = null
}

variable "environment" {
  type        = string
  description = "Environment segment used to compose secret names (e.g. a short region code)."
  default     = null
}

variable "stage" {
  type        = string
  description = "Stage / account segment used to compose secret names (e.g. \"prod\")."
  default     = null
}

variable "name" {
  type        = string
  description = "Base name used to compose secret names (e.g. \"payments\")."
  default     = null
}

variable "delimiter" {
  type        = string
  description = "Delimiter joining the name-prefix segments."
  default     = "-"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every secret this module creates."
  default     = {}
}

locals {
  enabled = var.enabled

  name_segments = [var.namespace, var.environment, var.stage, var.name]
  prefix        = join(var.delimiter, compact(local.name_segments))

  identity_tags = { for k, v in {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  } : k => v if v != null && v != "" }

  base_tags = merge(local.identity_tags, var.tags)
}
