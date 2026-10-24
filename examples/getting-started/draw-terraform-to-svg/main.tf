locals {
  # The Terraform to draw. In your own configuration this is usually
  # path.module: the module draws itself.
  fixture_dir = "${path.module}/../../../fixtures/aws-three-tier"
}

data "plotwork_import" "stack" {
  format = "terraform"
  title  = var.title
  files = {
    for f in fileset(local.fixture_dir, "*.tf") : f => file("${local.fixture_dir}/${f}")
  }
}

data "plotwork_render" "stack" {
  source = data.plotwork_import.stack.source
  scheme = var.scheme
}

resource "local_file" "diagram" {
  filename = "${path.module}/out/aws-three-tier.svg"
  content  = data.plotwork_render.stack.svg
}
