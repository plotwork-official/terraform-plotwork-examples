data "plotwork_import" "catalogue" {
  format = "kubernetes"
  text   = file("${path.module}/../../../fixtures/kubernetes-catalogue/catalogue.yaml")
}

data "plotwork_render" "catalogue" {
  source = data.plotwork_import.catalogue.source
  scheme = var.scheme
}

resource "local_file" "diagram" {
  filename = "${path.module}/out/kubernetes-catalogue.svg"
  content  = data.plotwork_render.catalogue.svg
}
