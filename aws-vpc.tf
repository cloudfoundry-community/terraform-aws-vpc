provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "${var.region}"
}

resource "aws_vpc" "default" {
	cidr_block = "${var.network}.0.0/16"
}

resource "aws_internet_gateway" "default" {
	vpc_id = "${aws_vpc.default.id}"
}

# NAT instance

resource "aws_security_group" "nat" {
	name = "nat"
	description = "Allow services from the private subnet through NAT"

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

	vpc_id = "${aws_vpc.default.id}"
}

resource "aws_instance" "nat" {
	ami = "${var.aws_nat_ami}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.nat.id}"]
	subnet_id = "${aws_subnet.bastion.id}"
	associate_public_ip_address = true
	source_dest_check = false
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

resource "aws_subnet" "cfruntime" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.1.0/24"
}

resource "aws_subnet" "microbosh" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.2.0/24"
}

resource "aws_subnet" "docker-services" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.4.0/24"
}

# Routing table for private subnets

resource "aws_route_table" "private" {
	vpc_id = "${aws_vpc.default.id}"

	route {
		cidr_block = "0.0.0.0/0"
		instance_id = "${aws_instance.nat.id}"
	}
}

resource "aws_route_table_association" "docker-services-private" {
	subnet_id = "${aws_subnet.docker-services.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "microbosh-private" {
	subnet_id = "${aws_subnet.microbosh.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "cfruntime-private" {
	subnet_id = "${aws_subnet.cfruntime.id}"
	route_table_id = "${aws_route_table.private.id}"
}


resource "aws_security_group" "bastion" {
	name = "bastion"
	description = "Allow SSH traffic from the internet"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	vpc_id = "${aws_vpc.default.id}"
}

resource "aws_eip" "cf" {
	vpc = true
}

resource "aws_instance" "bastion" {
	ami = "${var.aws_ubuntu_ami}"
	instance_type = "m1.medium"
	key_name = "${var.aws_key_name}"
	associate_public_ip_address = "true"
	security_groups = ["${aws_security_group.bastion.id}"]
	subnet_id = "${aws_subnet.bastion.id}"

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
			"/home/ubuntu/provision.sh ${var.aws_access_key} ${var.aws_secret_key} ${var.region} ${aws_vpc.default.id} ${aws_subnet.microbosh.id} ${var.network} ${aws_eip.cf.public_ip} ${aws_subnet.lb.id} ${aws_instance.bastion.availability_zone} ${aws_instance.bastion.id}",
		]
  }

}
