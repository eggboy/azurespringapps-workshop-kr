variable "prefix" {
  default     = "acme-fitness"
  description = "Prefix for all resources."
}

variable "postfix" {
  default     = "asa"
  description = "Postfix for all resources."
}

variable "tenant_id" {
  default     = "asa"
  description = "Postfix for all resources."
}

variable "location" {
  default     = "koreacentral"
  description = "The Azure Region in which all resources will be provisioned in"
}

variable "total_count" {
  default = 1
}

