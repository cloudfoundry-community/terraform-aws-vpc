#!/bin/bash

cd $HOME
sudo apt-get update
sudo apt-get install -y git vim-nox build-essential libxml2-dev libxslt-dev libmysqlclient-dev libpq-dev libsqlite3-dev git
curl -sSL https://get.rvm.io | bash -s stable
source /home/ubuntu/.rvm/scripts/rvm
rvm install ruby-2.1.3
rvm alias create default ruby-2.1.3

cat <<EOF > ~/.gemrc
gem: --no-document
EOF

gem install bundler
mkdir -p {bin,workspace/deployments,workspace/tools}
pushd workspace/deployments

mkdir bosh-bootstrap
pushd bosh-bootstrap
gem install bosh-bootstrap bosh_cli
cat <<EOF > settings.yml
---
provider:
  name: aws
  credentials:
    provider: AWS
    aws_access_key_id: $1
    aws_secret_access_key: $2
  region: $3
address:
  vpc_id: $4
  subnet_id: $5
  ip: $6.2.4
EOF

cat <<EOF > ~/.fog
:default:
    :aws_access_key_id: $1
    :aws_secret_access_key: $2
    :region: $3
EOF

bosh-bootstrap deploy

bosh -n target https://10.50.2.4:25555
bosh login admin admin
popd

git clone http://github.com/cloudfoundry-community/cf-boshworkspace
pushd cf-boshworkspace
bundle install --path vendor/bundle
mkdir -p ssh
export CF_ELASTIC_IP=$7
export SUBNET_ID=$8
export DIRECTOR_UUID=$(bundle exec bosh status | grep UUID | awk '{print $2}')
for VAR in CF_ELASTIC_IP SUBNET_ID DIRECTOR_UUID
do
  eval REP=\$$VAR
  perl -pi -e "s/$VAR/$REP/g" deployments/cf-aws-vpc.yml
done
bundle exec bosh upload release https://community-shared-boshreleases.s3.amazonaws.com/boshrelease-cf-189.tgz
bundle exec bosh deployment cf-aws-vpc
bundle exec bosh prepare deployment
popd


# Needed for microbosh/firstbosh/micro_bosh.yml:
# Elastic IP
# IP on Microbosh Subnet
# IP of DNS Server
# SUBNET ID of Microbosh Subnet
# Availability Zone
# Access Key ID
# Secret Access Key
# Default key name (can standardize on 'bosh')
# Default security group (can standardize on 'bosh')
# Region
