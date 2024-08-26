# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block                   = var.cidr_block
  instance_tenancy             = "default"

  enable_dns_hostnames         = true
  enable_dns_support           = true

  tags = {
    Name = "qr-vpc"
  }
}
##########################################################################################################
##########################################################################################################

# Create subnets
resource "aws_subnet" "public-subnet" {
  count                      = 2  
  vpc_id                     = aws_vpc.vpc.id
  cidr_block                 = var.public-subnets[count.index]
  availability_zone          = data.aws_availability_zones.azs.names[count.index]
  map_public_ip_on_launch    = true 

  tags = {
    Name                     =  format("pub-sub %d", count.index+1)
  }
}


resource "aws_subnet" "private-subnet" {
  count                     = 2 
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.private-subnets[count.index]
  availability_zone         = data.aws_availability_zones.azs.names[count.index]

  tags = {
    Name                    = format("pri-sub %d", count.index+1)
  }
}
##########################################################################################################
#########################################################################################################


# Create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id                    = aws_vpc.vpc.id

  depends_on = [ aws_vpc.vpc ]

  tags = {
    Name                    = "vpc-igw"
  }
}
##########################################################################################################
##########################################################################################################

# Allocate an elastic ip address
resource "aws_eip" "eip" {
  count                     = 2 
  vpc                       = true
   
  tags = {
    Name                    = format("eip %d", count.index+1)
  }
}
##########################################################################################################
##########################################################################################################

# Create nat gateway
resource "aws_nat_gateway" "nat" {
  count                     = 2  
  allocation_id             = element(aws_eip.eip.*.id, count.index)
  subnet_id                 = element(aws_subnet.public-subnet.*.id, count.index)
  
  depends_on = [
    aws_eip.eip,
    aws_subnet.public-subnet]

  tags = {
    Name                    = format("nat-gw %d", count.index+1)
  }
}
###########################################################################################################
###########################################################################################################

# Create route tables and attach it to internet gateway and nat gateway

# For  private route tables
resource "aws_route_table" "private-rt" {
  count                    = 2     
  vpc_id                   = aws_vpc.vpc.id

  route {
    cidr_block             = "0.0.0.0/0"
    nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
  }

  depends_on = [ aws_nat_gateway.nat ]

  tags = {
    Name                   = format("private-rt %d", count.index+1)
  }
}

# For public route tables
resource "aws_route_table" "public-rt" {
  count                    = 2  
  vpc_id                   = aws_vpc.vpc.id

  route {
    cidr_block             = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.gw.id
  }

  depends_on = [ aws_internet_gateway.gw ]

  tags = {
    Name                   = format("public-rt %d", count.index+1)
  }
}
#############################################################################################################
#############################################################################################################



# Create route table associations and attach it to both the private and public subnets

# For private subnets
resource "aws_route_table_association" "private" {
  count                   = 3  
  subnet_id               = element(aws_subnet.private-subnet.*.id, count.index)
  route_table_id          = element(aws_route_table.private-rt.*.id, count.index)

  depends_on = [ 
    aws_route_table.private-rt,
    aws_subnet.private-subnet
     ]  
}


# For public subnets
resource "aws_route_table_association" "public" {
  count                   = 3  
  subnet_id               = element(aws_subnet.public-subnet.*.id, count.index)
  route_table_id          = element(aws_route_table.public-rt.*.id, count.index)

  depends_on = [ 
    aws_route_table.public-rt,
    aws_subnet.public-subnet
    ]
}