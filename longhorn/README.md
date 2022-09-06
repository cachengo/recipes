![Longhorn logo](https://longhorn.io/img/logos/longhorn-horizontal-color.png "Longhorn Logo")

## What is Longhorn?

---

Longhorn is a lightweight, reliable and easy-to-use distributed block storage system for Kubernetes.

## Features

---

With Longhorn, you can:

Use Longhorn volumes as persistent storage for the distributed stateful applications in your Kubernetes cluster

Partition your block storage into Longhorn volumes so that you can use Kubernetes volumes with or without a cloud provider

Replicate block storage across multiple nodes and data centers to increase availability

Store backup data in external storage such as NFS or AWS S3

Create cross-cluster disaster recovery volumes so that data from a primary Kubernetes cluster can be quickly recovered from backup in a second Kubernetes cluster

Schedule recurring snapshots of a volume, and schedule recurring backups to NFS or S3-compatible secondary storage

Restore volumes from backup

Upgrade Longhorn without disrupting persistent volumes

## Installation

---

NOTE: Before installing Longhorn, it is required to have already installed k3s-leaders and k3s-followers in your nodes. Please refer to K3s apps in the marketplace for more information about their installation process.

1. Select the devices to which Longhorn will be installed from 'Devices' page.

2. Navigate to the 'App Marketplace' tab and select the 'Longhorn' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name. Click 'Install Longhorn' in the bottom right corner.

g## Required Parameters

---

## Using Longhorn

---

1. Setup SSH Tunneling between your device and any of your nodes using port 32300:

E.g.

```
ssh -L 8083:127.0.0.1:32300 cachengo@fde5:ef2d:1377:132e:b599:932a:3d4:d540
```

2. In your web browser, navigate to your localhost using the fowarded port. This will redirect you to Longhorn UI.

E.g.

```
http://localhost:8083
```

## OS Architectures

---

- Arm64

## Limitations / Known issues

---

## Longhorn Platform Video

---

[![Demo Image](http://img.youtube.com/vi/BnHMAJ8azBU/0.jpg)](https://www.youtube.com/watch?v=BnHMAJ8azBU)

## Docs

---

For more information: <https://github.com/longhorn/longhorn/blob/master/README.md>
