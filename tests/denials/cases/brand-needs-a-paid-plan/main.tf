resource "plotwork_organization_brand" "free" {
  organization = var.organization
  primary      = "#2a78d6"
}

variable "organization" {
  description = "The Free plan's organisation, owned by the account whose key runs the test."
  type        = string
}
