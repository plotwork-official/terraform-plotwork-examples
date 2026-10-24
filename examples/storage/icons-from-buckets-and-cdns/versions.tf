terraform {
  required_version = ">= 1.9"

  required_providers {
    plotwork = {
      source = "plotwork-official/plotwork"
      # plotwork_organization_icon arrived in 0.2.
      version = "~> 0.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}
