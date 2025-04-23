# CloudFront distribution for the web app
resource "aws_cloudfront_distribution" "web_app" {
    comment = "web app cloudfront distribution"
    enabled             = true
    default_root_object = "index.html"

    origin {
        domain_name              = aws_s3_bucket.default.bucket_regional_domain_name
        origin_id                = "web-app-origin"
        origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    }

    default_cache_behavior {
        target_origin_id = "web-app-origin"

        allowed_methods = [
            "GET",
            "HEAD",
            "OPTIONS"
        ]
        cached_methods  = ["GET", "HEAD"]   

        viewer_protocol_policy = "allow-all"
        compress               = true

        cache_policy_id = aws_cloudfront_cache_policy.default.id
    }

    restrictions {
        geo_restriction {
            restriction_type = "whitelist"
            locations        = ["FI"]
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

resource "null_resource" "cloudfront_invalidation" {
  provisioner "local-exec" {
    command = <<EOT
      aws cloudfront create-invalidation \
        --distribution-id ${aws_cloudfront_distribution.web_app.id} \
        --paths "/*"
    EOT
  }
}

resource "aws_cloudfront_origin_access_control" "default" {
    name        = "${aws_s3_bucket.default.bucket_regional_domain_name}"
    description = "Origin access control for web app"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "default" {
    name = "web-app-cache-policy"
    default_ttl = 86400
    max_ttl     = 31536000
    min_ttl     = 1
    
    parameters_in_cache_key_and_forwarded_to_origin {
        enable_accept_encoding_brotli = true
        enable_accept_encoding_gzip   = true
        cookies_config {
            cookie_behavior = "none"
        }

        headers_config {
            header_behavior = "none"
        }

        query_strings_config {
            query_string_behavior = "none"
        }
    }
    comment = "Cache policy for web app"

}

resource "null_resource" "upload_files" {
    provisioner "local-exec" {
                command = <<EOT
        for file in ./files/*; do 
            aws s3 cp "$file" s3://${aws_s3_bucket.default.bucket}/; 
        done
        EOT
    }

    triggers = {
        file_hash = md5(join("", fileset("./files", "*")))
    }

    depends_on = [aws_s3_bucket.default]
}

