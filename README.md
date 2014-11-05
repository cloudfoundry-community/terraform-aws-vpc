# terraform-cf-aws-vpc

This project aims to create one click deploy for Cloud Foundry on AWS VPC.

## Architecture
![](https://photos-4.dropbox.com/t/1/AAB8vXYiZDHSbE9aQqN4X9Y01lqA5CzsyPNm2-34UbXVyg/12/44300853/jpeg/1024x768/3/1413572400/0/2/cf_vpc.jpg/AYKsL9W9noKPtwL0zdQ8PxfERv3yXKefEN4yRCNM2hU)

## Deploy Cloud Foundry

The one step that isn't automated is the creation of SSH keys. Waiting for feature to be added to terraform.
An AWS SSH Key need to be created in desired region prior to running the following commands.

**NOTE**: You **must** being using at least terraform 0.3.1 for the tags to work.

```bash
mkdir terraform-cf
cd terraform-cf
terraform apply github.com/cloudfoundry-community/terraform-cf-aws-vpc
```
