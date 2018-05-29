/*
 Application servers
*/
resource "aws_security_group" "app_servers" {
    count = 2
	name = "vpc_application_servers_${element(var.azs, count.index)}"
	description = "Allow web clients to connect the app servers"

	ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        security_groups = ["${element(aws_security_group.web.*.id, count.index)}"]
	}

    ingress {
        from_port = 22
        to_port = 8000
        protocol = "tcp"
        security_groups = ["${element(aws_security_group.web.*.id, count.index)}"]
    }

    egress { # SQL Server
        from_port = 1433
        to_port = 1433
        protocol = "tcp"
        cidr_blocks = ["${element(var.database_subnets, count.index)}"]
    }

    egress { # MySQL
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["${element(var.database_subnets, count.index)}"]
    }

	vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "ApplicationServers"
    }
}

resource "aws_instance" "app_servers" {
    count = 2

	ami = "${lookup(var.amis, var.aws_region)}"

	availability_zone = "${element(var.azs, count.index)}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${element(aws_security_group.app_servers.*.id, count.index)}"]
    subnet_id = "${element(aws_subnet.application-subnet.*.id, count.index)}"
    source_dest_check = false

    /*
    # Install nginx and deploy web application
    provisioner "remote-exec" {
        inline = [
            "sudo yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y",
            "sudo yum install git-core",
            "sudo git clone https://github.com/amsilf/aws-vpc-extended.git ~/tmp/",
            "sude java -jar "
        ]
    }
    */

    tags {
        Name = "Application Server"
    }

}
