resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "aws-vpc"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
}

/*
  NAT Instance
*/
resource "aws_security_group" "nat" {
    count = 2

    name = "vpc_nat_${element(var.azs, count.index)}"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${element(var.database_subnets, count.index)}"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${element(var.database_subnets, count.index)}"]
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

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "NAT-Per-AZ"
    }
}

resource "aws_instance" "nat" {
    count = 2

    ami = "ami-30913f47" # this is a special ami preconfigured to do NAT
    availability_zone = "${element(var.azs, count.index)}"
    instance_type = "m1.small"

    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${element(aws_security_group.nat.*.id, count.index)}"]
    subnet_id = "${element(aws_subnet.public-subnet.*.id, count.index)}"
    associate_public_ip_address = true
    source_dest_check = false

    tags {
        Name = "VPC NAT"
    }
}

resource "aws_eip" "nat" {
    count = 2
    instance = "${element(aws_instance.nat.*.id, count.index)}"
    vpc = true
}

/*
  Public Subnet
*/
resource "aws_subnet" "public-subnet" {
    count = 2
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${element(var.public_subnets, count.index)}"
    availability_zone = "${element(var.azs, count.index)}"

    tags {
        Name = "Public Subnets"
    }
}

resource "aws_route_table" "public-subnet" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags {
        Name = "Public Subnets"
    }
}

resource "aws_route_table_association" "public-subnet" {
    count = 2
    subnet_id = "${element(aws_subnet.public-subnet.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.public-subnet.*.id, count.index)}"
}

/*
  Database Subnet
*/
resource "aws_db_subnet_group" "database-subnet-group" {
    subnet_ids = ["${aws_subnet.database-subnet.*.id}"]

    tags {
        Name = "DB Subnet groups"
    }
}

resource "aws_subnet" "database-subnet" {
    count = 2
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${element(var.database_subnets, count.index)}"
    availability_zone = "${element(var.azs, count.index)}"

    tags {
        Name = "Database Subnets"
    }
}

resource "aws_route_table" "database-subnet" {
    count = 2
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${element(aws_instance.nat.*.id, count.index)}"
    }

    tags {
        Name = "Database Subnet"
    }
}

resource "aws_route_table_association" "database-subnet" {
    count = 2
    subnet_id = "${element(aws_subnet.database-subnet.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.database-subnet.*.id, count.index)}"
}

/*
    Subnet for application servers
*/
resource "aws_subnet" "application-subnet" {
    count = 2
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${element(var.application_subnets, count.index)}"
    availability_zone = "${element(var.azs, count.index)}"

    tags {
        Name = "Subnet for application servers"
    }
}

resource "aws_route_table" "application-subnet" {
    count = 2
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${element(aws_instance.nat.*.id, count.index)}"
    }

    tags {
        Name = "Subnet for application servers"
    }
}

resource "aws_route_table_association" "application-subnet" {
    count = 2
    subnet_id = "${element(aws_subnet.application-subnet.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.application-subnet.*.id, count.index)}"
}

/*
    ELB configuration
*/
resource "aws_elb" "app_elb" {
    name = "ApplicationElb"

    # using subnets to create network elb instead of classic
    subnets = ["${aws_subnet.public-subnet.*.id}"]
    instances = ["${aws_instance.web-app.*.id}"]
    security_groups = ["${aws_security_group.web.*.id}"]

    listener = {
        instance_port      = 80
        instance_protocol  = "http"
        lb_port            = 8000
        lb_protocol        = "http"
    }

    cross_zone_load_balancing = true

    tags {
        Name = "ELB for the application"
    }
}
