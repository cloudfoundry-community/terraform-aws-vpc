# terraform-aws-vpc

This is part of a project that aims to create the infrastructure necessary for
Cloud Foundry to be installed. For reasons of modularity, it does not install CF
or microbosh itself. You *probably* don't want to use this repo directly.

## Architecture

This terraform repo will create a VPC in Amazon, two subnets - one as a 'bastion'
to put any ssh and nat servers you need, and one for 'microbosh', and the nat
server itself.

## Deploy Cloud Foundry

This repo doesn't actually deploy Cloud Foundry. See 
https://github.com/cloudfoundry-community/terraform-aws-cf-install for that.

## Subnets

The various subnets that are created by this repo, as well as by [terraform-aws-cf-net](https://github.com/cloudfoundry-community/terraform-aws-cf-net).

|    Name     |     CIDR   | Created By          |
--------------|------------|----------------------
|Bastion      | X.X.0.0/24 | terraform-aws-vpc   |
|Microbosh    | X.X.1.0/24 | terraform-aws-vpc   |
|Loadbalancer | X.X.x2.0/24| terraform-aws-cf-net|
|Runtime 2a   | X.X.x3.0/24| terraform-aws-cf-net|
|Runtime 2b   | X.X.x4.0/24| terraform-aws-cf-net|
