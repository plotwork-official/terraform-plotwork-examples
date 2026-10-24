resource "aws_db_subnet_group" "main" {
  name       = "shop-db"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_db_instance" "main" {
  identifier                  = "shop-db"
  engine                      = "postgres"
  instance_class              = "db.t4g.medium"
  allocated_storage           = 50
  username                    = "shop"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.main.name
  multi_az                    = true
}

resource "aws_elasticache_cluster" "sessions" {
  cluster_id      = "shop-sessions"
  engine          = "redis"
  node_type       = "cache.t4g.micro"
  num_cache_nodes = 1
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-example"
}

resource "aws_cloudfront_distribution" "assets" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id   = "assets"
  }

  default_cache_behavior {
    target_origin_id       = "assets"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
