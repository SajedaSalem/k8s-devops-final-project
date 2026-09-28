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

### Verification Screenshot

![Workstation tools and active Azure subscription](docs/screenshots/task02-tool-versions-azure.png)


###  How does Terraform authenticate to Azure in this setup, and why is this method safer than hardcoding credentials inside .tf files?

For this local workflow, Terraform's AzureRM provider will use the Azure CLI session established with:

    az login --use-device-code

Azure CLI manages authentication tokens locally. The provider uses this authentication to request access to Azure, subject to the signed-in account's permissions.

The subscription ID identifies the target subscription. Note: it is not a password and does not grant access by itself.

This avoids embedding passwords, client secrets, or access tokens in Terraform code, where they could be exposed through a public repository and its Git history.

The local Azure CLI credential cache must also remain private.



# Task 3 ___________________________________________________________________________________________

### What happens if you run "terraform apply" before accepting marketplace terms?

Terraform may fail when trying to create the Rocky Linux virtual machines because Azure requires the Marketplace legal terms for that image to be accepted before deployment. The VM resource cannot be provisioned until those terms have been accepted for the subscription.

### Verification Screenshot

![Providers are registered](docs/screenshots/task03-registeredProvider.png)

![Image terms are accepted](docs/screenshots/task03-acceptedTerms.png)


# Task 4 ___________________________________________________________________________________________


### What is the difference between a public key and a private key, and where does each reside?

The public key can be distributed to remote systems and is used to verify authentication attempts. The private key must remain secret on the local machine because it proves the user's identity. In this project, the private key stays on the laptop, while only the public key is installed on the Azure VMs.


# Task 5 ___________________________________________________________________________________________

### Engineering Post-Mortem 2: HashiCorp Registry Unavailable

### Error
`terraform init` failed because Terraform could not retrieve the `hashicorp/azurerm` provider from `registry.terraform.io`.


### Cause
HashiCorp services were not available from my current region. The HashiCorp API also returned a message stating that the content was not available in the region.


### Fix
I used GitHub Actions to build the official hashicorp/azurerm provider from the HashiCorp source code. I then downloaded the compiled provider binary and configured a local Terraform filesystem mirror through ~/.terraformrc.

Terraform was then able to initialize successfully using:

  terraform init


### 1. Why does the NSG not need rules for Kubernetes traffic between cp1 and w1 inside the subnet?


Both Kubernetes nodes are connected to the same Azure virtual network and subnet. Azure allows communication within the virtual network through its default NSG rules, so additional inbound rules are not required for every internal Kubernetes port between cp1 and w1.

The custom NSG rules are mainly used to control traffic coming from outside the virtual network, such as SSH on port 22 and the Kubernetes API on port 6443.


### 2. Why must the private IPs be static for this cluster?

The Kubernetes nodes need stable addresses because the control plane and worker communicate using their private IPs. In this project:

- k8slab-cp1 uses 10.0.1.10
- k8slab-w1 uses 10.0.1.11

Using static private IPs prevents these addresses from changing after restarts or redeployments. This also keeps /etc/hosts, Ansible inventory values, and Kubernetes configuration consistent

### 3. What is stored in terraform.tfstate, and why must it never be pushed to Git?

terraform.tfstate stores Terraform's record of the real infrastructure. It contains information such as:

- Azure resource IDs
- IP addresses
- resource properties
- relationships between Terraform resources and Azure resources
- configuration values that may include sensitive information

The state file should not be committed to Git because it can expose infrastructure details and potentially sensitive values. It is therefore excluded through .gitignore.


# Task 6 ___________________________________________________________________________________________

### Verification Screenshot

![terraform apply completion summary](docs/screenshots/task06-terraformapply.png)

![successful SSH login to both VMs](docs/screenshots/task06.sshLogin.png)


# Task 7 ___________________________________________________________________________________________


A dedicated automation user named `sajida` was created on both Kubernetes nodes.

The user was added to the `wheel` group and configured with passwordless sudo using a dedicated sudoers drop-in file.

The following commands were used on both nodes:

