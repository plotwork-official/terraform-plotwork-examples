variable "project" {
  description = "The Google Cloud project."
  type        = string
}

variable "bucket" {
  description = "An existing Cloud Storage bucket the SVG is written to."
  type        = string
}

variable "object_key" {
  description = "The SVG's name in storage."
  type        = string
  default     = "diagrams/aws-three-tier.svg"
}
