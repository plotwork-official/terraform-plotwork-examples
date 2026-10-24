variable "scheme" {
  description = "light, dark, or auto for one picture that follows the viewer's setting."
  type        = string
  default     = "light"

  validation {
    condition     = contains(["light", "dark", "auto"], var.scheme)
    error_message = "scheme must be light, dark or auto."
  }
}
