![Jitsu logo](https://jitsu.com/img/jitsu-responsive.svg "Jitsu Logo")

## What is Jitsu?

---

an open-source web- and app- event collection platform. Jitsu is designed to be a fast and easy replacement for proprietary analytics stacks such as Google Analytics and Segment.

## Features

---

Unstructured Event Collection. Jitsu can be used as event gateway for your database. Once an event is sent to Jitsu (via HTTP API or JS SDK), it take cares of the rest: table schema maintenance, batching and/or buffering events (for performance optimization or for reliability). If you want to learn more about how Jitsu works we have an article explaining Jitsu's architecture.

Data Collection (from external services). Jitsu can collect data from external services via an API and insert it in your database. We support a number of native connectors. Also Jitsu can serve as a bridge to Singer, which is an open source command-line framework for API connectors.

Transformation and event dispatching. Think of Jitsu as a network router for events. It can send events to multiple destinations based on dynamic rules. Also, it can apply transformations to incoming data streams, including geo-resolution based on IP addresses and rule-based transformations.

## Installation

---

1. Select the devices to which Jitsu will be installed from 'Devices' page.

2. Navigate to the 'App Marketplace' tab and select the 'Jitsu' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install Jitsu' in the bottom right corner.

## Required Parameters

---

## Additional Parameters

---

**Installation Name**

Here you will put your app name. Although the app name is Jitsu on the portal, you can personalize the name that is shown on the device's Applications.

## Using Jitsu

---


1. Setup SSH Tunneling between your device and any of your nodes using port 32301:

E.g.

```
ssh -L 8000:127.0.0.1:32301 cachengo@fde5:ef2d:1377:132e:b599:932a:3d4:d540
```

2. In your web browser, navigate to your localhost using the fowarded port. This will redirect you to Jitsu UI.

E.g.

```
http://127.0.0.1:8000/configurator

```



## OS Architectures

---

- Arm64

## Limitations / Known issues

---

N/A

## Jitsu Platform Video

---

[![Demo Image](http://img.youtube.com/vi/59cVVUxXxFU/0.jpg)](https://youtu.be/59cVVUxXxFU)

## Docs

---

For more information: <[https://github.com/jitsucom/jitsu/blob/master/README.md]>
