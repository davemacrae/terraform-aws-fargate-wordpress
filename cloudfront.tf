locals {
  custom_origin_id = "myoriginid"
}

resource "aws_cloudfront_distribution" "cdn" {
  aliases = var.cnames
  enabled = var.enabled
  tags    = var.tags

  origin {
    #domain_name = var.domain_name
    domain_name = aws_lb.wordpress.dns_name
    origin_id   = var.origin_id

    custom_origin_config {
      http_port              = var.http_port
      https_port             = var.https_port
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = var.origin_ssl_protocols
    }
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.cloudfront_acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin"]

      cookies {
        forward           = "whitelist"
        whitelisted_names = var.cookies_whitelisted_names
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern     = "wp-admin/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.origin_id

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "wp-login.php"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.origin_id

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin"]

      cookies {
        forward           = "whitelist"
        whitelisted_names = var.cookies_whitelisted_names
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
}

# We don't need this as we do n't control the DNS records from this account
/* 
resource "aws_route53_record" "wordpress" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cloudfront_distribution.cdn.domain_name]
}
 */