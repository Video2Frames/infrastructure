# S3 Bucket for video uploads
resource "aws_s3_bucket" "video_uploads" {
  bucket = "video2frame-video-uploads"

  tags = merge(
    var.tags,
    {
      Name = "Video Uploads Bucket"
    }
  )
}

# Block public access for video uploads bucket
resource "aws_s3_bucket_public_access_block" "video_uploads" {
  bucket = aws_s3_bucket.video_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption for video uploads bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "video_uploads" {
  bucket = aws_s3_bucket.video_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket for extracted frames
resource "aws_s3_bucket" "extracted_frames" {
  bucket = "video2frame-extracted-frames"

  tags = merge(
    var.tags,
    {
      Name = "Extracted Frames Bucket"
    }
  )
}

# Block public access for extracted frames bucket
resource "aws_s3_bucket_public_access_block" "extracted_frames" {
  bucket = aws_s3_bucket.extracted_frames.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption for extracted frames bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "extracted_frames" {
  bucket = aws_s3_bucket.extracted_frames.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
