output "object" {
  description = "Where the SVG was written."
  value       = "s3://${aws_s3_object.diagram.bucket}/${aws_s3_object.diagram.key}"
}
