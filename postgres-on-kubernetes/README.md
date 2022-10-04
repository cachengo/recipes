![postgres logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/postgres/logo.png "Postgres Logo")

## What is PostgreSQL?

---

PostgreSQL, often simply "Postgres", is an object-relational database management system (ORDBMS) with an emphasis on extensibility and standards-compliance. It can handle workloads ranging from small single-machine applications to large Internet-facing applications with many concurrent users. Recent versions also provide replication of the database itself for security and scalability.

## Features

---

- User-defined types.
- Table inheritance.
- Sophisticated locking mechanism.
- Foreign key referential integrity.
- Views, rules, subquery.
- Nested transactions (savepoints)
- Multi-version concurrency control (MVCC)
- Asynchronous replication.

## Installation

---

1. Select the devices to which PostgreSQL will be installed from 'Devices' page.

2. Navigate to the 'App Marketplace' tab and select the 'PostgreSQL' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install PostgrSQL' in the bottom right corner.

## Required Parameters

---

**POSTGRES_USERNAME**
This variable is used in conjunction with `POSTGRES_PASSWORD` to set a user and its password.

**POSTGRES_PASSWORD**
This variable is used in conjunction with `POSTGRES_USERNAME` to set a user and its password.

## Additional Parameters

---

**Installation Name**

Here you will put your app name. Although the app name is MariaDB on the portal, you can personalize the name that is shown on the device's Applications.

**NAMESPACE_NAME**
This variable is used to create a namespace in Kubernetes. Leave it in blank to install pods on default namespace.

## Using PostgreSQL

---

Use device shell to execute commands using psql client. This command will open psql client in interactive mode.

kubectl exec -it -n <yournamespace> postgres-0 -- psql -U <yourusername> -W

After executing this command, you will be asked for the password you already assign in the Postgres installation.

Then, you can execute psql commands to use the database.

## OS Architectures

---

- Arm64

## Limitations / Known issues

---

## PostgreSQL Platform Video

---

[![Demo Image](http://img.youtube.com/vi/tzbA7VniRpw/0.jpg)](https://youtu.be/tzbA7VniRpw)

## Docs

---

For more information: <https://github.com/docker-library/docs/tree/master/postgres/README.md>
