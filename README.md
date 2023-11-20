<h1 align="center">DevSecOps CI/CD with Jenkins and ArgoCD</h1>

This repository contains the terraform code and github workflow used to automate the deployment of the infrastructure required to implement an end-to-end DevSecOps CI/CD pipeline to EKS. CI is implemented using Jenkins and CD using ArgoCD. This repository is intended to be used with the two repositories below in order.
- [eks-app](https://github.com/yemisprojects/eks-app) repo: It contains the application source code to be containerized
- [kubernetes-manifests](https://github.com/yemisprojects/kubernetes-manifests) repo: It contains helm charts for deployment by ArgoCD

<h2 align="center">Architecture</h1>

<img alt="GitHub Actions CICD for Terraform" src="https://github.com/yemisprojects/eks-infra/blob/main/images/architecture/architecture%20used.png">

Github Actions integrates seamlessly with Github and there is a wide variety of reusable actions from the [github marketplace](https://github.com/marketplace) to adopt. Pipeline workflows are written in YAML and with Github-Hosted runners its easy to get started with minimal operational overhead. Terrafom is open source, cloud agnostic with a large community contributing to it. It also provides the flexibility to work with many providers (cloud and non-cloud) and a wide variety of modules you can reuse. This makes it a versatile IaC tool. Checkov is a static code analysis tool for infrastructure as code (IaC) and also a software composition analysis (SCA) tool for images and open source packages. It detects security and compliance misconfigurations. Each of these tools have been used to automate infrastructure deployment for this project

# Prerequisites

- Github account
- AWS account (Note: This project does not fall under the free tier)
- Domain (AWS R53 or third party)
- kubectl installed locally
- Terraform installed locally

## Github initial setup (required)

In addition to the above requirements, there are other prerequisite steps to deploy the resources and use the workflows from this repository in your AWS account. Most of these have been automated via terraform. 

As a first step, fork this repository and run the commands below. Note down the values of the terraform output for the next step

```sh
cd github_setup && terraform init
terraform fmt && terraform apply -auto-approve
```

Using the command above, terraform creates the following resources: 

1. **S3 buckets to store terraform's state & DynamoDB tables to lock the state**

    Terraform utilizes a [state file](https://www.terraform.io/language/state) to store information about the current state of your managed infrastructure and associated configuration. This file will need to be persisted between different runs of the workflow. The recommended approach is to store this file within S3 or other similar remote backend. To lock writes to the state file when in use a DynamoDB table is required when using S3 backend.

2. **IAM role utilized by Github to authenticate to AWS**: 

    Using [OpenID Connect (OIDC)](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) an IAM Role will be used by the pipeline to authenticate and carry out actions in your AWS account. At a minimum, the role requires permission to the S3 buckets, dynamoDB tables and to deploy the desired resources. See this [AWS blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/) for more information. Note that, admin permissions have been used for simplicity in this project. In a real time scenario, you should adhere to the principle of least privilege

#### GitHub Secrets

The next step is to create the following github secrets in your repository. Use the terraform output values from the previous step.

- `AWS_ROLE` : Federated IAM role to be utilized by Github actions
- `CICD_TFSTATE_BUCKET` : Bucket name for remote backed for Jenkins instance
- `CICD_TFSTATE_DB` : DynamoDB table for state locking for Jenkins instance
- `EKS_TFSTATE_BUCKET` : Bucket name for remote backed for EKS cluster
- `EKS_TFSTATE_DB` : DynamoDB table for state locking for EKS cluster

Instructions to add the secrets to the repository can be found [here](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository).

## How to deploy resources via Github Actions

<img alt="GitHub Actions CICD for Terraform" src="https://github.com/yemisprojects/eks-infra/blob/main/images/archiecture_github_actions/github_workflow.png">
                                            <h4 align="center">Github Workflow</h4>

1. Fork this repo and use the steps in the previous sections to update your github secrets
2. **_Required_**: Update value of the `grafana_domain_name` variable in `eks/dev/variables.tf` to your domain name
3. You can push your change directly to the main branch. However, to see the comments on the PR by github-actions bot and terraform plan from a PR (pull request) perspective i suggest you create a new branch and check in the Terraform code with your change. See sample [here](https://github.com/yemisprojects/eks-infra/blob/main/images/archiecture_github_actions/PR%20comment%20Github%20action.png). Also one would typically not merge changes directly to the main branch
4. Create a Pull Request (PR) in GitHub once you're ready to merge your code.
3. A GitHub Actions workflow will trigger to ensure your code is well formatted and validated. A Terraform plan will also run to generate a preview of the changes that will happen in your AWS account and displayed as a comment on the PR. Concurrently Checkov will scan your Terraform configurations for security misconfigurations. The results of the latter can be found in the `Security` tab -> `Code Scanning` section of your repository. Note, enforcement has been disabled in the workflow to allow all checks to pass.
4. Once the PR is appropriately reviewed, the PR can be merged into your main branch.
5. After merge, another job will trigger from the main branch and deploy the infrastructure using Terraform. Generally, creating the cluster can take up to 10mins.

<img alt="Checkov code scan" src="https://github.com/yemisprojects/eks-infra/blob/main/images/archiecture_github_actions/checkov%20scan.png">
                                            <h4 align="center">Checkov scan</h4>

<h4 align="center">Resources deployed</h4>

Below is a list of key resources deployed via Github Actions. For a complete list of all resources, see the [doc for terraform](https://github.com/yemisprojects/eks-infra/tree/main/eks_infra/dev#readme) within this repo.

1. Jenkins running on EC2 accessible via SSM
2. EKS Cluster with 1 managed node group
3. Admin user named (eksadmin1) to manage the cluster
4. Karpenter cluster auto-scaler
5. ArgoCD
6. Prometheus and Grafana
7. AWS Application Load balancer Controller

## Verify EKS access
Confirm the cluster is created successfully and you can access it with these commands. Replace `eksadmin1` with the AWS CLI profile created for the `eksadmin1` user
```sh
aws eks update-kubeconfig --region us-west-2 --name eks-poc --profile <eksadmin1>
kubectl get nodes
```

## Verify Jenkins access
Jenkins should be setup to be scalable and highly available but a single instance is used here for simplicity. Review the [documentation](https://www.jenkins.io/doc/book/scaling/architecting-for-scale/) for more information if needed. Goto the `http://x.x.x.x:8080` where _x.x.x.x_ is it EC2 public IP. Configuring Jenkins is detailed extensively in the [eks-app](https://github.com/yemisprojects/eks-app) repo.

## How to access Grafanna
An AWS load balancer controller was installed and used to expose the grafana service using the domain name you provided earlier. Go to your browser, provide the domain name and login with the default credentials below. Also ensure a CNAME record has been added in your domain to complete access. Instructions for AWS Route53 is found [here](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-creating.html).

```
Username: admin
Password: prom-operator
```

You can [import](https://grafana.com/docs/grafana/latest/dashboards/manage-dashboards/#import-a-dashboard) a Kubernetes Cluster Dashboard using this ID: `1860`

## How to access ArgoCD UI 
You can use port forwarding to [access ArgoCD UI](https://argo-cd.readthedocs.io/en/stable/getting_started/#3-access-the-argo-cd-api-server) for initial configuration
```sh
kubectl port-forward svc/argocd-server -n argocd 8083:443
```
The default username is `admin` and the default password can be obtained using the command below.
```sh
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Go to your web browser using the forwared port `https://localhost:8083` and login with the credential above

Note: The ideal method to access ArgoCD UI is to expose the ArgoCD service using Ingress but this requires a certificate. This is not covered in this project. See the ArgoCD [documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/) for more information.

## Verify Karpenter installation

Due to the number of cluster addons installed such as grafana, argoCD it is expected the cluster will scale up to more than two nodes. Run the command below to verify successfull installation and that there are no errors in the karpenter logs. 
```sh
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter -c controller
```

## Possible issues
The most re-occuring issue i faced running the project locally or via Github actions was with creating Karpenter's provisioner resource. Errors encountered include _`Internal error occurred: failed calling webhook "validation.webhook.provisioners.karpenter.sh"`_ OR _`Failed calling webhook “defaulting.webhook.karpenter.sh”`_.  A sample error from the Github Actions logs is shown below.

<img width="2159" alt="Karpenter error" src="https://github.com/yemisprojects/eks-infra/blob/main/images/Karpenter%20error.png">

These errors are [officially documented](https://karpenter.sh/preview/troubleshooting/#webhooks) as _"a bug in ArgoCD’s upgrade workflow where webhooks are leaked"_. The solution is to simply delete the webhooks and rerun terraform apply or rerun the workflow

```sh
kubectl delete mutatingwebhookconfigurations defaulting.webhook.provisioners.karpenter.sh
kubectl delete validatingwebhookconfiguration validation.webhook.provisioners.karpenter.sh
kubectl delete mutatingwebhookconfigurations defaulting.webhook.karpenter.sh
```

Note that you will need to generate access keys for the `eksadmin1` user, create a new AWS profile locally and run the commands above with the new profile
