# ==========================================
# 1. EKS Cluster Control Plane
# ==========================================
resource "aws_eks_cluster" "main" {
  name     = "gitops-estate-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id,
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy
  ]

  tags = {
    Name = "gitops-estate-cluster"
  }
}

# ==========================================
# 2. EKS Managed Node Group (SPOT Instances)
# ==========================================
resource "aws_eks_node_group" "spot_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "gitops-estate-spot-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  # Cost Optimization: Use SPOT instances that AWS can reclaim if needed
  capacity_type  = "SPOT"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.node_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.node_amazon_ec2_container_registry_read_only,
  ]

  tags = {
    Name = "gitops-estate-spot-node"
  }
}
