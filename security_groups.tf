# ==========================================
# 1. EKS Cluster Control Plane Security Group
# ==========================================
resource "aws_security_group" "cluster" {
  name        = "gitops-estate-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.main.id

  # Allow outbound traffic to anywhere (updates, API calls, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic from control plane"
  }

  tags = {
    Name = "gitops-estate-cluster-sg"
  }
}

# ==========================================
# 2. EKS Worker Nodes Security Group
# ==========================================
resource "aws_security_group" "node" {
  name        = "gitops-estate-node-sg"
  description = "Security group for all nodes in the EKS cluster"
  vpc_id      = aws_vpc.main.id

  # Allow nodes to communicate with each other (crucial for microservice mesh/pod-to-pod)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow nodes to communicate with each other"
  }

  # Allow worker nodes to accept communication from the EKS cluster control plane
  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow control plane to access worker kubelet"
  }



  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow control plane webhook communication"
  }

  # Allow worker nodes full outbound internet access (via NAT gateway for pulling images, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow nodes all outbound internet access"
  }

  tags = {
    Name                                          = "gitops-estate-node-sg"
    "kubernetes.io/cluster/gitops-estate-cluster" = "owned"
  }
}

# ==========================================
# 3. Application Load Balancer (ALB) Security Group
# ==========================================
resource "aws_security_group" "alb" {
  name        = "gitops-estate-alb-sg"
  description = "Security group for public ALB ingress"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP public traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Allow HTTPS public traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Restrict egress: Only allow the ALB to talk to the EKS Worker Nodes
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.node.id]
    description     = "Allow ALB outbound traffic exclusively to EKS worker nodes"
  }

  tags = {
    Name = "gitops-estate-alb-sg"
  }
}