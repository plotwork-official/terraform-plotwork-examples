resource "plotwork_pattern" "free" {
  organization = var.organization
  content      = file("${path.module}/../../../../fixtures/organisation-design/patterns/payments-service.pattern.json")
}

variable "organization" {
  description = "The Free plan's organisation, owned by the account whose key runs the test."
  type        = string
}
