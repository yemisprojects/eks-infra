# DevSecOps CI/CD with EKS and ArgoCD

This repository contains the terraform code and github workflows used to automate the deployment of the infrastructure required to implement an end-to-end DevSecOps CI/CD pipeline to EKS. CI is implemented using Jenkins and CD via ArgoCD (GitOps). This repo is intended to be used with the two repositories listed below.
- ..
- ..

## Architecture

<img width="2159" alt="GitHub Actions CICD for Terraform" src="">


# Required Accounts

- Github account
- AWS account (Note: This project does not fall under the free tier)

# GitHub Actions Workflow

1. Fork this repo, create a new branch and check in the Terraform code.
2. Create a Pull Request (PR) in GitHub once you're ready to merge your code.
3. A GitHub Actions workflow will trigger to ensure your code is well formatted and produces secure validated. In addition, a Terraform plan will run to generate a preview of the changes that will happen in your AWS account and displayed as a comment on the PR.
4. Once appropriately reviewed, the PR can be merged into your main branch.
5. After merge, another GitHub Actions job will trigger from the main branch and execute the changes using Terraform.

## Resources Deployed

Below is a list of key resources deployed via the Github Actions. For a complete list of all resources, see this..... terraform docs in this repo.

1. Provisioned Jenkins Server running on EC2
2. EKS Cluster with 1 managed Node group
3. Karpenter cluster auto-scaler
4. ArgoCD
5. Prometheus and Grafana

## Getting Started

To use the workflows from this repository in your environment several prerequisite steps are required. Most of these have been automated via terraform which you will need to run locally.

1. **Terraform State Location and DynamoDB for remote backend and state locking**

    Terraform utilizes a [state file](https://www.terraform.io/language/state) to store information about the current state of your managed infrastructure and associated configuration. This file will need to be persisted between different runs of the workflow. The recommended approach is to store this file within S3 or other similar remote backend. To lock a write to the state file when in use a DynamoDB table is required.

2. **IAM role utilized by Github to authenticate to AWS**: 

    An IAM identity will be required the pipeline to authenticate to AWS and carry out account. At a minimum, it requires permission to the S3 bucket, dynamoDB table (for remote backend) and to deploy the desired resources. See this [AWS blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/) for more information. 

3. **Add GitHub Secrets**

    _Note: While the IAM role does not contain any secrets or credentials we still utilize GitHub Secrets as a convenient means to parameterize the identity information._

    Create the following secrets on the repository:

    - `AWS_ROLE` : Federated IAM role to be utilized by Github actions
    - `CICD_TFSTATE_BUCKET` : Bucket name for remote backed for jenkins remote backend
    - `CICD_TFSTATE_DB` : DynamoDB table for state locking for Jenkins S3 backend
    - `EKS_TFSTATE_BUCKET` : Bucket name for remote backed for jenkins remote backend
    - `EKS_TFSTATE_DB` : DynamoDB table for state locking for Jenkins S3 backend
    
    Instructions to add the secrets to the repository can be found [here](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository).


## Access grafanna

Prometheus default login
Username: admin
Password: prom-operator

Import Dashboard ID: 1860

## Access ArgoCD server 
Run this command to access ArgoCd server. 
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl port-forward svc/vproapp-service 8083:80
Goto your browser on 

ArgoCd can be exposed as a service but this requires a certificate manager. This is not covered in this project. See the documentation more information


kubectl port-forward svc/argocd-server -n argocd 8082:80
Ref: https://argo-cd.readthedocs.io/en/stable/getting_started/


https://localhost:8080


## Possible Issues
https://karpenter.sh/preview/troubleshooting/#webhooks
