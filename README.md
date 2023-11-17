# DevSecOps CI/CD with Jenkins and ArgoCD

This repository contains the terraform code and github workflow used to automate the deployment of the infrastructure required to implement an end-to-end DevSecOps CI/CD pipeline to EKS. CI is implemented using Jenkins and CD via ArgoCD (GitOps). This repo is intended to be used with the two repositories listed below.
- https://github.com/yemisprojects/eks-app (contains application to be containerized)
- https://github.com/yemisprojects/kubernetes-manifests (contains helm charts for deployment by ArgoCD)

## Infrastructure pipeline Architecture

<img width="2159" alt="GitHub Actions CICD for Terraform" src="">

# Prerequisites

- Github account
- AWS account (Note: This project does not fall under the free tier)
- Domain (AWS R53 or third party)
- kubectl installed locally
- Terraform installed locally

## Github initial setup (required)

In addition to the above requirements, there are other prerequisite steps to deploy the resources and use the workflows from this repository in your AWS account. Most of these have been automated via terraform. 

As a first step, fork this repository and run the commands below. Note down the values of the terraform output for the next step

```t
cd github_setup && terraform init
terraform fmt && terraform apply -auto-approve
```

Using the command above, terraform creates the following resources: 

1. **S3 buckets to store terraform's state & DynamoDB tables to lock the state**

    Terraform utilizes a [state file](https://www.terraform.io/language/state) to store information about the current state of your managed infrastructure and associated configuration. This file will need to be persisted between different runs of the workflow. The recommended approach is to store this file within S3 or other similar remote backend. To lock writes to the state file when in use a DynamoDB table is required when using S3 backend.

2. **IAM role utilized by Github to authenticate to AWS**: 

    An IAM Role will be via by the pipeline using OIDC to authenticate to AWS and carry out actions in your AWS account. At a minimum, the role requires permission to the S3 buckets, dynamoDB tables and to deploy the desired resources. See this [AWS blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/) for more information. 

#### GitHub Secrets

The next step is to create the following github secrets in your  repository. Use the terraform output values from the previous step.

- `AWS_ROLE` : Federated IAM role to be utilized by Github actions
- `CICD_TFSTATE_BUCKET` : Bucket name for remote backed for Jenkins instance
- `CICD_TFSTATE_DB` : DynamoDB table for state locking for Jenkins instance
- `EKS_TFSTATE_BUCKET` : Bucket name for remote backed for EKS cluster
- `EKS_TFSTATE_DB` : DynamoDB table for state locking for EKS cluster

Instructions to add the secrets to the repository can be found [here](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository).

## How to Deploy resources via Github Actions

1. Fork this repo and use the steps in the previous sections to update your github secrets
2. **Required**: Update value of the `grafana_domain_name` variable in `eks/dev/variables.tf`' to your domain name
3. You can push your change directly to the main branch but to see the terraform 
plan from a PR (pull request) perspective i suggest you create a new branch and check in the Terraform code with your change.
4. Create a Pull Request (PR) in GitHub once you're ready to merge your code.
3. A GitHub Actions workflow will trigger to ensure your code is well formatted and validated. In addition, a Terraform plan will run to generate a preview of the changes that will happen in your AWS account and displayed as a comment on the PR.
4. Once the PR is appropriately reviewed, the PR can be merged into your main branch.
5. After merge, another GitHub Actions job will trigger from the main branch and deploy the infrastructure using Terraform.

## Resources Deployed

Below is a list of key resources deployed via Github Actions. For a complete list of all resources, see the [doc for terraform](https://github.com/yemisprojects/eks-infra/tree/main/eks_infra/dev#readme) in this repo.

1. Provisioned Jenkins Server running on EC2
2. EKS Cluster with 1 managed Node group
3. Karpenter cluster auto-scaler
4. ArgoCD
5. Prometheus and Grafana



## How to Access grafanna
An AWS load balancer controller was installed and used to expose Grafana service at Use the default credentials to access Grafana default credentials below.  

```
Username: admin
Password: prom-operator
```

Kubernets Dashboard ID that can be imported within grafana: `1860`

## How to Access ArgoCD server 
You can use port forwarding to access ArgoCD UI for initial configurations 

```
kubectl port-forward svc/vproapp-service 8081:443
```

The default username is `admin` and the default password can be obtained using the command below:
`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

Goto your browser on `https://localhost:8080` and login with the credential abobe

Note: The ideal method to access ArgoCD UI is to expose the ArgoCD service using Ingrss but this requires a certificate. This is not covered in this project. See the ArgoCD [documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/) more information.


kubectl port-forward svc/argocd-server -n argocd 8082:80
Ref: https://argo-cd.readthedocs.io/en/stable/getting_started/


https://localhost:8080


## Possible Issues
https://karpenter.sh/preview/troubleshooting/#webhooks