```bash
sudo useradd -m -s /bin/bash sajida
sudo usermod -aG wheel sajida
echo 'sajida ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/sajida
sudo chmod 0440 /etc/sudoers.d/sajida
```

### Verification Screenshot

![sudo whoami returning root without password prompt on cp1 ](docs/screenshots/task07-rootN1.png)

![sudo whoami returning root without password prompt on cp1 ](docs/screenshots/task07-rootN2.png)


### 1. Why does the user need passwordless sudo on cp1 even though cp1 is the Ansible controller?

The Ansible controller is also one of the Kubernetes nodes and must be configured by Ansible just like the worker node.

Many configuration tasks require administrative privileges, for example:

- installing packages
- disabling swap
- configuring kernel modules
- installing Kubernetes components

Passwordless sudo allows Ansible to perform these privileged tasks automatically without stopping to ask for a password.


### 2. Why is a sudoers drop-in file safer than editing /etc/sudoers directly?

Using a dedicated file inside /etc/sudoers.d/ keeps the configuration for the automation user isolated from the main sudo configuration.

This is safer because:
- the main /etc/sudoers file remains unchanged
- the automation user's permissions can be managed separately
- the configuration can be removed easily if needed
- mistakes are less likely to affect the entire sudo configuration

The file permissions are restricted to 0440, as required.


# Task 8 ___________________________________________________________________________________________

A dedicated SSH key pair was generated on `cp1` under the automation user `sajida`.

The key was created with:

```bash
ssh-keygen -t ed25519
```

The public key from cp1 was then added to: /home/sajida/.ssh/authorized_keys on w1.

The required permissions were configured with:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Passwordless SSH access from cp1 to w1 was verified with:


```bash
ssh k8slab-w1 hostname
```

Expected output: k8slab-w1

The command completed without prompting for a password.

### Verification Screenshot

![ Key-Based SSH Access from cp1 to w1](docs/screenshots/task08-sshByHostname.png)


### 1. Why does ssh-copy-id fail on Azure VMs by default, and how was the key installed on w1?

Azure Linux VMs are commonly configured for SSH key authentication only, with password authentication disabled.

ssh-copy-id normally logs in to the remote machine first and then installs the public key. If password login is disabled and the new automation user does not yet have an authorized SSH key, ssh-copy-id cannot authenticate as that user.

In this project, the public key generated on cp1 was copied manually to the authorized_keys file of the sajida user on w1.
The connection to w1 was first made using the Azure administrator account and the original k8slab_key. The key was then installed under:

/home/sajida/.ssh/authorized_keys

with the correct ownership and permissions.

### 2. What happens if permissions on .ssh or authorized_keys are configured too loosely?

OpenSSH checks the permissions of SSH-related files and directories for security reasons.
If .ssh or authorized_keys is writable by other users, SSH may consider the configuration insecure and refuse to use the authorized key.

The recommended permissions are:

~/.ssh               → 700

~/.ssh/authorized_keys → 600

This ensures that only the owner can modify the SSH configuration and authorized keys.

# Task 9 ___________________________________________________________________________________________

Ansible Core was installed only on the control-plane node k8slab-cp1.
The worker node k8slab-w1 does not have Ansible installed.

### Installation

On k8slab-cp1, Ansible Core was installed with:

```bash
sudo dnf install -y epel-release
sudo dnf install -y ansible-core
```
The installation was verified with:

![ Key-Based SSH Access from cp1 to w1](docs/screenshots/task09-ansibleVersion.png)

The project repository was then cloned on cp1 under the automation user's home directory:

```bash
cd ~
git clone https://github.com/SajedaSalem/k8s-devops-final-project.git
```
 
 ### Why does w1 require no Ansible software installed?

Ansible is agentless. The Ansible software runs only on the controller node, which in this project is k8slab-cp1.
The controller connects remotely to k8slab-w1 using SSH and executes Ansible modules there.
Therefore, w1 does not need Ansible installed.

It only needs:
- SSH access
- Python
- the automation user sajida
- passwordless sudo permissions

This allows cp1 to manage w1 remotely.



# Task 10 __________________________________________________________________________________________

