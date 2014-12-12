# terraform-aws-vpc

This project aims to create the infrastructure necessary for Cloud Foundry to be
installed. For reasons of modularity, it does not install CF or microbosh itself.

## Architecture

This terraform repo will create a VPC in Amazon, two subnets - one as a 'bastion'
to put any ssh and nat servers you need, and one for 'microbosh', and the nat
server itself.

## Deploy Cloud Foundry

This repo doesn't actually deploy Cloud Foundry. See 
https://github.com/cloudfoundry-community/terraform-aws-cf for that.
