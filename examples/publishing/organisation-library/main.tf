locals {
  fixture_dir = "${path.module}/../../../fixtures/azure-web-app"
}

data "plotwork_import" "booking" {
  format = "terraform"
  title  = "Booking on Azure"
  files = {
    for f in fileset(local.fixture_dir, "*.tf") : f => file("${local.fixture_dir}/${f}")
  }
}

# The organisation's private library: members open it with view_url, and
# nothing in it has a public address.
resource "plotwork_diagram" "booking" {
  source         = data.plotwork_import.booking.source
  name           = "Booking on Azure"
  folder         = var.folder
  organization   = var.organization
  classification = "internal"
}
