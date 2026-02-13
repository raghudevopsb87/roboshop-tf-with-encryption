resource "aws_eks_cluster" "main" {
  name     = var.env
  role_arn = aws_iam_role.cluster.arn
  version  = "1.34"
  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
}

resource "aws_launch_template" "main" {
  name     = "eks-ng-lt"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      encrypted   = true
      kms_key_id  = var.kms
    }
  }

}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.xlarge","t3.2xlarge"]
  capacity_type   = "SPOT"

  launch_template {
    name    = aws_launch_template.main.name
    version = "$Latest"
  }

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 10
  }

  update_config {
    max_unavailable = 1
  }
}

resource "aws_eks_access_entry" "workstation" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = "arn:aws:iam::739561048503:role/workstation-role"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "workstation" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::739561048503:role/workstation-role"

  access_scope {
    type       = "cluster"
  }
}

resource "null_resource" "kubeconfig" {

  depends_on = [aws_eks_node_group.main]

  triggers = {
    cluster = timestamp()
  }

  provisioner "local-exec" {
    command = "rm -rf ~/.kube ; aws eks update-kubeconfig --name dev ; kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
  }
}

resource "aws_eks_addon" "pod-identity" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "external-dns" {
  depends_on = [aws_eks_addon.pod-identity]
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "external-dns"
}

resource "aws_eks_pod_identity_association" "external-dns" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "external-dns"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external-dns.arn
}

resource "aws_eks_pod_identity_association" "cluster-autoscaler" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "default"
  service_account = "cluster-autoscaler-aws-cluster-autoscaler"
  role_arn        = aws_iam_role.cluster-autoscaler.arn
}



