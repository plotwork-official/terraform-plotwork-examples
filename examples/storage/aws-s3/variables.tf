variable "region" {
  description = "The bucket's AWS region."
  type        = string
  default     = "ap-southeast-2"
}

variable "bucket" {
  description = "An existing S3 bucket the SVG is written to."
  type        = string
}

variable "object_key" {
  description = "The SVG's name in storage."
  type        = string
  default     = "diagrams/aws-three-tier.svg"
}
