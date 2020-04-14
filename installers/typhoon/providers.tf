provider "aws" {
  version                 = "2.53.0"
  region                  = "us-east-1"
  shared_credentials_file = "/home/medined/.config/aws/credentials"
}

provider "ct" {
  version = "0.5.0"
}
