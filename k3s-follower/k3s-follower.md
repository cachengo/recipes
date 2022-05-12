![K3S logo](https://k3s.io/images/logo-k3s.svg "K3S Logo")

## What is K3S?

---

Lightweight Kubernetes
The certified Kubernetes distribution built for IoT & Edge computing

The K3s-Follower is responsible for running the kubelet and kube-proxy. In addition:

Flannel as embedded process
Containerd as the container runtime
Internal load balancer that load-balances connections between all API servers in HA configurations
Network policy controller to enforce network policies

## Features

---

-Perfect for Edge
K3s is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.

-Simplified & Secure
K3s is packaged as a single <50MB binary that reduces the dependencies and steps needed to install, run and auto-update a production Kubernetes cluster.

-Optimized for ARM
Both ARM64 and ARMv7 are supported with binaries and multiarch images available for both. K3s works great from something as small as a Raspberry Pi to an AWS a1.4xlarge 32GiB server.

## Installation

---

1. Select the devices to which K3S-Follower will be installed from 'Devices' page.

2. Navigate to the 'App Marketplace' tab and select the 'K3S-Follower' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install K3S-Follower' in the bottom right corner.

## Required Parameters

---

**K3S_TOKEN**
Secret token used for joining new nodes

**IP_ADDRESS**
IP address of the leader node

## Additional Parameters

---

**Installation Name**

Here you will put your app name. Although the app name is MariaDB on the portal, you can personalize the name that is shown on the device's Applications.

**INSTALL_K3S_VERSION**
Version of k3s to download from github.

## Using K3S

---

### Device Shell

Use device shell to interact with K3S using kubectl commands. To see the nodes that are part of your cluster, run:

`kubectl get nodes`

For more information about commands visit <https://rancher.com/docs/k3s/latest/en/>

### K3S Dashboard

Dashboard is a web-based Kubernetes user interface. You can use Dashboard to deploy containerized applications to a Kubernetes cluster, troubleshoot your containerized application, and manage the cluster resources.

K3S Dashboard will be available soon to install from the App Marketplace.

## OS Architectures

---

- Arm64

## Limitations / Known issues

---

N/A

## K3S Platform Video

---

[![Demo Image](http://img.youtube.com/vi/2LNxGVS81mE/0.jpg)](https://www.youtube.com/watch?v=2LNxGVS81mE)

## Docs

---

For more information: <[https://rancher.com/docs/k3s/latest/en/]>
