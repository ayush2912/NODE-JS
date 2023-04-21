terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-offsetmax"
    key            = "-transport-notification/remote/s3/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "dynamodb-state-locking-terraform"
  }
}
