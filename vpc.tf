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
    instance_type = "t3.micro"
    key_name = aws_key_pair.mykey.key_name
    vpc_security_group_ids = [aws_security_group.firewall.id]
    subnet_id = aws_subnet.pubsubnet.id

    tags = {
        Name = "myinstance-tf"
    }

   user_data = <<-EOF
              #!/bin/bash
              systemctl stop apache2 || true
              systemctl disable apache2 || true
              apt-get remove -y apache2 || true

              apt-get update -y
              apt-get install -y docker.io docker-compose-plugin git-all

              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              cd /home/ubuntu
              git clone https://github.com/rohitwithit/studentportal.git
              chown -R ubuntu:ubuntu /home/ubuntu/studentportal
              cd studentportal

              HOST_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
              sed -i "s/HOST_IP/$HOST_IP/g" nginx.conf

              docker compose up -d --build

              sleep 15
              docker compose exec -T backend node seedAdmin.js
              EOF


}