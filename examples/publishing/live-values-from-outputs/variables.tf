variable "environment" {
  description = "The environment's name: in the title, the folder and the stable link. Lower-case letters, digits and hyphens."
  type        = string
  default     = "example"

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be lower-case letters and digits in words joined by single hyphens."
  }
}

variable "replicas" {
  description = "Tasks per subnet. Change it and apply to watch the diagram follow."
  type        = number
  default     = 2
}
