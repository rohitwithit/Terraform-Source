resource "aws_vpc" "myvpc" {
    cidr_block = "192.168.0.0/20"
    tags = {
      Name = "myvpc"
    } 
}

resource "aws_subnet" "pubsubnet" {
  cidr_block = "192.168.0.0/22"
  vpc_id = aws_vpc.myvpc.id
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "publicSubnet"
  }
}

resource "aws_internet_gateway" "igw"{

    vpc_id = aws_vpc.myvpc.id
    tags = {
      Name = "igw"
    }
}
resource "aws_route_table" "pubroute" {
    vpc_id = aws_vpc.myvpc.id
    tags = {
      Name = "pubroute"
    }

    route {
        gateway_id = aws_internet_gateway.igw.id
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_route_table_association" "rsa" {
    route_table_id = aws_route_table.pubroute.id
    subnet_id = aws_subnet.pubsubnet.id
}


resource "aws_subnet" "prisubnet" {
  cidr_block = "192.168.4.0/22"
  vpc_id = aws_vpc.myvpc.id
  availability_zone = "ap-south-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "privateSubnet"
  }
}

resource "aws_eip" "static" {
    domain = "vpc"
}

resource "aws_nat_gateway" "mynat" {
    allocation_id = aws_eip.static.id
    subnet_id = aws_subnet.pubsubnet.id 

    tags = {
        Name = "mynat"
    }   
}

resource "aws_route_table" "rt2" {
    vpc_id = aws_vpc.myvpc.id
    tags = {
        Name = "private route"
    }
    route {
        nat_gateway_id = aws_nat_gateway.mynat.id
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_route_table_association" "rta2" {

    subnet_id = aws_subnet.prisubnet.id
    route_table_id = aws_route_table.rt2.id
}

resource "aws_security_group" "firewall" {
    name = "firewall"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "mykey" {
    key_name = "mykey"
    public_key = file("ec2key.pub")  
}

resource "aws_instance" "myinstance" {

    ami = "ami-0c7632fb77f35db43"
    instance_type = "t3.small"
    key_name = aws_key_pair.mykey.key_name
    vpc_security_group_ids = [aws_security_group.firewall.id]
    subnet_id = aws_subnet.pubsubnet.id

    tags = {
        Name = "myinstance-tf"
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                echo "<h1> Instance Creation using Terraform - Rohit Mahale </h1>" > /var/www/html/index.html
            EOF
}

resource "aws_instance" "priinstance" {

    ami = "ami-0c7632fb77f35db43"
    instance_type = "t3.small"
    key_name = aws_key_pair.mykey.key_name
    vpc_security_group_ids = [aws_security_group.firewall.id]
    subnet_id = aws_subnet.prisubnet.id

    tags = {
        Name = "myinstance-pri"
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                echo "<h1> Instance Creation using Terraform - Rohit Mahale </h1>" > /var/www/html/index.html
            EOF
}