An Ansible inventory was created to define the Kubernetes control-plane and worker nodes.
The inventory contains:

```ini
[k8s_master]
k8slab-cp1 ansible_connection=local

[k8s_workers]
k8slab-w1 ansible_host=10.0.1.11

[k8s_cluster:children]
k8s_master
k8s_workers
```
A group variables file was created at: ansible/group_vars/all.yml
with:

```
cp1_ip: "10.0.1.10"
w1_ip: "10.0.1.11"
cluster_user: "sajida"
pod_network_cidr: "192.168.0.0/16"

ansible_user: "{{ cluster_user }}"
ansible_become: true
```
Connectivity to both nodes was verified with:
![ Key-Based SSH Access from cp1 to w1](docs/screenshots/task10-ping.png)


### Why is cp1 managed with ansible_connection=local instead of connecting over SSH to itself?

cp1 is the Ansible controller and is also part of the Kubernetes cluster.

Using: ansible_connection=local
allows Ansible to manage the control-plane node directly from the local machine instead of opening an unnecessary SSH connection back to itself.
This makes the configuration simpler and avoids relying on SSH for local execution.


# Task 11 __________________________________________________________________________________________

Created the Ansible playbook: `ansible/prepare-nodes.yml`

The playbook performs the following tasks on both Kubernetes nodes:

- Updates the DNF package cache
- Upgrades installed packages
- Installs administration tools:
  - nano
  - vim
  - git
  - curl
  - wget
  - bash-completion
  - tar
  - tmux
- Installs networking and troubleshooting tools:
  - iproute
  - net-tools
  - bind-utils
  - traceroute
  - tcpdump
  - lsof
  - sysstat
- Installs Python 3 and pip
- Installs and enables chrony
- Enables and starts SSH
- Displays system information using Ansible facts
- Checks whether a reboot is required using `needs-restarting -r`
- Reboots only worker nodes when necessary
- Never automatically reboots the control-plane node


The playbook was executed with:

```bash
ansible-playbook -i inventory.ini prepare-nodes.yml
```

### Verification

![ Prepare Nodes ](docs/screenshots/task11-playRecap.png)

The worker node required a reboot after package updates and was automatically rebooted by Ansible. The control-plane node was intentionally not rebooted.


### What does idempotency mean in Ansible and Infrastructure as Code?

Idempotency means that repeatedly applying the same automation should bring the system to the same desired state without unnecessarily repeating changes.
For example, if a package is already installed or a service is already running, Ansible reports the task as ok instead of changing the system again.
This can be seen in the playbook output. The control-plane node had already been prepared, therefore most tasks returned:

ok

while the newly recreated worker required configuration changes and returned:

changed

This allows Infrastructure as Code to be safely executed multiple times while keeping systems consistent.


# Task 12 __________________________________________________________________________________________

### Why can control-plane.yml and workers.yml not be swapped?

The control plane must be initialized before any worker can join the cluster.
control-plane.yml runs kubeadm init, which creates the Kubernetes control plane and generates the worker join command containing the API server address, token, and discovery information.

workers.yml depends on that generated join command.

Therefore, if workers.yml ran first, the worker would have no initialized Kubernetes API server to connect to and no valid join command to use.

# Task 13 __________________________________________________________________________________________

For Kubernetes to run correctly, both nodes were prepared with the required Linux kernel, networking, security, and container runtime settings.

### Kubernetes Prerequisites

The playbook `ansible/prerequisites.yml` performs the following configuration on all Kubernetes nodes:

- Disables swap immediately with `swapoff -a`
- Disables swap permanently in `/etc/fstab`
- Sets SELinux to `permissive`
- Loads the required kernel modules:
  - `overlay`
  - `br_netfilter`
- Ensures the kernel modules are loaded after reboot
- Configures the required sysctl parameters:
  - `net.bridge.bridge-nf-call-iptables = 1`
  - `net.ipv4.ip_forward = 1`

Verification was performed with:

```bash
ansible -i inventory.ini k8s_cluster -b -m shell -a \
"swapon --show; getenforce; lsmod | grep -E 'overlay|br_netfilter'; \
sysctl net.bridge.bridge-nf-call-iptables; \
sysctl net.ipv4.ip_forward"
```

