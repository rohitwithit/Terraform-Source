resource "aws_key_pair" "mykey1" {
    key_name = "Mykey"
    public_key = file("ec2key.pub")
}

resource "aws_security_group" "mysg" {
    name = "tf-sg"
    vpc_id = "vpc-0f7baea6461ad3611"

    ingress {
        from_port = 80 
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
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

resource "aws_instance" "instance1" {

    ami = "ami-0c7632fb77f35db43"
    instance_type = "t3.micro"
    key_name = aws_key_pair.mykey1.key_name
    vpc_security_group_ids = [aws_security_group.mysg.id]
    tags = {
        name = "Myinstance"
    } 
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                echo "<h1> Instance Creation using Terraform - Rohit Mahale </h1>" > /var/www/html/index.html
            EOF
}
