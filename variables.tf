variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}
variable "region" {
  default = "us-east-1"
}
variable "aws_nat_ami" {
	default = "ami-1d2b2958"
}
variable "aws_ubuntu_ami" {
	default = "ami-736e6536"
}
variable "network" {
	default = "10.10"
}
