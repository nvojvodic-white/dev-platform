terraform {
  backend "s3" {
    bucket         = "dev-platform-tfstate-375976227140"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
