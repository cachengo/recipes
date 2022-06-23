![seaweedfs logo](https://raw.githubusercontent.com/chrislusf/seaweedfs/master/note/seaweedfs.png "seaweedfs Logo")

## What is SeaweedFS?

---

SeaweedFS is a simple and highly scalable distributed file system. 


## Features

---

- Can choose no replication or different replication levels, rack and data center aware.
- Automatic master servers failover - no single point of failure (SPOF).
- Automatic Gzip compression depending on file MIME type.
- Automatic compaction to reclaim disk space after deletion or update.
- Automatic entry TTL expiration.
- Any server with some disk spaces can add to the total storage space.
- Adding/Removing servers does not cause any data re-balancing unless triggered by admin commands.
- Optional picture resizing.
- Support ETag, Accept-Range, Last-Modified, etc.
- Support in-memory/leveldb/readonly mode tuning for memory/performance balance.
- Support rebalancing the writable and readonly volumes.
- Customizable Multiple Storage Tiers: Customizable storage disk types to balance performance and cost.
- Transparent cloud integration: unlimited capacity via tiered cloud storage for warm data.
- Erasure Coding for warm storage Rack-Aware 10.4 erasure coding reduces storage cost and increases availability.

## Installation

---

1. Select the devices to which SeaweedFS will be installed from 'Devices' page.

2. Navigate to the 'App Marketplace' tab and select the 'SeaweedFS' application.

3. The 'Install Now' button should now appear near the top of the screen. Select this button.

4. Give your installation a name and fill all the parameters. Click 'Install SeaweedFS' in the bottom right corner.

5. After installing master servers, to install more volumes, proceed to the marketplace and install 'SeaweedFS-Volume'.

## Required Parameters

---


**MASTER_PORT**

By default, the master node runs on port 9333, and the volume nodes run on port 8080

**VOLUME_PORT**

By default, the volume nodes run on port 8080

**MASTER_NODES**

IP Address of the master servers. At least 3 servers are needed. 

## Additional Parameters

---

**Installation Name**

Here you will put your app name. Although the app name is MariaDB on the portal, you can personalize the name that is shown on the device's Applications.


## How it works

---
The master servers are coordinated by Raft protocol, to elect a leader. The leader takes over all the work to manage volumes, assign file ids. All other master servers just simply forward requests to the leader.

If the leader dies, another leader will be elected. And all the volume servers will send their heartbeat together with their volumes information to the new leader. The new leader will take the full responsibility.

During the transition, there could be moments where the new leader has partial information about all volume servers. This just means those yet-to-heartbeat volume servers will not be writable temporarily.

## Using SeaweeFS 

Write File
To upload a file: first, send a HTTP POST, PUT, or GET request to /dir/assign to get an fid and a volume server URL:

> curl http://localhost:9333/dir/assign
{"count":1,"fid":"3,01637037d6","url":"127.0.0.1:8080","publicUrl":"localhost:8080"}
Second, to store the file content, send a HTTP multi-part POST request to url + '/' + fid from the response:

> curl -F file=@/home/chris/myphoto.jpg http://127.0.0.1:8080/3,01637037d6
{"name":"myphoto.jpg","size":43234,"eTag":"1cc0118e"}
To update, send another POST request with updated file content.

For deletion, send an HTTP DELETE request to the same url + '/' + fid URL:

> curl -X DELETE http://127.0.0.1:8080/3,01637037d6
Save File Id
Now, you can save the fid, 3,01637037d6 in this case, to a database field.

The number 3 at the start represents a volume id. After the comma, it's one file key, 01, and a file cookie, 637037d6.

The volume id is an unsigned 32-bit integer. The file key is an unsigned 64-bit integer. The file cookie is an unsigned 32-bit integer, used to prevent URL guessing.

The file key and file cookie are both coded in hex. You can store the <volume id, file key, file cookie> tuple in your own format, or simply store the fid as a string.

If stored as a string, in theory, you would need 8+1+16+8=33 bytes. A char(33) would be enough, if not more than enough, since most uses will not need 2^32 volumes.

If space is really a concern, you can store the file id in your own format. You would need one 4-byte integer for volume id, 8-byte long number for file key, and a 4-byte integer for the file cookie. So 16 bytes are more than enough.

Read File
Here is an example of how to render the URL.

First look up the volume server's URLs by the file's volumeId:

> curl http://localhost:9333/dir/lookup?volumeId=3
{"volumeId":"3","locations":[{"publicUrl":"localhost:8080","url":"localhost:8080"}]}
Since (usually) there are not too many volume servers, and volumes don't move often, you can cache the results most of the time. Depending on the replication type, one volume can have multiple replica locations. Just randomly pick one location to read.

Now you can take the public URL, render the URL or directly read from the volume server via URL. Remember to replace localhost with the IPV6 of the master node. For example :

http://[fde5:ef2d:1377:aa0f:6299:93ce:d95e:c50e]:8080/3,01637037d6.jpg
Notice we add a file extension ".jpg" here. It's optional and just one way for the client to specify the file content type.

If you want a nicer URL, you can use one of these alternative URL formats:

 http://localhost:8080/3/01637037d6/my_preferred_name.jpg
 http://localhost:8080/3/01637037d6.jpg
 http://localhost:8080/3,01637037d6.jpg
 http://localhost:8080/3/01637037d6
 http://localhost:8080/3,01637037d6
If you want to get a scaled version of an image, you can add some params:

http://localhost:8080/3/01637037d6.jpg?height=200&width=200
http://localhost:8080/3/01637037d6.jpg?height=200&width=200&mode=fit
http://localhost:8080/3/01637037d6.jpg?height=200&width=200&mode=fill

## OS Architectures

---

- Arm64

## Limitations / Known issues

---

## SeaweedFS Platform Video

---

[![Demo Image](http://img.youtube.com/vi/szoZdELtQZI/0.jpg)](https://youtu.be/szoZdELtQZI)

## Docs

---

For more information: <https://github.com/chrislusf/seaweedfs#readme>
