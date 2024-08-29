########################################### CREATE VPC ##################################################
#########################################################################################################
resource "aws_vpc" "vpc" {
  cidr_block                   = var.cidr_block
  instance_tenancy             = "default"

  enable_dns_hostnames         = true
  enable_dns_support           = true

  tags = {
    Name = "qr-vpc"
  }
}


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



# Create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id                    = aws_vpc.vpc.id

  depends_on = [ aws_vpc.vpc ]

  tags = {
    Name                    = "vpc-igw"
  }
}



# Allocate an elastic ip address
resource "aws_eip" "eip" {
  count                     = 2 
  vpc                       = true
   
  tags = {
    Name                    = format("eip %d", count.index+1)
  }
}



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



########################################### CREATE KEY PAIR #######################################################
################################################################################################################

resource "aws_key_pair" "key-pair" {
    key_name     = var.key_name
    public_key   = tls_private_key.ssh_key.public_key_openssh
}

# Create a Private key
resource "tls_private_key" "ssh_key" {
  algorithm      = "RSA"
  rsa_bits       = 4096
}

# Put the private key in a local file
resource "local_file" "private-file" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/id_rsa/${aws_key_pair.key-pair.key_name}.pem"
  file_permission = "0600"
}




################################## CREATION OF SECURITY GROUP ####################################################
##################################################################################################################
resource "aws_security_group" "sg" {
  name        = var.qrcode-sg
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id
  

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
      
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
 egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
       
 }

  tags = {
    Name = "allow-tls"
  }
}




############################## CREATION OF IAM ROLE FOR EKS CLUSTER #######################
################################################################################################


resource "aws_iam_role" "eksrole" {
    name                       = var.cluster-rolename
    assume_role_policy         = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "eks.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    })
}



# Attach iam role to eks cluster policy
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn                    = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role                          = aws_iam_role.eksrole.name
}




# Create an IAM role for EKS worker nodes
resource "aws_iam_role" "worker-node-role" {
    name                          = var.node-rolename
    assume_role_policy            = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "ec2.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    })

}



# Attach the IAM policies to the EKS worker nodes
resource "aws_iam_role_policy_attachment" "WorkerPolicy" {
  policy_arn                      = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role                            = aws_iam_role.worker-node-role.name
}

resource "aws_iam_role_policy_attachment" "CNIPolicy" {
  policy_arn                      = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role                            = aws_iam_role.worker-node-role.name
}

resource "aws_iam_role_policy_attachment" "ContainerRegistry" {
  policy_arn                      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role                            = aws_iam_role.worker-node-role.name
}




# IAM role for csi drive addon
resource "aws_iam_role" "ebs_csi_driver" {
  assume_role_policy              = data.aws_iam_policy_document.csi.json
  name                            = var.csi_role_name
}

#Policy attachemet to iam role addon
resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver" {
  role                            = aws_iam_role.ebs_csi_driver.name
  policy_arn                      = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}




# Create Iam role for aws load balancer controller
resource "aws_iam_role" "load_balancer_controller" {
  assume_role_policy              = data.aws_iam_policy_document.controller.json
  name                            = var.controller_rolename
}

# Create a policy to the iam role of the load balancer controller
resource "aws_iam_policy" "controller_policy" {
  policy                          = jsonencode(jsondecode(file("controller.json")))
  name                            = var.controller_policyname
}


# Attach a policy to the the role of the load balancer
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role                            = aws_iam_role.load_balancer_controller.name
  policy_arn                      = aws_iam_policy.controller_policy.arn
}



######################################### CREATION OF CLUSTER #################################
###############################################################################################

resource "aws_eks_cluster" "eks-cluster" {
  name                    = var.cluster
  role_arn                = aws_iam_role.eksrole.arn
  
  

  vpc_config {
    # private subnets to configure kubernetes nodes and public to expose services from kubernetes to the internet by using load balancer
    subnet_ids             = concat(aws_subnet.private-subnet.*.id, aws_subnet.public-subnet.*.id) 
  }
 
}



# Create the EKS NODE GROUP
resource "aws_eks_node_group" "ec2-node-group" {
  cluster_name             = aws_eks_cluster.eks-cluster.name
  node_group_name          = var.nodegroup
  node_role_arn            = aws_iam_role.worker-node-role.arn
  subnet_ids               = aws_subnet.private-subnet.*.id 
  

  scaling_config {
    desired_size           = 2
    max_size               = 4
    min_size               = 1
  }

  update_config {
    max_unavailable        = 1
  }

  instance_types           = [var.instance-type]

  remote_access {
    ec2_ssh_key            = aws_key_pair.key-pair.key_name 
    source_security_group_ids = [aws_security_group.sg.id]
  }
  
}



########################### CREATE AN OIDC IDENTITY PROVIDER ########################################
#####################################################################################################

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list           = ["sts.amazonaws.com"]
  thumbprint_list          = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url                      = data.tls_certificate.eks.url

}





######################### CREATION OF EBS CSI DRIVE ON ###############################################
#######################################################################################################


resource "aws_eks_addon" "csi_driver" {
  cluster_name             = aws_eks_cluster.eks-cluster.name
  addon_name               = var.addon_name
  addon_version            = data.aws_eks_addon_version.latest.version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

}