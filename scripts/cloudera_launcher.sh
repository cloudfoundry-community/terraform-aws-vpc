#!/bin/bash

CLOUDERA_SUBNET=${1}
CLOUDERA_SG=${2}
KEYNAME=${3}
HADOOP_INSTANCE_COUNT=${4}
HADOOP_INSTANCE_TYPE=${5}
CENTOS_AMI=${6}
AWS_KEY=${7}
AWS_PRIV=${8}

mkdir -p /home/ec2-user/cloudera/
wget https://s3.amazonaws.com/quickstart-reference/cloudera/hadoop/latest/scripts/download.sh --output-document=/home/ec2-user/cloudera/download.sh
wget https://s3.amazonaws.com/quickstart-reference/cloudera/hadoop/latest/scripts/cleanup.sh --output-document=/home/ec2-user/cloudera/cleanup.sh

#sed -i "s/PUBLICSUBNETID-CFN-REPLACE/${CLOUDERA_SUBNET}/" /home/ec2-user/cloudera/download.sh
# We will be using the 'private' option only. You need to replace both PRIVATESUBNETID and SUBNETID to update the comments and the real config
sed -i "s/PRIVATESUBNETID-CFN-REPLACE/${CLOUDERA_SUBNET}/" /home/ec2-user/cloudera/download.sh
sed -i "s/SUBNETID-CFN-REPLACE/${CLOUDERA_SUBNET}/" /home/ec2-user/cloudera/download.sh

# THE TYPO IS IN THE UPSTREAM CONFIGS. DOING BOTH IN CASE THEY FIX IT LATER
sed -i "s/SECUTIRYGROUPIDS-CFN-REPLACE/${CLOUDERA_SG}/" /home/ec2-user/cloudera/download.sh
sed -i "s/SECURITYGROUPIDS-CFN-REPLACE/${CLOUDERA_SG}/" /home/ec2-user/cloudera/download.sh

sed -i "s/KEYNAME-CFN-REPLACE/${KEYNAME}/" /home/ec2-user/cloudera/download.sh

sed -i "s/HADOOPINSTANCE-COUNT-CFN-REPLACE/${HADOOP_INSTANCE_COUNT}/" /home/ec2-user/cloudera/download.sh
sed -i "s/HADOOPINSTANCE-TYPE-CFN-REPLACE/${HADOOP_INSTANCE_TYPE}/" /home/ec2-user/cloudera/download.sh

sed -i "s/, HBASE/, HBASE, SPARK/" /home/ec2-user/cloudera/download.sh

sudo /bin/sh /home/ec2-user/cloudera/download.sh
sudo /bin/sh /home/ec2-user/cloudera/cleanup.sh

sed -i "s#privateKey-REPLACE-ME#/home/ec2-user/.ssh/cloudera.pem#" /home/ec2-user/cloudera/cloudera-director-1*/aws.simple.conf
sed -i "s/# associatePublicIpAddresses: true/associatePublicIpAddresses: false/" /home/ec2-user/cloudera/cloudera-director-1*/aws.simple.conf
sed -i 's/owner:/#owner:/' /home/ec2-user/cloudera/cloudera-director-1*/aws.simple.conf
sed -i "s/image:.*/image: ${CENTOS_AMI}/" /home/ec2-user/cloudera/cloudera-director-1*/aws.simple.conf
sed -i "s/# accessKeyId.*/accessKeyId: ${AWS_KEY}/" /home/ec2-user/cloudera/cloudera-director-1*/aws.simple.conf
sed -i "s%# secretAccessKey.*%secretAccessKey: ${AWS_PRIV}%" /home/ec2-user/cloudera/cloudera-director-1*/aws.simple.conf
sed -i 's#echo.*#/usr/bin/yum clean all\n/usr/bin/yum -y install vim#' /home/ec2-user/cloudera/cloudera-director-1*/aws.simple.conf
