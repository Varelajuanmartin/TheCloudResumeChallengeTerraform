# **********************************
# *************** S3 ***************
# **********************************

# 1) S3Bucket: static-webpage-cv
# P 2) Unable block public access
# P 3) Bucket policy:
# {
#     "Version": "2008-10-17",
#     "Id": "PolicyForCloudFrontPrivateContent",
#     "Statement": [
#         {
#             "Sid": "AllowCloudFrontServicePrincipal",
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "cloudfront.amazonaws.com"
#             },
#             "Action": "s3:GetObject",
#             "Resource": "arn:aws:s3:::static-webpage-cv/*",
#             "Condition": {
#                 "StringEquals": {
#                     "AWS:SourceArn": "arn:aws:cloudfront::922166932404:distribution/EC86W9VRBXPJ7"
#                 }
#             }
#         }
#     ]
# }
# P 4) Upload the webpage files

resource "aws_s3_bucket" "static-webpage-cv" {
  bucket = "static-webpage-cv-terraform"
}

# **********************************
# ************ DYNAMODB ************
# **********************************

# 1) DynamoDB Table: VisitorCount
# 2) On demand
# 3) Index PageName String, Attribute Count Number
# 4) Add an item PageName = "1", Count = "0"

resource "aws_dynamodb_table" "VisitorCount" {
  name = "VisitorCountTerraform"
  billing_mode = "PAY_PER_REQUEST" # On demand
  hash_key = "PageName"
  attribute {
    name = "PageName"
    type = "S"
  }
}
resource "aws_dynamodb_table_item" "VisitorCountItem" {
  table_name = aws_dynamodb_table.VisitorCount.name
  hash_key = aws_dynamodb_table.VisitorCount.hash_key
  item = <<ITEM
{
  "PageName": {"S": "1"},
  "Count": {"N": "0"}
}
ITEM
}

# **********************************
# *********** CLOUDFRONT ***********
# **********************************

# 1) Create Cloudfron distribution
# 2) Origin s3 DNS
# 3) Origin access control. Origin type s3. Ensure bucket policy
# 4) Default root object: index.html
# 5) Disable Cache
# 6) Price Class: North America & Europe. PriceClass_100
# 7) Alternate domain name & custom SSL Certificate
# 8) Origin Access
# P 9) Alternate domain names: www.juanvarela.com.ar

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.static-webpage-cv.id
  acl    = "private"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_control" "oac" {
	name                              = "oac_terraform"
	description                       = ""
	origin_access_control_origin_type = "s3"
	signing_behavior                  = "always"
	signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static-webpage-cv.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }
  enabled             = true
  default_root_object = "index.html"

  #aliases = ["www.juanvarela.com.ar"]

  # AWS Managed Caching Policy (CachingDisabled)
  default_cache_behavior {
    cache_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Using the CachingDisabled managed policy ID:
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:922166932404:certificate/c6a5f3e6-6eae-4677-a804-3649ffe12e11"
    minimum_protocol_version = "TLSv1.2_2021" # Required when specifying acm_certificate_arn
    ssl_support_method = "sni-only" # Required when specifying acm_certificate_arn
  }
}