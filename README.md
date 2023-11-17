# DevSecOps CI/CD with Jenkins and ArgoCD

This repository contains the terraform code and github workflows used to automate the deployment of the infrastructure required to implement an end-to-end DevSecOps CI/CD pipeline to EKS. CI is implemented using Jenkins and CD via ArgoCD (GitOps). This repo is intended to be used with the two repositories listed below.
- https://github.com/yemisprojects/eks-app
- https://github.com/yemisprojects/kubernetes-manifests

## Infrastructure pipeline Architecture

<img width="2159" alt="GitHub Actions CICD for Terraform" src="">

# Prerequisites

- Github account
- AWS account (Note: This project does not fall under the free tier)
- Domain (AWS R53 or third party)
- kubectl Installed locally

# GitHub workflow

1. Fork this repo, create a new branch and check in the Terraform code.
2. Create a Pull Request (PR) in GitHub once you're ready to merge your code.
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

## Github Initial setup (required)

To use the workflows from this repository in your environment several prerequisite steps are required. Most of these have been automated via terraform which you will need to run locally. Run the commands below and note down the values of the output for the next step

```t
cd github_setup && terraform init
terraform fmt && terraform apply -auto-approve

```

The commands above creates the following resources: 

1. **S3 buckets to store terraform's state & DynamoDB tables to lock the state**

    Terraform utilizes a [state file](https://www.terraform.io/language/state) to store information about the current state of your managed infrastructure and associated configuration. This file will need to be persisted between different runs of the workflow. The recommended approach is to store this file within S3 or other similar remote backend. To lock a write to the state file when in use a DynamoDB table is required.

2. **IAM role utilized by Github to authenticate to AWS**: 

    An IAM identity will be required the pipeline to authenticate to AWS and carry out account. At a minimum, it requires permission to the S3 bucket, dynamoDB table (for remote backend) and to deploy the desired resources. See this [AWS blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/) for more information. 

#### Add GitHub Secrets

    Within your github repository, create the following secrets on the repository. Use the terraform output values from the previous terr.

    - `AWS_ROLE` : Federated IAM role to be utilized by Github actions
    - `CICD_TFSTATE_BUCKET` : Bucket name for remote backed for jenkins remote backend
    - `CICD_TFSTATE_DB` : DynamoDB table for state locking for Jenkins S3 backend
    - `EKS_TFSTATE_BUCKET` : Bucket name for remote backed for jenkins remote backend
    - `EKS_TFSTATE_DB` : DynamoDB table for state locking for Jenkins S3 backend
    
    Instructions to add the secrets to the repository can be found [here](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository).


**REQUIRED**: 
Update value of the grafana_domain_name variable in `eks/dev/variables.t`' to your domain name
Raise a PR and merge to main

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
