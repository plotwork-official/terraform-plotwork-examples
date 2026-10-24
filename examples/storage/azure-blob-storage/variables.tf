variable "storage_account_name" {
  description = "An existing storage account."
  type        = string
}

variable "container_name" {
  description = "An existing container in it."
  type        = string
  default     = "architecture"
}

variable "object_key" {
  description = "The SVG's name in storage."
  type        = string
  default     = "diagrams/aws-three-tier.svg"
}
