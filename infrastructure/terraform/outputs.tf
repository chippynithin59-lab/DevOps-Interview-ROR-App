output "cluster_name" {
  description = "EKS cluster name, needed for `aws eks update-kubeconfig`"
  value       = module.eks.cluster_name # VERIFY against your module version's actual output name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_rails_app_url" {
  value = aws_ecr_repository.rails_app.repository_url
}

output "ecr_nginx_url" {
  value = aws_ecr_repository.nginx.repository_url
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "rds_port" {
  value = aws_db_instance.main.port
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app.bucket
}

output "rails_app_irsa_role_arn" {
  description = "Put this in k8s/serviceaccount.yaml's eks.amazonaws.com/role-arn annotation"
  value       = aws_iam_role.rails_app.arn
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "alb_security_group_id" {
  description = "Put this in k8s/ingress.yaml's alb.ingress.kubernetes.io/security-groups annotation"
  value       = aws_security_group.alb.id
}

output "configure_kubectl" {
  description = "Run this command after apply to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_ecr.arn
}