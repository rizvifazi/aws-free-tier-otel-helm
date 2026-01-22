output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "kubeconfig_hint" {
  description = "Use aws eks update-kubeconfig to talk to the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "otel_demo_frontendproxy_url" {
  description = "Public URL for the OTel Demo Frontend Proxy"
  value       = local.frontendproxy_hostname != "" ? "http://${local.frontendproxy_hostname}:8080" : "(pending)"
}

output "grafana_url_via_proxy" {
  description = "Grafana proxied through Frontend Proxy"
  value       = local.frontendproxy_hostname != "" ? "http://${local.frontendproxy_hostname}:8080/grafana" : "(pending)"
}

output "jaeger_url_via_proxy" {
  description = "Jaeger UI proxied through Frontend Proxy"
  value       = local.frontendproxy_hostname != "" ? "http://${local.frontendproxy_hostname}:8080/jaeger/ui" : "(pending)"
}
