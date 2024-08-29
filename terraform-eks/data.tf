# Declare the data source
data "aws_availability_zones" "azs" {
  state = "available"
}


#Query AWS for the iam policy document for ebs-csi-addon
data "aws_iam_policy_document" "csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}


#Query AWS fot the iam policy document for aws load balancer controller
data "aws_iam_policy_document" "controller" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}


# Qurey the aws infrastructure for the provider url
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}



# Query the aws for the latest addon version for the eks
data "aws_eks_addon_version" "latest" {
  addon_name         = var.addon_name
  kubernetes_version = aws_eks_cluster.eks-cluster.version
  most_recent        = true

  depends_on = [ aws_eks_cluster.eks-cluster ]
}