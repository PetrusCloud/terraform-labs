#######################################
# Provider
#######################################
provider "aws" {
  region = var.aws_region
}

#######################################
# Call for the Module
#######################################
module "vpc" {
  source = "./modules/vpc"
  subnet_cidr = "20.0.0.0/24"
  environment = "stage"
  project = "terraform"
  vpc_cidr = "20.0.0.0/16"
}
    
