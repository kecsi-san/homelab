# Existing S3 buckets — import before first apply:
#   terraform import aws_s3_bucket.buckets["<bucket-name>"] <bucket-name>
#
# Add bucket names to the locals map below, then run terraform import for each.
# Bucket names are in terraform.tfvars (gitignored) to avoid committing them.

variable "s3_bucket_names" {
  description = "Names of existing S3 buckets to manage (set in terraform.tfvars)"
  type        = list(string)
  default     = []
}

resource "aws_s3_bucket" "buckets" {
  for_each = toset(var.s3_bucket_names)
  bucket   = each.key

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "buckets" {
  for_each = toset(var.s3_bucket_names)
  bucket   = aws_s3_bucket.buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "buckets" {
  for_each = toset(var.s3_bucket_names)
  bucket   = aws_s3_bucket.buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "buckets" {
  for_each = toset(var.s3_bucket_names)
  bucket   = aws_s3_bucket.buckets[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
