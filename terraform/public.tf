/*
  Web Servers
*/
resource "aws_security_group" "web" {
    count = 2
    name = "vpc_web_${element(var.azs, count.index)}"
    description = "Allow incoming HTTP connections."

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
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress { # App servers
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "WebServers"
    }
}

resource "aws_instance" "web-app" {
    count = 2

    ami = "${lookup(var.amis, var.aws_region)}"
    availability_zone = "${element(var.azs, count.index)}"
    instance_type = "t2.small"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${element(aws_security_group.web.*.id, count.index)}"]
    subnet_id = "${element(aws_subnet.public-subnet.*.id, count.index)}"
    source_dest_check = false

    # Install nginx and deploy web application

    provisioner "remote-exec" {
        inline = [
            "sudo yum -y update",
            "sudo yum install nginx -y",
            "sudo yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y",
            "sudo yum install git-core",
            "sudo mkdir ~/tmp/",
            "sudo git clone https://github.com/amsilf/aws-vpc-extended.git ~/tmp/",
            "sudo cp -fR ~/tmp/client/* /usr/share/nginx/html/",
            "sudo rm -rf ~/tmp/",
            "sudo echo ${"aws_security_group.web.*.id"} > subnet.config",
            "sudo nginx"
        ]
    }
    
    tags {
        Name = "Web Server"
    }
}