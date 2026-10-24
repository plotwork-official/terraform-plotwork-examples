# Reads PLOTWORK_API_KEY, and PLOTWORK_API_URL when set.
provider "plotwork" {}

# Reads the usual AWS credentials: AWS_PROFILE, AWS_ACCESS_KEY_ID, an
# instance role.
provider "aws" {
  region = var.aws_region
}
