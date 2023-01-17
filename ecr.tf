resource "aws_ecr_repository" "clean_me" {
  name = "clean_me"

}

resource "aws_ecr_repository" "clean_me_nsfw" {
  name = "clean_me_nsfw"

}

resource "aws_ecr_repository" "db_dump_s3" {
  name = "db_dump_s3"

}
