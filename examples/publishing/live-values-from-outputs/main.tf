# Stands in for the real stack, so the example runs with no cloud account.
# In your configuration, read the same values from your resources or module
# outputs instead: aws_vpc.main.cidr_block, aws_lb.web.dns_name, and so on.
resource "terraform_data" "deployment" {
  input = {
    vpc_cidr    = "10.20.0.0/16"
    subnets     = { "app-a" = "10.20.10.0/24", "app-b" = "10.20.11.0/24" }
    lb_dns_name = "shop-web-1234567890.ap-southeast-2.elb.amazonaws.com"
    db_endpoint = "shop-db.abcdefghij.ap-southeast-2.rds.amazonaws.com"
    replicas    = var.replicas
  }
}

# The diagram reads the deployment's values, so Terraform publishes it after
# the deployment and again whenever one of the values changes.
resource "plotwork_diagram" "network" {
  name   = "${var.environment} network"
  folder = "Examples/Terraform"
  scheme = "auto"
  alias  = "network-${var.environment}"

  source = templatefile("${path.module}/templates/network.diagram.tftpl", {
    environment = var.environment
    vpc_cidr    = terraform_data.deployment.output.vpc_cidr
    subnets     = terraform_data.deployment.output.subnets
    lb_dns_name = terraform_data.deployment.output.lb_dns_name
    db_endpoint = terraform_data.deployment.output.db_endpoint
    replicas    = terraform_data.deployment.output.replicas
  })
}
