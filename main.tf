provider "aws" {
  region = ""
  access_key = ""
  secret_key = ""
}

## Custome VPC
resource "aws_vpc" "webonise" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "webonise"
  }
}
## Public Subnet1
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.webonise.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "public-subnet"
  }
}
## Public Subnet2
resource "aws_subnet" "public-subnet2" {
  vpc_id     = aws_vpc.webonise.id
  availability_zone = "us-east-1b"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "public-subnet2"
  }
}
## Internet Gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.webonise.id

  tags = {
    Name = "gateway"
  }
}
## Route Table for Public subnet
resource "aws_route_table" "publicRout" {
  vpc_id = aws_vpc.webonise.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "publicRout"
  }
}
## Route Table attached to public subnet
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.publicRout.id
}
## Route Table attached to public subnet2
resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.publicRout.id
}
## Private Subnet
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.webonise.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}
## Private Subnet2
resource "aws_subnet" "private-subnet2" {
  vpc_id     = aws_vpc.webonise.id
  availability_zone = "us-east-1b"
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "private-subnet2"
  }
}
## Allocate Elastic IP to NAT Gateway
resource "aws_eip" "elasticip" {
  //instance = aws_instance.web.id
  vpc      = true
}
## NAT Gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.elasticip.id
  subnet_id     = aws_subnet.public-subnet.id
  depends_on = [aws_internet_gateway.gateway]

  tags = {
    Name = "natgw"
  }
}
## Route Table for Private subnet
resource "aws_route_table" "privateRout" {
  vpc_id = aws_vpc.webonise.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   gateway_id = aws_nat_gateway.natgw.id
  # }
  //cidr_block = "10.0.2.0/24"
  tags = {
    Name = "privateRout"
  }
}
## Route Table Association to private subnet
resource "aws_route_table_association" "b" {
    subnet_id = aws_subnet.private-subnet.id
    route_table_id = aws_route_table.privateRout.id
}
## Route Table Association to private subnet2
resource "aws_route_table_association" "b1" {
    subnet_id = aws_subnet.private-subnet2.id
    route_table_id = aws_route_table.privateRout.id
}

## Security Group For load-Balancer
resource "aws_security_group" "loadbalancerSG" {
  name        = "loadbalancerSG"
  //description = "A load balancer security group allowing access from internet"
  vpc_id      = aws_vpc.webonise.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "loadbalancerSG"
  }
}
## Security Group For WebServer
resource "aws_security_group" "WebServerSG" {
  name        = "WebServerSG"
  //description = "A load balancer security group allowing access from internet"
  vpc_id      = aws_vpc.webonise.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.loadbalancerSG.id}"]
    //cidr_blocks      = ["${aws_security_group.loadbalancerSG.id}"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.loadbalancerSG.id}"]
    //cidr_blocks      = ["${aws_security_group.loadbalancerSG.id}"]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.loadbalancerSG.id}"]
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "WebServerSG"
  }
}

## Security Group For Databse
resource "aws_security_group" "dbSG" {
  name        = "dbServer"
  //description = "A load balancer security group allowing access from internet"
  vpc_id      = aws_vpc.webonise.id

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.WebServerSG.id}"]
    //cidr_blocks      = ["${aws_security_group.loadbalancerSG.id}"]
  }  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dbServer"
  }
}


## EC2 instance in private subnet with user-data to install nodejs,nginx
resource "aws_instance" "webServer" {
  ami           = "ami-042e8287309f5df03"
  associate_public_ip_address = false
  instance_type = "t3.micro"
  subnet_id      = aws_subnet.private-subnet.id
  vpc_security_group_ids      = ["${aws_security_group.WebServerSG.id}"]

  user_data = <<-EOF
	            #!/bin/bash
              sudo apt -y update
              sudo apt -y install nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              sudo apt install git
              cd
              git clone https://github.com/codefellows/javascript-b15-notes.git nodejs
              cd nodejs
              npm install && bower install
	            EOF
  tags = {
    Name = "webServer"
  }
}
## A Mysql RDS in private subnet.
resource "aws_db_subnet_group" "db-subnet" {
  name       = "db-subnet"
  subnet_ids = ["${aws_subnet.private-subnet.id}", "${aws_subnet.private-subnet2.id}"]
}
resource "aws_db_instance" "webServerDB" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "webServerDB"
  username             = "admin"
  password             = "admin123#$"
  parameter_group_name = "default.mysql8.0"
  //skip_final_snapshot  = true

  vpc_security_group_ids      = ["${aws_security_group.dbSG.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.db-subnet.name}"
}

## Application Load Balancer
resource "aws_lb" "webServerALB" {
  name               = "webServerALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancerSG.id]
  subnets = [aws_subnet.public-subnet.id,aws_subnet.public-subnet2.id]


  tags = {
    Environment = "webServerALB"
  }
}
## Target group
resource "aws_lb_target_group" "targetGroupALB" {
  name     = "targetGroupALB"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webonise.id
}
## Target group attached with instance
resource "aws_lb_target_group_attachment" "targetGroupAttachment" {
  target_group_arn = aws_lb_target_group.targetGroupALB.arn
  target_id        = aws_instance.webServer.id
  port             = 80
}
## Add Listners for ALB
resource "aws_lb_listener" "albListner" {
  load_balancer_arn = aws_lb.webServerALB.arn
  port              = "80"
  protocol          = "HTTP"

   default_action {
    target_group_arn = "${aws_lb_target_group.targetGroupALB.id}"
    type             = "forward"
  }
}
