# A diagram kept in the repository as a .diagram file, published to your own
# library with a stable link. Edit the file, apply, and the link shows the
# new picture.
resource "plotwork_diagram" "payments" {
  source = file("${path.module}/diagrams/payments.diagram")
  name   = "Payments"
  folder = "Examples/Terraform"
  scheme = "auto"
  alias  = "payments-${var.environment}"
}
