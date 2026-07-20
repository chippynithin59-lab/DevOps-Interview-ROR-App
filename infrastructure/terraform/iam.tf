# ============================================================
# AWS Load Balancer Controller — lets it create/manage ALBs on
# your behalf when you apply a Kubernetes Ingress.
# ============================================================

data "aws_iam_policy_document" "lb_controller_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn] # VERIFY output name against your module version
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "${var.project_name}-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume.json
}

# Official policy JSON from AWS's docs -- downloaded once during setup, see README.
resource "aws_iam_policy" "lb_controller" {
  name   = "${var.project_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/policies/lb_controller_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
    }
  }
}

resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name # VERIFY output name against your module version
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.lb_controller.metadata[0].name
  }
  set {
    name  = "region"
    value = var.aws_region
  }
  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  depends_on = [kubernetes_service_account.lb_controller]
}

# ============================================================
# Rails app pod — lets it reach S3 via IRSA (no access keys) and
# read the RDS credentials secret from Secrets Manager.
# ============================================================

data "aws_iam_policy_document" "rails_app_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:ror-app:rails-app"] # namespace:serviceaccount-name
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rails_app" {
  name               = "${var.project_name}-rails-app-role"
  assume_role_policy = data.aws_iam_policy_document.rails_app_assume.json
}

data "aws_iam_policy_document" "rails_app_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.app.arn,
      "${aws_s3_bucket.app.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "rails_app_s3" {
  name   = "${var.project_name}-rails-app-s3-policy"
  policy = data.aws_iam_policy_document.rails_app_s3.json
}

resource "aws_iam_role_policy_attachment" "rails_app_s3" {
  role       = aws_iam_role.rails_app.name
  policy_arn = aws_iam_policy.rails_app_s3.arn
}

data "aws_iam_policy_document" "rails_app_secrets" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db.arn]
  }
}

resource "aws_iam_policy" "rails_app_secrets" {
  name   = "${var.project_name}-rails-app-secrets-policy"
  policy = data.aws_iam_policy_document.rails_app_secrets.json
}

resource "aws_iam_role_policy_attachment" "rails_app_secrets" {
  role       = aws_iam_role.rails_app.name
  policy_arn = aws_iam_policy.rails_app_secrets.arn
}