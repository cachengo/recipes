![Ingress-nginx logo](https://docs.nginx.com/nginx-ingress-controller/images/icons/NGINX-Ingress-Controller-product-icon.svg "Ingress-nginx Logo")

## What is Ingress-nginx?

---

Ingress-nginx is an Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.

## Features

---

An API object that manages external access to the services in a cluster, typically HTTP.

Ingress may provide load balancing, SSL termination and name-based virtual hosting.

## Installation

---

1. Select the devices to which Ingress-nginx will be installed from 'Devices' page.

2. Navigate to the 'App Marketplace' tab and select the 'Ingress-nginx' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install Ingress-nginx' in the bottom right corner.

## Required Parameters

---

## Additional Parameters

---

**Installation Name**

Here you will put your app name. Although the app name is Ingres-nginx on the portal, you can personalize the name that is shown on the device's Applications.

## Using Ingress-nginx

---

Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource.

An Ingress may be configured to give Services externally-reachable URLs, load balance traffic, terminate SSL / TLS, and offer name-based virtual hosting. An Ingress controller is responsible for fulfilling the Ingress, usually with a load balancer, though it may also configure your edge router or additional frontends to help handle the traffic.

An Ingress does not expose arbitrary ports or protocols. Exposing services other than HTTP and HTTPS to the internet typically uses a service of type Service.Type=NodePort or Service.Type=LoadBalancer.

## OS Architectures

---

- Arm64

## Limitations / Known issues

---

N/A

## Ingress-nginx Platform Video

---

[![Demo Image](http://img.youtube.com/vi/AXZr2OC8Unc/0.jpg)](https://www.youtube.com/watch?v=AXZr2OC8Unc)

## Docs

---

For more information: <[https://kubernetes.io/docs/concepts/services-networking/ingress/]>
