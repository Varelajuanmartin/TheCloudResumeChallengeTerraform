# **********************************
# *************** S3 ***************
# **********************************

# 1) S3Bucket: static-webpage-cv
# - 2) Unable block public access
# - 3) Bucket policy:
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
# - 4) Upload the webpage files

resource "aws_s3_bucket" "static-webpage-cv" {
  bucket = "static-webpage-cv-terraform"
}
