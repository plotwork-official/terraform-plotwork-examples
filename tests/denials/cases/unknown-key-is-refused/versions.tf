terraform {
  required_version = ">= 1.9"

  required_providers {
    plotwork = {
      source  = "plotwork-official/plotwork"
      version = "~> 0.1"
    }
  }
}

# Reads PLOTWORK_API_KEY and PLOTWORK_API_URL.
provider "plotwork" {}
