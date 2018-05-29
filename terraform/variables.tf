variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}

variable dblogin {
    default = "login"
}
variable dbpassword {
    default = "password"
}

variable "aws_region" {
    description = "EC2 Region for the VPC"
    default = "eu-west-1"
}

variable "amis" {
    description = "AMIs by region"
    default = {
        eu-west-1 = "ami-ca0135b3" # ubuntu 14.04 LTS
    }
}

variable "azs" {
    description = "Availability Zones"
    default = ["eu-west-1a", "eu-west-1b" ]
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "192.168.0.0/16"
}

variable "public_subnets" {
    description = "CIDR for the Public Subnet"
    default = [ "192.168.101.0/24", "192.168.102.0/24" ]
}

variable "database_subnets" {
    description = "CIDR for the Private Subnet"
    default = [ "192.168.201.0/24", "192.168.202.0/24" ]
}

variable "application_subnets" {
    description = "CIDR for the Application server Layer"
    default = [ "192.168.1.0/24", "192.168.2.0/24" ]
}
