variable "organization" {
  description = "The slug or id of the organisation the icons belong to."
  type        = string
}

variable "aws_region" {
  description = "The region of the S3 bucket."
  type        = string
  default     = "eu-west-2"
}

variable "s3_bucket" {
  description = "The S3 bucket that holds an icon, or null to skip that icon."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "The key of the icon in s3_bucket."
  type        = string
  default     = "icons/ledger.svg"
}

variable "azure_blob_sas_url" {
  description = "A read-only SAS address of an SVG blob, or null to skip that icon."
  type        = string
  default     = null
  sensitive   = true
}

variable "cdn_icon_url" {
  description = "An https address that serves an SVG, or null to skip that icon."
  type        = string
  default     = null

  validation {
    condition     = var.cdn_icon_url == null || startswith(coalesce(var.cdn_icon_url, "x"), "https://")
    error_message = "cdn_icon_url must be an https:// address."
  }
}
