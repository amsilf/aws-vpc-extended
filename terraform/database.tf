/*
  Database Servers
*/
resource "aws_security_group" "db" {
    count = 2

    name = "vpc_db ${element(var.azs, count.index)}"
    description = "Allow incoming database connections."

    ingress { # SQL Server
        from_port = 1433
        to_port = 1433
        protocol = "tcp"
        security_groups = ["${element(aws_security_group.app_servers.*.id, count.index)}"]
    }

    ingress { # MySQL
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["${element(aws_security_group.app_servers.*.id, count.index)}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${var.vpc_cidr}"]
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

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "DBServers"
    }
}

resource "aws_db_instance" "db" {
    count = 2

    engine            = "mysql"
    engine_version    = "5.6.39"
    instance_class    = "db.t2.micro"
    allocated_storage = 10
    name              = "dbserver${count.index}"
    multi_az          = true
    username          = "${var.dblogin}"
    password          = "${var.dbpassword}"
    db_subnet_group_name = "${aws_db_subnet_group.database-subnet-group.name}"

    tags {
        Name = "DB Server"
    }
}