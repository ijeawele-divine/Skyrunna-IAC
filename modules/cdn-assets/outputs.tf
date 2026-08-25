output "bucket_name" {
  description = "S3 bucket holding CDN assets"
  value       = aws_s3_bucket.assets.id
}

output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.assets.id
}

output "distribution_domain_name" {
  description = "CloudFront domain name to reference assets by (e.g. https://<this>/skyrunna-demo-video.mp4)"
  value       = aws_cloudfront_distribution.assets.domain_name
}
