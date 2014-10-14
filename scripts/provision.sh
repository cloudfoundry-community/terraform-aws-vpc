#!/bin/bash

AWS_KEY_ID=${1}
AWS_ACCESS_KEY=${2}
REGION=${3}
VPC=${4}
BOSH_SUBNET=${5}
IPMASK=${6}
CF_IP=${7}
CF_SUBNET=${8}
CF_SUBNET_AZ=${9}
BASTION_AZ=${10}
BASTION_ID=${11}

cd $HOME
sudo apt-get update
sudo apt-get install -y git vim-nox build-essential libxml2-dev libxslt-dev libmysqlclient-dev libpq-dev libsqlite3-dev git unzip
curl -sSL https://get.rvm.io | bash -s stable

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

pushd /tmp
wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.3/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
sudo mv spiff /usr/local/bin/.
popd

source /home/ubuntu/.rvm/scripts/rvm
rvm install ruby-2.1.3
rvm alias create default ruby-2.1.3

cat <<EOF > ~/.gemrc
gem: --no-document
EOF

cat <<EOF > ~/.fog
:default:
    :aws_access_key_id: $AWS_KEY_ID
    :aws_secret_access_key: $AWS_ACCESS_KEY
    :region: $REGION
EOF

gem install fog
cat <<EOF > /tmp/attach_volume.rb
require 'fog'

connection = Fog::Compute.new(:provider => 'AWS')
vol = connection.create_volume("$BASTION_AZ", 40)
sleep 10 #FIXME, probably with a loop that checks output or something
connection.attach_volume("$BASTION_ID", vol.data[:body]["volumeId"], "xvdc")
EOF
ruby /tmp/attach_volume.rb
sleep 10
sudo /sbin/mkfs.ext4 /dev/xvdc
sudo /sbin/e2label /dev/xvdc workspace
echo 'LABEL=workspace /home/ubuntu/workspace ext4 defaults,discard 0 0' | sudo tee -a /etc/fstab
mkdir -p /home/ubuntu/workspace
sudo mount -a
sudo chown -R ubuntu:ubuntu /home/ubuntu/workspace

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
    aws_access_key_id: $AWS_KEY_ID
    aws_secret_access_key: $AWS_ACCESS_KEY
  region: $REGION
address:
  vpc_id: $VPC
  subnet_id: $BOSH_SUBNET
  ip: ${IPMASK}.2.4
EOF

bosh-bootstrap deploy

bosh -n target https://${IPMASK}.2.4:25555
bosh login admin admin
popd

git clone -b cf-terraform http://github.com/cloudfoundry-community/cf-boshworkspace
pushd cf-boshworkspace
bundle install --path vendor/bundle
mkdir -p ssh
export REGION=${CF_SUBNET_AZ}
export CF_ELASTIC_IP=$CF_IP
export SUBNET_ID=$CF_SUBNET
export DIRECTOR_UUID=$(bundle exec bosh status | grep UUID | awk '{print $2}')
for VAR in CF_ELASTIC_IP SUBNET_ID DIRECTOR_UUID REGION
do
  eval REP=\$$VAR
  perl -pi -e "s/$VAR/$REP/g" deployments/cf-aws-vpc.yml
done
bundle exec bosh upload release https://community-shared-boshreleases.s3.amazonaws.com/boshrelease-cf-189.tgz
bundle exec bosh deployment cf-aws-vpc
bundle exec bosh prepare deployment
bundle exec bosh -n deploy
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
