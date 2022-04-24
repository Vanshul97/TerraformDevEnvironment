//VPC Creation
resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}
//Subnet Creation --public subnet
resource "aws_subnet" "mtc_subnet" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2c"

  tags = {
    Name = "dev-public"
  }
}
//Internet Gateway Creation
resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}
//Route Table Creation
resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}
//Default Route Creation
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id
}
//Route Table Association Creation
resource "aws_route_table_association" "mtc_public_assoc" {
  subnet_id      = aws_subnet.mtc_subnet.id
  route_table_id = aws_route_table.mtc_public_rt.id
}
//Security Group Creation
resource "aws_security_group" "mtc_sg" {
  name        = "dev_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
//Key Pair Creation
resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtckey"
  public_key = file("~/.ssh/mtckey.pub")
}
//Instance(dev node) creation
resource "aws_instance" "mtc_instance" {
  ami                    = data.aws_ami.latest-ubuntu.id //used from datasources
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_subnet.id
  user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 10
  }
  provisioner "local-exec" {
    command =templatefile("windows-ssh-config.tpl",{
      hostname=self.public_ip,
      user="ubuntu",
      identityfile="~/.ssh/mtckey"
    })
    interpreter = [
      "Powershell","-Command"
    ]
  }
  tags = {
    Name = "dev-node"
  }

}
