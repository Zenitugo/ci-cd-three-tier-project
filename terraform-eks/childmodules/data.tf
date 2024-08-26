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
      variable = "${replace(var.openid-url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [var.openid-arn]
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
      variable = "${replace(var.openid-url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [var.openid-arn]
      type        = "Federated"
    }
  }
}