The result confirmed that both nodes had:

SELinux: Permissive
overlay: loaded
br_netfilter: loaded
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1


### Container Runtime

The playbook ansible/containerd.yml installs and configures containerd on all Kubernetes nodes.

The playbook performs the following tasks:

Installs dnf-plugins-core
Adds the Docker CE repository
Installs containerd.io
Creates /etc/containerd
Generates the default containerd configuration
Configures containerd to use the systemd cgroup driver
Enables and starts the containerd service

The following configuration was enabled: SystemdCgroup = true

Verification confirmed that containerd was:

active
enabled

on both nodes.

### 1. Why does the Kubernetes kubelet refuse to run if swap is enabled?

Kubernetes expects the kubelet to have predictable control over node memory.

If swap is enabled, the operating system may move memory pages from RAM to disk. This makes memory usage less predictable from Kubernetes' point of view and can interfere with resource limits, scheduling, and memory-pressure decisions.

For this reason, the standard Kubernetes node setup disables swap before starting kubelet.

### 2. Why must containerd and kubelet use the same cgroup driver?

Linux cgroups are used to control and account for resources such as CPU and memory.

The kubelet manages Kubernetes workloads, while containerd manages the actual containers. Both therefore interact with the same cgroup hierarchy.

If kubelet and containerd use different cgroup drivers, they may manage resources using different cgroup structures. This can lead to inconsistent resource management and node instability.

In this project, containerd is configured with: SystemdCgroup = true
so that the container runtime uses the systemd cgroup driver expected by the Kubernetes node configuration.



# Task 14 __________________________________________________________________________________________

The kubernetes.yml playbook configures the Kubernetes v1.36 repository and installs:

kubelet
kubeadm
kubectl

The installed version was verified as Kubernetes v1.36.5
Kubelet is enabled on both nodes and firewalld is inactive.

The control-plane.yml playbook initializes the control plane using:
´´´
kubeadm init \
  --apiserver-advertise-address=10.0.1.10 \
  --pod-network-cidr=192.168.0.0/16
´´´
The Kubernetes configuration is copied to /home/sajida/.kube/config for the automation user.
Calico v3.31.0 is then installed as the cluster Container Network Interface (CNI).


### Why is the control-plane node NotReady until Calico is installed?

kubeadm init creates the Kubernetes control plane, but it does not install a pod networking implementation. Without a CNI plugin, Kubernetes cannot configure networking between pods.Calico provides the required pod network. Once Calico is running successfully, Kubernetes networking becomes available and the node can transition to Ready.

# Task 15 __________________________________________________________________________________________

The workers.yml playbook joins the worker node using the join command generated on the control-plane node.

The task uses:
´´´
creates: /etc/kubernetes/kubelet.conf
´´´

so an already joined worker is not unnecessarily joined again when the playbook is rerun. The entire cluster was deployed using:
´´´
ansible-playbook -i inventory.ini site.yml
´´´

The final Ansible result & Cluster status was verified with::
![ final ansible](docs/screenshots/task15-palyRecap-getNodes.png)


### Engineering Post-Mortem - Worker Node Became Unresponsive

**Error:**  
`k8slab-w1` became unreachable by SSH and Ansible. Azure still showed the VM as running, but the VM Agent status was:

```text
ProvisioningState/Unavailable
Not Ready
VM Agent is unresponsive
```

Cause:
The worker VM itself became unhealthy. A normal restart and Azure redeploy did not recover the guest OS/VM Agent.

Fix:
The worker VM was replaced with Terraform using:

terraform plan -replace='azurerm_linux_virtual_machine.nodes["w1"]'

Only the VM was recreated, while the existing NIC and static IP addresses remained unchanged.

After recreation, the VM Agent returned Ready, SSH access was restored, and Ansible connectivity worked again.

Lesson Learned:
A VM can still appear as running in Azure while the guest OS or VM Agent is unhealthy. VM health should therefore be checked using SSH, VM Agent status, and Ansible connectivity, not only the cloud power state