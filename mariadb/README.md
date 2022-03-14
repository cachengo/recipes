
![mariadb logo](https://mariadb.org/wp-content/uploads/2019/01/mariadb_org_rgb_h-1.png "MariaDB Logo")

## What is MariaDB?
---


MariaDB Server is one of the most popular open source relational databases. It’s made by the original developers of MySQL and guaranteed to stay open source.

It is built upon the values of performance, stability, and openness.
## Features
---

-   Cloud DBaaS: SkySQL
-   Workloads: transactions, analytics and smart transactions (HTAP)
-   Transactional scalability: distributed SQL
-   Analytical scalability: columnar data with massively parallel processing
-   Development: temporal tables, JSON documents and geospatial support
-   High availability: automatic failover and transaction replay
-   Disaster recovery: online backups and point-in-time restore
-   Security: transparent data encryption and dynamic data masking
-   Oracle Database compatiblity: data types, sequences and PL/SQL


## Installation
---


1. Select the devices to which MariaDB will be installed from 'Devices' page. 

2. Navigate to the 'App Marketplace' tab and select the 'MariaDB' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install MariaDB' in the bottom right corner.



## Required Parameters
---
One of `MARIADB_ROOT_PASSWORD`, `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD`, or `MARIADB_RANDOM_ROOT_PASSWORD`, is required. 

**ROOT_PASSWORD**

This specifies the password that will be set for the MariaDB `root` superuser account. In the above example, it was set to `my-secret-pw`.

**ALLOW_EMPTY_ROOT_PASSWORD**

Set to a non-empty value, like `yes`, to allow the container to be started with a blank password for the root user.

**RANDOM_ROOT_PASSWORD**

Set to a non-empty value, like `yes`, to generate a random initial password for the root user. The generated root password will be printed to stdout (`GENERATED ROOT PASSWORD: .....`).

**HOST_PORT**
The host port mapped to the container.

## Additional Parameters
---

**Installation Name**

Here you will put your app name. Although the app name is MariaDB on the portal, you can personalize the name that is shown on the device's Applications.

**NETWORK**
This parameter allows you to create or assign the container to a Docker network. 

**DB_USER**, **DB_PASSWORD**

These are used in conjunction to create a new user and to set that user's password. Both user and password variables are required for a user to be created. 


**DATABASE_NAME** 

This variable allows you to specify the name of a database to be created on image startup.



## Using MariaDB
---


1. Connect to the device via SSH. 
2. The following command starts another  `mariadb`  container instance and runs the  `mysql`  command line client against your original  `mariadb`  container, allowing you to execute SQL statements against your database instance:

```console
$ docker run -it --network some-network --rm mariadb mysql -hsome-mariadb -uexample-user -p
```

... where  `some-mariadb`  is the name of your original  `mariadb`  container (connected to the  `some-network`  Docker network).
3. You will be asked for the database password.
4. Now you can execute SQL statements against your database instance.
    

## OS Architectures
---
 - Arm64

## Limitations / Known issues
---

 
## MariaDB Platform  Video
---


[![Demo Image](http://img.youtube.com/vi/EY367OkwJpY/0.jpg)](https://www.youtube.com/watch?v=EY367OkwJpY)

## Docs
---

For more information: <https://github.com/MariaDB/server#readme>

