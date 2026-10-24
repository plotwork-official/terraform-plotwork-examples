variable "environment" {
  description = "Names the stable link (payments-<environment>), so each environment keeps its own. Lower-case letters, digits and hyphens."
  type        = string
  default     = "example"

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be lower-case letters and digits in words joined by single hyphens."
  }
}
