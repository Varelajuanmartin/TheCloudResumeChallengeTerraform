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