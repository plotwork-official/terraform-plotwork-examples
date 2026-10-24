data "plotwork_import" "stack" {
  format = "terraform"
  text   = "resource \"aws_s3_bucket\" \"assets\" {}"
}

output "source" {
  description = "Never reached on the Free plan."
  value       = data.plotwork_import.stack.source
}
