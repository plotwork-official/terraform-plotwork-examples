terraform {
  required_version = ">= 1.9"

  required_providers {
    plotwork = {
      source  = "plotwork-official/plotwork"
      version = "~> 0.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
