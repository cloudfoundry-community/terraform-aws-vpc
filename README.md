# terraform-cf-aws-vpc

This project aims to create one click deploy for Cloud Foundry on AWS VPC.

## Architecture
![](https://photos-4.dropbox.com/t/1/AAB8vXYiZDHSbE9aQqN4X9Y01lqA5CzsyPNm2-34UbXVyg/12/44300853/jpeg/1024x768/3/1413572400/0/2/cf_vpc.jpg/AYKsL9W9noKPtwL0zdQ8PxfERv3yXKefEN4yRCNM2hU)

## Deploy Cloud Foundry

The one step that isn't automated is the creation of SSH keys. Waiting for feature to be added to terraform.
An AWS SSH Key need to be created in desired region prior to running the following commands.

**NOTE**: Security group tags are needed and PR is awaiting to be merged in. A version of terraform has been build with this feature.

OSX: [Terraform](https://www.dropbox.com/s/b146qmdvesgvnxd/terraform.tar.gz?dl=0 )

If a linux or window version is needed please email long@starkandwayne.com and I can create them for you.

```bash
mkdir terraform-cf
cd terraform-cf
terraform apply github.com/cloudfoundry-community/terraform-cf-aws-vpc
```
