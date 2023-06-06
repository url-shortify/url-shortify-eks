output "secretsmanager_argocd_admin_password_arn" {
  value = aws_secretsmanager_secret.argocd_admin_password.name
}
