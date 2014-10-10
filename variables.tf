variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}
variable "region" {
  default = "us-east-1"
}
variable "aws_nat_ami" {
	default = "ami-49691279"
}
variable "aws_ubuntu_ami" {
	default = "ami-37501207"
}
variable "network" {
	default = "10.10"
}
