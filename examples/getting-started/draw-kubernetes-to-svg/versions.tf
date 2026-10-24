terraform {
  required_version = ">= 1.9"

  required_providers {
    plotwork = {
      source  = "plotwork-official/plotwork"
      version = "~> 0.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
