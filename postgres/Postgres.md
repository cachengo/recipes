
![postgres logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/postgres/logo.png "Postgres Logo")

## What is PostgreSQL?
---


PostgreSQL, often simply "Postgres", is an object-relational database management system (ORDBMS) with an emphasis on extensibility and standards-compliance. It can handle workloads ranging from small single-machine applications to large Internet-facing applications with many concurrent users. Recent versions also provide replication of the database itself for security and scalability.

## Features
---

-   User-defined types.
-   Table inheritance.
-   Sophisticated locking mechanism.
-   Foreign key referential integrity.
-   Views, rules, subquery.
-   Nested transactions (savepoints)
-   Multi-version concurrency control (MVCC)
-   Asynchronous replication.

## Installation
---


1. Select the devices to which PostgreSQL will be installed from 'Devices' page. 

2. Navigate to the 'App Marketplace' tab and select the 'PostgreSQL' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install PostgrSQL' in the bottom right corner.



## Required Parameters
---


**DB_PASSWORD**

This environment variable sets the superuser password for PostgreSQL. The default superuser is defined by the  `POSTGRES_USER`  environment variable.



## Additional Parameters
---

**Installation Name**

Here you will put your app name. Although the app name is MariaDB on the portal, you can personalize the name that is shown on the device's Applications.

**NETWORK**
This parameter allows you to create or assign the container to a Docker network. 

**DB_USER**

This optional environment variable is used in conjunction with `POSTGRES_PASSWORD` to set a user and its password. This variable will create the specified user with superuser power and a database with the same name. If it is not specified, then the default user of `postgres` will be used.


**DB_NAME** 

This optional environment variable can be used to define a different name for the default database that is created when the image is first started. If it is not specified, then the value of `POSTGRES_USER` will be used.



## Using PostgreSQL
---


1. Connect to the device via SSH. 
2. The following command starts another  `postgres`  container instance and runs the  `psql`  command line client against your original  `postgres`  container, allowing you to execute SQL statements against your database instance:

```console
docker run -it --rm --network some-network postgres psql -h some-postgres -U postgres
```
```
```

... where  `some-postgres`  is the name of your original  `postgres`  container (connected to the  `some-network`  Docker network).
3. You will be asked for the database password.
4. Now you can execute SQL statements against your database instance.
    

## OS Architectures
---
 - Arm64

## Limitations / Known issues
---

 
## PostgreSQL Platform  Video
---


[![Demo Image](http://img.youtube.com/vi/tzbA7VniRpw/0.jpg)](https://youtu.be/tzbA7VniRpw)

## Docs
---

For more information: <https://github.com/docker-library/docs/tree/master/postgres/README.md>

