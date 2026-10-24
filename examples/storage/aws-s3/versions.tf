terraform {
  required_version = ">= 1.9"

  required_providers {
    plotwork = {
      source  = "plotwork-official/plotwork"
      version = "~> 0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
