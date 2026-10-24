variable "organization" {
  description = "The slug or id of the organisation. The API key must be the owner's or an admin's, or an organisation key with the design:write scope."
  type        = string
}

variable "primary_colour" {
  description = "The main brand colour, #rrggbb or #rgb."
  type        = string
  default     = "#2a78d6"
}

variable "secondary_colour" {
  description = "The secondary brand colour, or null to have Plotwork make it from the primary."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Put before every icon and pattern name, such as \"team-\", to keep a test run's apart from the organisation's own."
  type        = string
  default     = ""

  validation {
    condition     = var.name_prefix == "" || can(regex("^[a-z0-9]+(-[a-z0-9]+)*-$", var.name_prefix))
    error_message = "name_prefix must be lower-case words joined by hyphens, ending with a hyphen, such as \"team-\"."
  }
}

variable "icon_aliases" {
  description = "Other names for each icon, by file name without .svg."
  type        = map(list(string))
  default = {
    "payments-api" = ["payments service"]
  }
}
