# Recipes
A repository holding recipes for popular Cachengo Apps. 

## What is a Cachengo App?
A Cachengo App is defined by a single executable archive that takes either "install" or "uninstall" as an argument; it is the main requirement for declaring a new app in the Cachengo portal. All necessary logic for installing and uninstalling the application must be contained in this file. 

## What if my installation requires user configuration?
These is where parameters come in. All parameters are injected into the enviroment where the installer runs. By default, the installer will receive two variables: `$APPID` and `$GROUPID`. `$APPID` provides a string which can used to uniquely identify the installation on the device, this is useful for namespacing when an app can be installed multiple times in the same device and to aid with uninstall logic. Similarly, `$GROUPID` provides a string which uniquely identifies installations that were requested together; this variable is intended to help with setting up clusters. Application developers can define additional parameters they would like to receive as environment variables by specifying them in the parameters section of the "Create Application" form. Parameters of type list will be set as json encoded strings.

## What does SSH installation mean?
Not all clustered apps can be installed without a leader coordinating. When you check the box for "SSH Installation" the installer will only run on one node (the leader node) even when multiple nodes are the targets of the installation. In this type of installation the leader node will get temporary SSH access to the rest of the nodes in the installation, which enables app developers to use tools like ansible to define their installers.

## What happens when I check the "Public" checkbox?
Checking the "Public" checkbox will make your application appear in the Marketplace.

## How do I update the end-user of the status of the installation?
Use a system call to invoke the CLI: `cachengo-cli updateInstallStatus $APPID "MY NEW STATUS"`. Keep in mind that the new status shouldn't be longer than 20 characters.

## What about logging?
The entire output of stdout will be appended to a log which is made available through the portal when the installation finishes.

## Example
Here is an example installer written in bash that will bring up a Min.io cluster:
```bash
#!/bin/bash

function array_from_json_list {
  local -n arr=$1
  readarray -td '' arr < <(awk '{ gsub(/, /,"\0"); print; }' <<<"$2, ")
  unset 'arr[-1]'
  arr=( "${arr[@]##[}" )
  arr=( "${arr[@]##\"}" )
  arr=( "${arr[@]%]}" )
  arr=( "${arr[@]%\"}" )
}

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  echo $IPS
  local IPS_ARR
  array_from_json_list IPS_ARR "$IPS"
  export MINIO_ACCESS_KEY=$ACCESS_KEY
  export MINIO_SECRET_KEY=$SECRET_KEY

  for ((i=0;i<${#IPS_ARR[@]};++i)); do 
    echo "${IPS_ARR[i]} $GROUPID-$i"
    echo "${IPS_ARR[i]} $GROUPID-$i" >> /etc/hosts
  done

  echo "Total: $i"

  docker run -p 9000:9000 \
    --name $APPID \
    -d \
    -e "MINIO_ROOT_USER=$ACCESS_KEY" \
    -e "MINIO_ROOT_PASSWORD=$SECRET_KEY" \
    --net host \
    --restart unless-stopped \
    registry.cachengo.com/minio/minio server http://$GROUPID-{0...$((i-1))}/data/

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  rm -rf /data/dist_minio
  sed -i "/$GROUPID/d" /etc/hosts
  docker stop $APPID
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}

case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
```

## How to make a new recipe
The easiest way to get started is to look through the examples in the different folders and follow from there. But the general workflow is as follows:
1. Create a folder for your new recipe
2. Create a `run.sh` file and fill up with the commands for installing or uninstalling the app
3. Create a `package.json` file to help in the automated building of your recipe file
4. Call `python3 build.py <YOURFOLDER>` (this will generate a `<YOURFOLDER>.recipe` file)
5. Go to the Cachengo portal and click on the "+" under the Apps tab to declare your new app
6. Profit

## Any other tips?
#### List parameters
Question: The Cachengo portal allows you to declare parameters as list but environment variables cannot hold bash arrays, what should I do? 
Answer: `utils/parameters.sh` contains a helpful function to parsed your JSON serialized string into a bash array you can use. Don't forget to `source utils/parameters.sh` in your run.sh and include `utils/parametes.sh` in your denpendencies in `package.json`.
#### Status Updates
You have seen the installation states updating in the portal as an installation progresses. For your installation to do the same you should `source utils/cachengo.sh` and call `update_status <MYSTATUS>` at key steps in your installation. One important thing to remember is that your status must be **20 characters or less**
#### App secrets
Secrets are name value pairs that are stored in an encrypted database and pulled into the frontend only by request. We use secrets as way to allow apps the give the user information that will help them with further managing of the app (e.g. secret token to add worker nodes to Kubernetes). To declare secrets during your installation call `source utils/cachengo.sh` and call `declare_secret <NAME> <VALUE>` whenever you want to declare a new secret key-value pair.

