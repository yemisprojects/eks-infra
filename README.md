<h1 align="center">DevSecOps CI/CD with Jenkins and ArgoCD</h1>

This repository contains the terraform code and github workflow used to automate the deployment of the infrastructure required to implement an end-to-end DevSecOps CI/CD pipeline to EKS. CI is implemented using Jenkins and CD using Argo CD. This repository is intended to be used with the two repositories below in order.
- [eks-app](https://github.com/yemisprojects/eks-app) repo: It contains the application source code to be containerized
- [kubernetes-manifests](https://github.com/yemisprojects/kubernetes-manifests) repo: It contains helm charts for deployment by Argo CD

<h2 align="center">Architecture</h1>

<img alt="GitHub Actions CICD for Terraform" src="https://github.com/yemisprojects/eks-infra/blob/main/images/architecture/architecture%20used.png">

The architecture above represents the complete solution architecture for the EKS DevSecOps project. The rest of this documentation delves into the details of the Infrastructure pipeline portion of the solution above.

<h2 align="center">Infrastructure pipeline tools</h1>

The following tools below have been used to automate the infrastructure deployment for this project. The pipeline workflow is described further [down below](https://github.com/yemisprojects/eks-infra#github-workflow) on this page

- [Github Actions](https://docs.github.com/en/actions) integrates seamlessly with Github and there is a wide variety of reusable actions from the [github marketplace](https://github.com/marketplace) to adopt. Pipeline workflows are written in YAML and with Github-Hosted runners its easy to get started with minimal operational overhead. 
- [Terrafom](https://www.terraform.io) is open source, cloud agnostic with a large community contributing to it. It also provides the flexibility to work with many providers (cloud and non-cloud) and a wide variety of modules you can reuse. This makes it a versatile IaC tool. 
- [Checkov](https://www.checkov.io) is a static code analysis tool for infrastructure as code (IaC) and also a software composition analysis (SCA) tool for images and open source packages. It detects security and compliance misconfigurations. 

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
terraform apply -auto-approve
```

Using the command above, terraform creates the following resources: 

1. **S3 buckets to store terraform's state & DynamoDB tables to lock the state**

    Terraform utilizes a [state file](https://www.terraform.io/language/state) to store information about the current state of your managed infrastructure and associated configuration. This file will need to be persisted between different runs of the workflow. The recommended approach is to store this file within S3 or other similar remote backend. To lock writes to the state file when in use a DynamoDB table is required when using S3 backend.

2. **IAM role utilized by Github to authenticate to AWS**: 

    Using [OpenID Connect (OIDC)](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) an IAM Role will be used by the pipeline to authenticate and carry out actions in your AWS account. At a minimum, the role requires permission to the S3 buckets, dynamoDB tables and to deploy the desired resources. Using an IAM role versus AWS access keys saves you the burden of rotating long-term credentials. See this [AWS blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/) for more information. Note that, admin permissions have been used for simplicity in this project. In a real time scenario, you should adhere to the principle of least privilege.

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
2. **_Required_**: Update value of the `grafana_domain_name` variable in `eks/dev/variables.tf` to your desired domain name as this will be used to access Grafana dashboard at a later step.
3. You can push your change directly to the main branch. However, to see the terraform plan posted by github-actions bot from a PR (pull request) perspective i suggest you create a new branch and check in the Terraform code with your change. See sample [here](https://github.com/yemisprojects/eks-infra/blob/main/images/archiecture_github_actions/PR%20comment%20Github%20action.png). Also one would typically not merge changes directly to the main branch
4. Create a Pull Request (PR) in GitHub once you're ready to merge your code.
5. A GitHub Actions workflow will trigger to ensure your code is well formatted and validated. A Terraform plan will also run to generate a preview of the changes that will happen in your AWS account and displayed as a comment on the PR.
    - Concurrently Checkov will scan your Terraform configurations misconfigurations with potential security implications. The results of the latter can be found in the `Security` tab -> `Code Scanning` section of your repository. Note, enforcement has been disabled in the workflow to allow all checks to pass. Sample code scan results are shown in the screenshot below.
6. Once the PR is appropriately reviewed, the PR can be merged into your main branch.
7. After merge, another job will trigger from the main branch and deploy the infrastructure using Terraform. Generally, creating the cluster can take up to 10mins.

<img alt="Checkov code scan" src="https://github.com/yemisprojects/eks-infra/blob/main/images/archiecture_github_actions/checkov%20scan.png">
                                            <h5 align="center">Checkov scan result</h5>

<h4>Resources deployed</h4>

Below is a list of key resources deployed via the pipeline by default in us-east-1. For a complete list of all resources, see the [terraform docs](https://github.com/yemisprojects/eks-infra/tree/main/eks_infra/dev#readme) for the code within this repo.

1. Jenkins running on EC2 accessible via SSM
2. EKS Cluster with 1 managed node group
3. Admin user named (eksadmin1) to manage the cluster
4. Karpenter cluster auto-scaler
5. Argo CD
6. Prometheus and Grafana
7. AWS Application Load balancer Controller

## Verify EKS access
Confirm the cluster is created successfully and you can access it with these commands. Go to the AWS console, and generate access keys for the newly created `eksadmin1` IAM user. Run the commands below to configure your AWS CLI profile and authenticate to the EKS cluster
```sh
aws configure --profile eksadmin1
aws eks update-kubeconfig --region us-east-1 --name eks-poc --profile eksadmin1
kubectl get nodes
```

## Verify Jenkins access
Jenkins should be setup to be scalable and highly available but a single instance is used here for simplicity. Review the [documentation](https://www.jenkins.io/doc/book/scaling/architecting-for-scale/) for more information if needed. Goto the `http://x.x.x.x:8080` where _x.x.x.x_ is Jenkins EC2 public IP. Configuring Jenkins is detailed extensively in the [eks-app](https://github.com/yemisprojects/eks-app) repo.

## How to access Grafanna
- An AWS load balancer controller was installed and a load balancer was created to expose the grafana service using the domain name you provided earlier. The name of the new load balancer is `prometheus-ingress`
<img alt="Grafana Load balancer" src="https://github.com/yemisprojects/eks-app/blob/main/images/Loadbalancers-app-grafana.png">

- Get the load balancer name and create a CNAME record in your domain. The screenshot below shows an example when using route53. Instructions for AWS Route53 can be found [here](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-creating.html).
<img alt="Route53 record" src="https://github.com/yemisprojects/eks-app/blob/main/images/R53_record.png">

- Go to your browser, type in your chosen domain name and login with the default credentials below. to access the Grafana console. 
```
Username: admin
Password: prom-operator
```
- You can [import](https://grafana.com/docs/grafana/latest/dashboards/manage-dashboards/#import-a-dashboard) a Kubernetes Cluster Dashboard using this ID: `1860`

## How to access Argo CD UI 
You can use port forwarding to [access Argo CD UI](https://argo-cd.readthedocs.io/en/stable/getting_started/#3-access-the-argo-cd-api-server) for initial configuration
```sh
kubectl port-forward svc/argocd-server -n argocd 8083:443
```
The default username is `admin` and the default password can be obtained using the command below.
```sh
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Go to your web browser using the forwared port `https://localhost:8083` and login with the credential above

Note: The ideal method to access Argo CD UI is to expose the Argo CD service using Ingress but this requires a certificate. This is not covered in this project. See the ArgoCD [documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/) for more information.

## Verify Karpenter installation

Due to the number of cluster addons installed such as grafana, Argo CD it is expected the cluster will scale up to more than two nodes. Run the command below to verify successfull installation and that there are no errors in the karpenter logs. 
```sh
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter -c controller
```

## Destroy Infrastructure

Destroy the infrastructure after you have completed all the steps to implement the application pipeline in the [eks-app](https://github.com/yemisprojects/eks-app) repo. To destroy the infrastructure via the Github actions pipeline. Follow these steps

- Go to the _Actions_ tab within this repo
- To destroy the EKS Cluster, Click `Terraform Destroy EKS` workflow -> `Run workflow` on the main branch
- To destroy the Jenkins pipeline, Click `Terraform Destroy Jenkins Pipeline` workflow -> `Run workflow` on the main branch
- A screenshot is shown below for reference
<img alt="Destroy EKS cluster" src="https://github.com/yemisprojects/eks-infra/blob/main/images/Destroy%20eks%20cluster.png">

#### Delete S3 backend and DynamoDb

The IAM role used by the pipeline, S3 backend and DynamoDb resources will also need to destroyed as well. Run the command below and you are done

```sh
cd github_setup && terraform destroy -auto-approve
```

## Possible issues
1. The most re-occuring issue i faced running the project locally or via Github actions was with creating Karpenter's provisioner resource. Errors encountered include _`Internal error occurred: failed calling webhook "validation.webhook.provisioners.karpenter.sh"`_ OR _`Failed calling webhook “defaulting.webhook.karpenter.sh”`_.  A sample error from the Github Actions logs is shown below.

<img alt="Karpenter error" src="https://github.com/yemisprojects/eks-infra/blob/main/images/Karpenter%20error.png">
    
+ These errors are [officially documented](https://karpenter.sh/preview/troubleshooting/#webhooks) as _a bug in Argo CD’s upgrade workflow where webhooks are leaked_. The solution is to simply delete the webhooks and rerun terraform apply or rerun the workflow. The issue will most likely not be encountered in karpenter v0.32.x (v1beta1) as this solution used v1alpha5 api version for the karpenter provisioner. You can reattempt this project with the newest release.

Note that you will need to generate access keys for the `eksadmin1` user, create a new AWS profile locally and run the commands above with the new profile

```sh
kubectl delete mutatingwebhookconfigurations defaulting.webhook.provisioners.karpenter.sh
kubectl delete validatingwebhookconfiguration validation.webhook.provisioners.karpenter.sh
kubectl delete mutatingwebhookconfigurations defaulting.webhook.karpenter.sh
```

2. If you run into issues while trying to destroy the EKS cluster via the pipeline, go to the AWS console and attempt to destroy the EKS VPC manually. It is most likely that there are resource dependencies preventing the destruction via terraform. 

    Try to delete a few resources listed and retry the pipeline _Terraform Destroy EKS_ workflow to delete the entire infrastructure. Some resources are spun up outside of Terraform such as the Ingress load balancers or it's attached security groups and could lead to dependencies violations when destroying the resources. See the sample error screenshot below.

<img alt="Karpenter error" src="https://github.com/yemisprojects/eks-infra/blob/main/images/Destroy%20terraform%20error.png">
