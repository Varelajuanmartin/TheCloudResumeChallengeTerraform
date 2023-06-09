# **********************************
# *************** S3 ***************
# **********************************

# 1) S3Bucket: static-webpage-cv
# 2) Block all public access
# 3) Upload the webpage files
# 4) Apply Bucket Resource policy
# 5) Object properties: ACL Disabled

resource "aws_s3_bucket" "static-webpage-cv" {
  bucket = "static-webpage-cv-terraform"
}

resource "aws_s3_bucket_public_access_block" "s3_block_public_access" {
  bucket = aws_s3_bucket.static-webpage-cv.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "static_webpage" {
  key        = "index.html" # Name uploaded in bucket
  bucket     = aws_s3_bucket.static-webpage-cv.id
  source     = "index.html" # Source of file in folder
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "PolicyForCloudFrontPrivateContent" {
  bucket = aws_s3_bucket.static-webpage-cv.id
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Id": "PolicyForCloudFrontPrivateContent",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.static-webpage-cv.arn}/*",
      "Condition": {
        "StringEquals": {
            "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
        }
      }
    }
  ]
}
EOF
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
    origin_id                = local.s3_origin_id # Origin Name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }
  enabled             = true
  default_root_object = "index.html"

  aliases = ["terraform.juanvarela.com.ar"]

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
    acm_certificate_arn = "arn:aws:acm:us-east-1:922166932404:certificate/885c587d-ba2c-4d27-ae3e-8f269c8f51e1"
    minimum_protocol_version = "TLSv1.2_2021" # Required when specifying acm_certificate_arn
    ssl_support_method = "sni-only" # Required when specifying acm_certificate_arn
  }
}

# **********************************
# ******* CERTIFICATE MANAGER ******
# **********************************

# 1) Create public certificate. Specify domain
# 2) Add the new certificate with the hosted zone (Route 53)
# 3) Update acm_certificate_arn


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
# ************ IAM ROLE ************
# **********************************

# 1) Generate a Role so Lambda can access DynamoDB Table

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Lambda Basic Exectution Role
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role = aws_iam_role.iam_for_lambda.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda DynamoDB Policy
resource "aws_iam_role_policy_attachment" "dynamodb_execution" {
  role = aws_iam_role.iam_for_lambda.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# **********************************
# ************* LAMBDA *************
# **********************************

# 1) Create function VisitorCountersTerraform
# 2) Function type Node.js 12.x
# 3) Copy Function

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "VisitorCounterTerraform"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_readwrite_dynamodb_CORS.handler" # Name of the .js file inside the .zip without .js

  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "nodejs12.x"
}

# **********************************
# *********** API GATEWAY **********
# **********************************

# 1) Create REST API Gateway VisitorCounterTerraform
# 2) Create Resource, configure as proxy
# 3) Create Method ANY, Authorization NONE,   Lambda function proxy
# 4) Deploy API, stage name dev
# 5) Allow API Gateway invoke Lambda

resource "aws_api_gateway_rest_api" "VisitorCounter_RESTAPI" {
  name = "VisitorCounterTerraform"
}

resource "aws_api_gateway_resource" "VisitorCounter_Resource" {
  parent_id   = aws_api_gateway_rest_api.VisitorCounter_RESTAPI.root_resource_id
  path_part   = "{proxy+}"
  rest_api_id = aws_api_gateway_rest_api.VisitorCounter_RESTAPI.id
}

resource "aws_api_gateway_method" "VisitorCounter_Method" {
  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.VisitorCounter_Resource.id
  rest_api_id   = aws_api_gateway_rest_api.VisitorCounter_RESTAPI.id
}

resource "aws_api_gateway_integration" "VisitorCounter_Integration" {
  http_method = aws_api_gateway_method.VisitorCounter_Method.http_method
  resource_id = aws_api_gateway_resource.VisitorCounter_Resource.id
  rest_api_id = aws_api_gateway_rest_api.VisitorCounter_RESTAPI.id
  
  type        = "AWS_PROXY" #  MOCK
  integration_http_method  = "POST" # ANY
  uri                      = aws_lambda_function.test_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "VisitorCounter_Deployment" {
  rest_api_id = aws_api_gateway_rest_api.VisitorCounter_RESTAPI.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
    aws_api_gateway_resource.VisitorCounter_Resource.id,
    aws_api_gateway_method.VisitorCounter_Method.id,
    aws_api_gateway_integration.VisitorCounter_Integration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "VisitorCounter_Stage" {
  deployment_id = aws_api_gateway_deployment.VisitorCounter_Deployment.id
  rest_api_id   = aws_api_gateway_rest_api.VisitorCounter_RESTAPI.id
  stage_name    = "devTerraform"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.VisitorCounter_RESTAPI.execution_arn}/*/*"
}