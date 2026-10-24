variable "organization" {
  description = "The slug or id of the organisation whose library holds the diagram. The API key must be its organisation key, or a member's key that may publish."
  type        = string
}

variable "folder" {
  description = "The folder in the library, outermost first."
  type        = string
  default     = "Examples/Terraform"
}
