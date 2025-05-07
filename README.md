# Multi-Cluster GitOps on Kind/Docker with ArgoCD and Crossplane

This project demonstrates how to implement a extensible GitOps solution for managing **multiple Amazon EKS clusters** and their cloud resources using **ArgoCD** and **Crossplane**. Project inspired by the AWS blog series:

- [Part 1](https://aws.amazon.com/blogs/containers/part-1-build-multi-cluster-gitops-using-amazon-eks-flux-cd-and-crossplane/)
- [Part 2](https://aws.amazon.com/blogs/containers/part-2-multi-cluster-gitops-cluster-fleet-provisioning-and-bootstrapping/)
- [Part 3](https://aws.amazon.com/blogs/containers/part-3-multi-cluster-gitops-application-onboarding/)

## Overview

The solution follows a **hub-and-spoke architecture**:
- The **management cluster** (hub) provisions, bootstraps, and manages a fleet of workload clusters (spokes) and their resources.
- **ArgoCD** handles GitOps-driven continuous delivery to Kubernetes clusters.
- **Crossplane** provisions and manages AWS cloud infrastructure using Kubernetes manifests and CRDs.
- A mix of dedicated repositories and GitOps controllers gives both platform and application teams maximum self-service with governance.

## Key Features

- **Declarative, GitOps-based lifecycle management** for both clusters and cloud resources.
- **Separation of concerns**:
  - Platform team provisions and manages clusters/infrastructure.
  - Application teams onboard and manage workloads.
  - Governance team defines which apps go to which clusters.
- **De-centralized deployment**: Each cluster runs its own ArgoCD and Crossplane for scalability and resiliency.
- **Secure secrets management** using Sops and External Secrets Operator, integrated with AWS Secrets Manager.
- **Multi-repository Git structure** to serve platform, application, and governance teams.

## Architecture

- **Management Cluster**  
  Provisions workload clusters, installs essential controllers (ArgoCD, Crossplane, Sealed Secrets), manages IAM, and stores setup artifacts.
- **Workload Clusters**  
  Run applications and their supporting AWS resources, bootstrapped by the management cluster.
- **ArgoCD**  
  Monitors Git repos and applies Kubernetes manifests to clusters (continuous delivery).
- **Crossplane**  
  Provides Kubernetes-native APIs for cloud resource provisioning and lifecycle management.
- **Sops & External Secrets**  
  Enable encrypted secrets in Git and dynamic retrieval from AWS Secrets Manager.


## GitOps Repository Structure

| Repository        | Owner            | Purpose                                                               |
|-------------------|------------------|-----------------------------------------------------------------------|
| `k8s-system-local`| Platform team    | Cluster lifecycle, global tooling, bootstrap manifests                |
| `k8s-workloads`   | Governance team  | Maps app repos to target clusters, manages onboarding policies        |
| `app-manifests`   | App teams        | Workload manifests, application deployment definitions                |  

## Basic Workflow

1. **Setup:**
   - Create management cluster with Kind and Docker Desktop on the local machine.
   - Bootstrap management cluster with ArgoCD and Crossplane.
   - Preconfigure Sops secrets using AWS Secrets Manager and External Secrets Operator.

2. **Provision Clusters:**
   - Define new workload clusters in `k8s-system-local` repo.
   - Crossplane provisions EKS clusters as specified in Git.
   - Management cluster ArgoCD bootstraps each workload cluster (installs its own ArgoCD, Crossplane, etc.).

3. **Deploy Applications:**
   - App teams commit/PR app manifests to their repo.
   - Governance team maps apps to clusters in `k8s-workloads` repo.
   - ArgoCD in each workload cluster continuously syncs and applies assigned workloads.

4. **Manage AWS Resources:**
   - Define AWS cloud resources as Crossplane custom resources, version-controlled in Git.
   - Crossplane provisions and manages these resources alongside workloads.

5. **Secrets Management:**
   - Store secrets encrypted by Sops in Git repos.
   - Sops and External Secrets Operator handle transparent decryption and syncing with AWS Secrets Manager.

## Getting Started

1. Configure and run Docker machine

Runtime machine resources used in this project:
- CPU: 8
- Memory: 12GB
- Disk size: 100GB

2. Clone this repository and go to the root folder.

3. Run DevBox shell

```bash
devbox shell
```

It may take some time till devbox ends up installation of all tools and dependencies (~5min).

4. SSO Authentication to the AWS Account with the corresponding aws profile.

5. Make sure that `.sops.yaml` file with creation rules are in `$HOME`.

```bash
creation_rules:
  - kms: arn:aws:kms:us-west-2:<aws_account_id>:key/<key_id>
    encrypted_regex: "^(data|stringData)$"
    aws_region: <aws_region>
    aws_profile: <sso_aws_profile>
```

6. Run task command

```bash
task c
```

7. Use port-forward to open ArgoCD UI

```bash
kubectl -n argocd port-forward svc/argocd-server 8443:443 > /dev/null 2>&1 &
```

Fetch the admin password from the cluster Secret

```bash
kubectl -n argocd get secret argocd-cluster -o jsonpath='{.data.admin\.password}' | base64 -d
```

To change the admin password you will need to modify the cluster secret

```bash
kubectl -n argocd patch secret example-argocd-cluster \
  -p '{"stringData": {
    "admin.password": "newpassword"
  }}'
```

## Troubleshooting

TBC