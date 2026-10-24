variable "title" {
  description = "The diagram's title."
  type        = string
  default     = "Shop on AWS"
}

variable "scheme" {
  description = "light, dark, or auto for one picture that follows the viewer's setting."
  type        = string
  default     = "auto"

  validation {
    condition     = contains(["light", "dark", "auto"], var.scheme)
    error_message = "scheme must be light, dark or auto."
  }
}
