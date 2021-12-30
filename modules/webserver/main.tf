resource "aws_default_security_group" "default-SG"{
  vpc_id = var.vpc_id
  ingress{
    description = "SSH to Instanct"
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = [var.my_public_ip] 
  }
  ingress{
    description = "SHH to Instanct"
    from_port = "8080"
    to_port = "8080"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress{
    description = "Outbound request allowed to all ports and destination on any protocol"
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]   
    prefix_list_ids = [] 
  }
  tags = {
    Name: "${var.env_prefix}-SG"
  }
}

data "aws_ami" "latest-amazon-image"{
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = [var.image_name]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key"{
  key_name = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-instance"{
  ami = data.aws_ami.latest-amazon-image.id
  instance_type = var.instance_type

  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_default_security_group.default-SG.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  
  user_data = file("external-script.sh")

  tags = {
    Name: "${var.env_prefix}-server"
  }

}
/*
resource "aws_security_group" "myapp-SG"{
  name = "myapp-SG"
  vpc_id = aws_vpc.myapp-vpc.id
  ingress{
    description = "SSH to Instanct"
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = [var.my_public_ip] 
  }
  ingress{
    description = "SHH to Instanct"
    from_port = "8080"
    to_port = "8080"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress{
    description = "Outbound request allowed to all ports and destination on any protocol"
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]   
    prefix_list_ids = [] 
  }
  tags = {
    Name: "${var.env_prefix}-SG"
  }
}

resource "aws_instance" "myapp-instance"{
  ami = data.aws_ami.latest-amazon-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-SG.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  
  user_data = <<EOF
              #!/bin/bash
              sudo yum update -y && sudo yum install -y docker
              sudo systemctl start docker
              sudo usermod -aG docker ec2-user
              docker run -it -p 8080:80 --name nginx -d nginx               
              EOF

  tags = {
    Name: "${var.env_prefix}-server"
  }

}

*/