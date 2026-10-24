# Fixtures

Sample infrastructure the examples draw. Each folder is read as text by `plotwork_import` and never applied, so it needs no cloud account and creates nothing.

| Folder | What it is | Read as |
|---|---|---|
| `aws-three-tier/` | VPC, load balancer, ECS service, RDS, ElastiCache, SQS and Lambda, S3 and CloudFront | `terraform` |
| `azure-web-app/` | App Service, SQL, Key Vault, Storage, Application Insights in a VNet | `terraform` |
| `kubernetes-catalogue/` | A namespace with an Ingress, Deployments, Services, a StatefulSet, ConfigMap and Secret | `kubernetes` |

They are not linted or validated: they are inputs, not modules.
