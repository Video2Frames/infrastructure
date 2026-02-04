resource "aws_ecrpublic_repository" "video_processor" {
  repository_name = "video2frames-video-processor"

  catalog_data {
    about_text        = "Video2Frames Video Processor - Container for video frame extraction service"
    architectures     = ["x86-64"]
    operating_systems = ["Linux"]
  }

  tags = var.tags
}
