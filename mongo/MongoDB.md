![mongodb logo](https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/MongoDB_Logo.svg/2560px-MongoDB_Logo.svg.png "MongoDB Logo")

## What is MongoDB?

---

MongoDB is a free and open-source cross-platform document-oriented database program. Classified as a NoSQL database program, MongoDB uses JSON-like documents with schemata.

## Features

---

- Comprehensive monitoring for full-performance visibility
- Supported:Automated database management for 10-20x more efficient ops
- Supported:Fully-managed backup for your peace of mind

## Installation

---

1. Select the devices to which MongoDB will be installed from 'Devices' page.

2. Navigate to the 'App Marketplace' tab and select the 'MongoDB' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install MongoDB' in the bottom right corner.

## Required Parameters

---

**ROOT_PASSWORD**, **ROOT_USERNAME**

These variables, used in conjunction, create a new user and set that user's password. This user is created in the `admin` [authentication database](https://docs.mongodb.com/manual/core/security-users/#user-authentication-database) and given [the role of `root`](https://docs.mongodb.com/manual/reference/built-in-roles/#root), which is [a "superuser" role](https://docs.mongodb.com/manual/core/security-built-in-roles/#superuser-roles).

**HOST_PORT**
The host port mapped to the container.

## Additional Parameters

---

**Installation Name**

Here you will put your app name. Although the app name is MariaDB on the portal, you can personalize the name that is shown on the device's Applications.

**NETWORK**
This parameter allows you to create or assign the container to a Docker network.

**DB_NAME**

This variable allows you to specify the name of a database to be used for creation scripts in `/docker-entrypoint-initdb.d/*.js` (see _Initializing a fresh instance_ below). MongoDB is fundamentally designed for "create on first use", so if you do not insert data with your JavaScript files, then no database is created.

## Using MongoDB

---

To access the database via UI it is recommended to connect via Compass.

For more information about this product, visit: <[https://www.mongodb.com/products/compass]>

## OS Architectures

---

- Arm64

## Limitations / Known issues

---

Version 5.0+ doesn't work on our devices. You need to install version 4.4.

Web interface not supported.

## MongoDB Platform Video

---

[![Demo Image](http://img.youtube.com/vi/RGfFpQF0NpE/0.jpg)](https://www.youtube.com/watch?v=RGfFpQF0NpE)

## Docs

---

For more information: <[https://github.com/docker-library/docs/tree/master/mongo/README.md](https://github.com/docker-library/docs/tree/master/mongo/README.md#supported-tags-and-respective-dockerfile-links)>
