variable "aws_vpc" {}
variable "network" {}
variable "aws_route_table_private" {}
variable "aws_centos_ami" {}
variable "aws_key_name" {}
variable "aws_subnet_bastion" {}

resource "aws_subnet" "cloudera" {
	vpc_id = "${var.aws_vpc}"
	cidr_block = "${var.network}.10.0/24"
}

resource "aws_route_table_association" "cloudera-private" {
	subnet_id = "${aws_subnet.cloudera.id}"
	route_table_id = "${var.aws_route_table_private}"
}

# Create the Cloudera Launcher Server & Security Group
resource "aws_security_group" "cloudera_launcher" {
	name = "cloudera_launcher"
	description = "Allow SSH traffic from the internet"
	vpc_id = "${var.aws_vpc}"

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
	ami = "${var.aws_centos_ami}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	associate_public_ip_address = true
	security_groups = ["${aws_security_group.cloudera_launcher.id}"]
	subnet_id = "${var.aws_subnet_bastion}"

	tags {
		Name = "Cloudera Launcher"
	}

	connection {
		user = "ec2-user"
		key_file = "${var.aws_key_path}"
	}

	provisioner "file" {
		source = "${path.module}/cloudera_launcher.sh"
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
			"/home/ec2-user/cloudera_launcher.sh ${aws_subnet.cloudera.id} ${aws_security_group.cloudera_launcher.id} ${var.aws_key_name} ${var.hadoop_instance_count} ${var.hadoop_instance_type} ${var.aws_centos_ami} ${var.aws_access_key} ${var.aws_secret_key}",
		]
	}

}
