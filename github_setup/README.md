<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.44.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.24.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_backend"></a> [eks\_backend](#module\_eks\_backend) | ../modules/backend | n/a |
| <a name="module_pipeline_backend"></a> [pipeline\_backend](#module\_pipeline\_backend) | ../modules/backend | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.github_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.tf_github_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [random_integer.backend](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/integer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_github_username"></a> [github\_username](#input\_github\_username) | Github username | `string` | `"yemisprojects"` | no |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | github repo name | `string` | `"eks-infra"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_role"></a> [aws\_role](#output\_aws\_role) | github actions role |
| <a name="output_cicd_tfstate_bucket"></a> [cicd\_tfstate\_bucket](#output\_cicd\_tfstate\_bucket) | Name of the bucket for S3 pipeline backend |
| <a name="output_cicd_tfstate_db"></a> [cicd\_tfstate\_db](#output\_cicd\_tfstate\_db) | Name of dynamodb table for pipeline remote state |
| <a name="output_eks_tfstate_bucket"></a> [eks\_tfstate\_bucket](#output\_eks\_tfstate\_bucket) | Name of the bucket for S3 eks backend |
| <a name="output_eks_tfstate_db"></a> [eks\_tfstate\_db](#output\_eks\_tfstate\_db) | Name of dynamodb table for eks remote state |
<!-- END_TF_DOCS -->
