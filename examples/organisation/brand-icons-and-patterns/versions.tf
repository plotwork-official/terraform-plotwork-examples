terraform {
  required_version = ">= 1.9"

  required_providers {
    plotwork = {
      source = "plotwork-official/plotwork"
      # The brand, icon and pattern resources arrived in 0.2.
      version = "~> 0.2"
    }
  }
}
