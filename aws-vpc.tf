provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "${var.region}"
}

resource "aws_vpc" "default" {
	cidr_block = "${var.network}.0.0/16"
	enable_dns_hostnames = "true"
	tags {
		Name = "cf-vpc"
	}
}

resource "aws_internet_gateway" "default" {
	vpc_id = "${aws_vpc.default.id}"
}



# NAT instance

resource "aws_security_group" "nat" {
	name = "nat"
	description = "Allow services from the private subnet through NAT"
	vpc_id = "${aws_vpc.default.id}"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 9418
		to_port = 9418
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		from_port = -1
		to_port = -1
		protocol = "icmp"
	}

	tags {
		Name = "nat"
	}

}

resource "aws_instance" "nat" {
	ami = "${lookup(var.aws_nat_ami, var.region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.nat.id}"]
	subnet_id = "${aws_subnet.bastion.id}"
	associate_public_ip_address = true
	source_dest_check = false
	tags {
		Name = "nat"
	}
}

resource "aws_eip" "nat" {
	instance = "${aws_instance.nat.id}"
	vpc = true
}

# Public subnets

resource "aws_subnet" "bastion" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.0.0/24"
}

resource "aws_subnet" "lb" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.3.0/24"
}

# Routing table for public subnets

resource "aws_route_table" "public" {
	vpc_id = "${aws_vpc.default.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.default.id}"
	}
}

resource "aws_route_table_association" "lb-public" {
	subnet_id = "${aws_subnet.lb.id}"
	route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "bastion-public" {
	subnet_id = "${aws_subnet.bastion.id}"
	route_table_id = "${aws_route_table.public.id}"
}

# Private subsets

resource "aws_subnet" "cfruntime-2a" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.5.0/24"
}

resource "aws_subnet" "cfruntime-2b" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.6.0/24"
}

resource "aws_subnet" "microbosh" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.2.0/24"
}

resource "aws_subnet" "cloudera" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.10.0/24"
}

# Routing table for private subnets

resource "aws_route_table" "private" {
	vpc_id = "${aws_vpc.default.id}"

	route {
		cidr_block = "0.0.0.0/0"
		instance_id = "${aws_instance.nat.id}"
	}
}

resource "aws_route_table_association" "microbosh-private" {
	subnet_id = "${aws_subnet.microbosh.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "cfruntime-2a-private" {
	subnet_id = "${aws_subnet.cfruntime-2a.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "cfruntime-2b-private" {
	subnet_id = "${aws_subnet.cfruntime-2b.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "cloudera-private" {
	subnet_id = "${aws_subnet.cloudera.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_security_group" "bastion" {
	name = "bastion"
	description = "Allow SSH traffic from the internet"
	vpc_id = "${aws_vpc.default.id}"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags {
		Name = "bastion"
	}

}

resource "aws_security_group" "cf" {
	name = "cf"
	description = "CF security groups"
	vpc_id = "${aws_vpc.default.id}"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		from_port = 4443
		to_port = 4443
		protocol = "tcp"
	}


	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		from_port = -1
		to_port = -1
		protocol = "icmp"
	}

	ingress {
		from_port = 0
		to_port = 65535
		protocol = "tcp"
		self = "true"
	}

	tags {
		Name = "cf"
	}

}

resource "aws_eip" "cf" {
	vpc = true
}

resource "aws_instance" "bastion" {
	ami = "${lookup(var.aws_ubuntu_ami, var.region)}"
	instance_type = "m1.medium"
	key_name = "${var.aws_key_name}"
	associate_public_ip_address = true
	security_groups = ["${aws_security_group.bastion.id}"]
	subnet_id = "${aws_subnet.bastion.id}"

	tags {
		Name = "inception server"
	}

	connection {
  	user = "ubuntu"
  	key_file = "${var.aws_key_path}"
  }

	provisioner "file" {
		source = "scripts/provision.sh"
		destination = "/home/ubuntu/provision.sh"
  }

	provisioner "remote-exec" {
		inline = [
			"chmod +x /home/ubuntu/provision.sh",
			"/home/ubuntu/provision.sh ${var.aws_access_key} ${var.aws_secret_key} ${var.region} ${aws_vpc.default.id} ${aws_subnet.microbosh.id} ${var.network} ${aws_eip.cf.public_ip} ${aws_subnet.cfruntime-2a.id} ${aws_subnet.cfruntime-2a.availability_zone} ${aws_instance.bastion.availability_zone} ${aws_instance.bastion.id} ${aws_subnet.lb.id}",
		]
  }

}

# Create the Cloudera Launcher Server & Security Group
resource "aws_security_group" "cloudera_launcher" {
	name = "cloudera_launcher"
	description = "Allow SSH traffic from the internet"
	vpc_id = "${aws_vpc.default.id}"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 0
		to_port = 65535
		protocol = "tcp"
		self = "true"
	}

	tags {
		Name = "cloudera launcher"
	}

}

resource "aws_instance" "cloudera_launcher" {
	ami = "${lookup(var.aws_centos_ami, var.region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	associate_public_ip_address = true
	security_groups = ["${aws_security_group.cloudera_launcher.id}"]
	subnet_id = "${aws_subnet.bastion.id}"

	tags {
		Name = "Cloudera Launcher"
	}

	connection {
		user = "ec2-user"
		key_file = "${var.aws_key_path}"
	}

	provisioner "file" {
		source = "scripts/cloudera_launcher.sh"
		destination = "/home/ec2-user/cloudera_launcher.sh"
	}

	provisioner "file" {
		source = "${var.aws_key_path}"
		destination = "/home/ec2-user/.ssh/cloudera.pem"
	}

	provisioner "remote-exec" {
		inline = [
			"chmod +x /home/ec2-user/cloudera_launcher.sh",
			"chmod 0400 /home/ec2-user/.ssh/cloudera.pem",
			"/home/ec2-user/cloudera_launcher.sh ${aws_subnet.cloudera.id} ${aws_security_group.cloudera_launcher.id} ${var.aws_key_name} ${var.hadoop_instance_count} ${var.hadoop_instance_type} ${lookup(var.aws_centos_ami, var.region)} ${var.aws_access_key} ${var.aws_secret_key}",
		]
	}

}
