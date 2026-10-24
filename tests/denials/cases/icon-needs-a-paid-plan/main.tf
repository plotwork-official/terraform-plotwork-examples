resource "plotwork_organization_icon" "free" {
  organization = var.organization
  name         = "denial-check"
  svg          = file("${path.module}/../../../../fixtures/organisation-design/icons/payments-api.svg")
}

variable "organization" {
  description = "The Free plan's organisation, owned by the account whose key runs the test."
  type        = string
}
