# DevOps Final Project _________________________________________________________________________________________________

## End-to-end DevOps bootcamp project using Azure, Terraform, Ansible,Kubernetes, GitHub Actions, Flask, and PostgreSQL.


##  Project Status 

Completed:
- Prepared an Ubuntu 26.04 LTS environment using WSL 2 on Windows.
- Connected VS Code to the WSL environment.
- Verified Git, SSH, Python, Terraform, and Azure CLI.
- Authenticated to Azure and verified an enabled default subscription.
- Initialized the local Git repository on the main branch.
- Added .gitignore rules and an initial Terraform variables template.

Azure infrastructure has not been provisioned yet.




##  Planned Architecture 


- k8slab-cp1: Rocky Linux 9, Kubernetes control plane and Ansible controller.
- k8slab-w1: Rocky Linux 9, Kubernetes worker.
- Flask Task Tracker application with a PostgreSQL database.
- GitHub Actions for checks, tests, and container image publication to GHCR.




##  Repository Structure 

| Path | Purpose |
|------|---------|
| terraform/ | Azure infrastructure definitions |
| ansible/ | Inventory, variables, and automation playbooks |
| app/ | Application code, tests, and container configuration |
| k8s/ | Kubernetes manifests |
| docs/screenshots/ | Verification screenshots |




##  Workstation Setup 


Commands run inside Ubuntu through WSL 2:

    git --version
    ssh -V
    python3 --version
    terraform version
    az version


Azure login:

    az login --use-device-code

Subscription verification:

    az account show --query "{Name:name, State:state, Default:isDefault}" --output table

The selected subscription was enabled and set as the default.







# Task 1 ___________________________________________________________________________________________

### 1. Which files did you exclude with .gitignore , and what sensitive data would they leak if committed?

- Terraform state and saved plans: may contain sensitive resource
  attributes, configuration values, or credentials.
- Real Terraform variable files and .env files: may contain secrets
  and environment-specific settings.
- SSH private keys: could allow someone to impersonate the key owner.
- Kubernetes kubeconfig and admin.conf: may contain credentials
  granting access to the cluster.
- Crash logs: may contain sensitive diagnostic information.
- Terraform working directories, Python environments, caches, and
  coverage reports: generated local files that should not be committed.

Safe example templates are allowed and must contain no real secrets.


### 2. If a secret is committed and deleted in a later commit, is it safe? Why or why not?

No it is not safe. Earlier commits may still contain the secret, and other people may already
have copied it. An appropriate solution is to revoke the exposed secret first, then remove
it from repository history. A .gitignore rule does not erase existing Git history.






# Task 2 ___________________________________________________________________________________________

### Engineering Post-Mortem 1: Terraform Download Failure

### Error
Terraform downloads and requests to HashiCorp's release and APT endpoints returned HTTP 404.

### Cause
The response included " x-amzn-waf-reason: geo ", and the browser reported that the content was unavailable in the current region.

### Fix
Installed Terraform through the Snap Store using the community-maintained Snapcrafters package:

    sudo snap install terraform --classic

This package is not officially maintained by HashiCorp. Classic confinement permits broader access than a strictly confined Snap.

### Verification

    terraform version

Result: Terraform v1.16.4 on linux_amd64.

This resolved the CLI installation. Access to Terraform provider downloads has not yet been verified.




###  How does Terraform authenticate to Azure in this setup, and why is this method safer than hardcoding credentials inside .tf files?

For this local workflow, Terraform's AzureRM provider will use the Azure CLI session established with:

    az login --use-device-code

Azure CLI manages authentication tokens locally. The provider uses this authentication to request access to Azure, subject to the signed-in account's permissions.

The subscription ID identifies the target subscription. Note: it is not a password and does not grant access by itself.

This avoids embedding passwords, client secrets, or access tokens in Terraform code, where they could be exposed through a public repository and its Git history.

The local Azure CLI credential cache must also remain private.