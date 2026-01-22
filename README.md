# OpenTelemetry Project on EKS (Terraform, Helm)
Terraform configurations to deploy OpenTelemetry project using Helm on aws free tier account

This project creates:
- A VPC (public+private subnets across 3 AZs)
- An EKS cluster (IRSA enabled) with two managed node groups
- Explicit EKS add-ons via `aws_eks_addon`: vpc-cni, kube-proxy, coredns
- Helm install of the OpenTelemetry Demo, exposing the Frontend Proxy via a LoadBalancer

## Prereqs
- Terraform `>= 1.5`
- AWS CLI v2 installed and configured (for `aws eks get-token`)
- kubectl installed

## Deploy

```bash
terraform init -upgrade
terraform validate
terraform apply
```

Configure `kubectl`:
```bash
$(terraform output -raw kubeconfig_hint)
```

Get public URL:
```bash
terraform output otel_demo_frontendproxy_url
terraform output grafana_url_via_proxy
terraform output jaeger_url_via_proxy
```

If the URL shows "(pending)", wait 1–3 minutes for the LoadBalancer to be provisioned and run:
```bash
terraform refresh
terraform output otel_demo_frontendproxy_url
```

## Clean up
```bash
terraform destroy
```

## Notes
- Providers use EKS module outputs + AWS CLI token to avoid reading the cluster before it's created.
- Helm provider uses v3 syntax (kubernetes as an argument object).

