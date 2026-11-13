# This is Main.tf file create the complete three tier infrastructure for the organization

# create the vpc

resource "aws_vpc" "quant-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "quant-vpc"
    Env  = "prod"
    Owner = "Othniel"
  }
}

# Create the required six subnets


resource "aws_subnet" "Web-public-A" {
  vpc_id     = aws_vpc.quant-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-public-A"
    Env  = "prod"
    Owner = "Othniel"
  }  
  
}


resource "aws_subnet" "Web-public-B" {
  vpc_id     = aws_vpc.quant-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-public-B"
    Env  = "prod"
    Owner = "Othniel"
  }
}

resource "aws_subnet" "App-private-A" {
  vpc_id     = aws_vpc.quant-vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "App-private-A"
    Env  = "prod"
    Owner = "Othniel"
  }
}

resource "aws_subnet" "App-private-B" {
  vpc_id     = aws_vpc.quant-vpc.id
  cidr_block = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "App-private-B"
    Env  = "prod"
    Owner = "Othniel"
  }
}

resource "aws_subnet" "DB-private-A" {
  vpc_id     = aws_vpc.quant-vpc.id
  cidr_block = "10.0.21.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "DB-private-A"
    Env  = "prod"
    Owner = "Othniel"
  }
}


resource "aws_subnet" "DB-private-B" {
  vpc_id     = aws_vpc.quant-vpc.id
  cidr_block = "10.0.22.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "DB-private-B"
    Env  = "prod"
    Owner = "Othniel"
  }
}

# Create the internet gateway

resource "aws_internet_gateway" "quant-gw" {
  vpc_id = aws_vpc.quant-vpc.id

  tags = {
    Name = "quant-gw"
  }
}


# Create elastic ip for the NAT gateway

resource "aws_eip" "quant-eip" {
  domain  = "vpc"
}
  
# Create NAT gateway

resource "aws_nat_gateway" "quant-NATGW" {
  allocation_id = aws_eip.quant-eip.id
  subnet_id     = aws_subnet.Web-public-A.id

  tags = {
    Name = "quant-NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.quant-gw]
}


# Create public route table

resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.quant-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.quant-gw.id
  }
  

  tags = {
    Name = "publicRT"
  }
}    
  


# Create private route table 

resource "aws_route_table" "privateRT" {
  vpc_id = aws_vpc.quant-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.quant-NATGW.id
  }

  
  tags = { 
    Name = "privateRT"
  }
}    
  



# Create route table associations

resource "aws_route_table_association" "public-RT-Association-A" {
  subnet_id      = aws_subnet.Web-public-A.id
  route_table_id = aws_route_table.publicRT.id
}


resource "aws_route_table_association" "public-RT-Association-B" {
  subnet_id      = aws_subnet.Web-public-B.id
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_route_table_association" "private-RT-Association-A" {
  subnet_id      = aws_subnet.App-private-A.id
  route_table_id = aws_route_table.privateRT.id
}


resource "aws_route_table_association" "private-RT-Association-B" {
  subnet_id      = aws_subnet.App-private-B.id
  route_table_id = aws_route_table.privateRT.id
}


resource "aws_route_table_association" "DB-RT-Association-A" {
  subnet_id      = aws_subnet.DB-private-A.id
  route_table_id = aws_route_table.privateRT.id
}


resource "aws_route_table_association" "DB-RT-Association-B" {
  subnet_id      = aws_subnet.DB-private-B.id
  route_table_id = aws_route_table.privateRT.id
}


# Create the required security groups for the infrastructure

## Create the web security group 

resource "aws_security_group" "Web-SG" {
  name        = "Web-SG"
  description = "Allow internet traffic for Web tier instances"
  vpc_id      = aws_vpc.quant-vpc.id

  tags = {
    Name = "Web-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.Web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.Web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp" {
  security_group_id = aws_security_group.Web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1

}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.Web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  
}


## Create App security group


resource "aws_security_group" "App-SG" {
  name        = "App-SG"
  description = "Allow salected traffic into the application Instances"
  vpc_id      = aws_vpc.quant-vpc.id

  tags = {
    Name = "App-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh-2" {
  security_group_id = aws_security_group.App-SG.id
  referenced_security_group_id = aws_security_group.Web-SG.id
  from_port         = 22  
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-app-port" {
  security_group_id = aws_security_group.App-SG.id
  referenced_security_group_id = aws_security_group.Web-SG.id
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp-2" {
  security_group_id = aws_security_group.App-SG.id
  referenced_security_group_id = aws_security_group.Web-SG.id
  from_port          = -1 
  ip_protocol        = "icmp"
  to_port            = -1

}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-2" {
  security_group_id = aws_security_group.App-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


## Create DB security group


resource "aws_security_group" "DB-SG" {
  name        = "DB-SG"
  description = "Allow selected traffic into the database Instances"
  vpc_id      = aws_vpc.quant-vpc.id

  tags = {
    Name = "DB-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh-3" {
  security_group_id = aws_security_group.DB-SG.id
  referenced_security_group_id = aws_security_group.App-SG.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-DB-port" {
  security_group_id = aws_security_group.DB-SG.id
  referenced_security_group_id = aws_security_group.App-SG.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp-3" {
  security_group_id = aws_security_group.DB-SG.id
  referenced_security_group_id = aws_security_group.App-SG.id
  from_port         = -1 
  ip_protocol       = "icmp"
  to_port           = -1
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-3" {
  security_group_id = aws_security_group.DB-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Create the Aws Instances that are required


## Set the ami date source

data "aws_ami" "ubuntu" {
  
  most_recent      = true
  
  

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }



 owners = ["099720109477"] # Canonical

}


resource "aws_instance" "Bastion-Server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id  = aws_subnet.Web-public-A.id
  vpc_security_group_ids = [aws_security_group.Web-SG.id]
  key_name   = var.key_name 

  tags = {
    Name = "Bastion-Server"
  }
}


 


resource "aws_instance" "Web-VM" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id  = aws_subnet.Web-public-B.id 
  vpc_security_group_ids = [aws_security_group.Web-SG.id] 
  key_name  = var.key_name

  tags = {
    Name = "Web-VM"
  }
}

 


resource "aws_instance" "App-VM" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id   = aws_subnet.App-private-A.id
  vpc_security_group_ids = [aws_security_group.App-SG.id] 
  key_name  = var.key_name

  tags = {
    Name = "App-VM"
  }
}




 


resource "aws_instance" "DB-VM" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id   = aws_subnet.DB-private-A.id 
  vpc_security_group_ids = [aws_security_group.DB-SG.id] 
  key_name  = var.key_name 

  tags = {
    Name = "DB-VM"
  }
}



