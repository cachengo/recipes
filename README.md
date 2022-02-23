# Recipes
A repository holding recipes for popular Cachengo Apps. 

## What is a Recipe?
A recipe is a simple executable that takes either "install" or "uninstall" as an argument; it is the main requirement for declaring a new app in the Cachengo portal. All parameters that it may require must be read from environment variables. When defining an App in the Cachengo portal, you must define necessary parameters and tell the app which environment variable to set with it's value. The cachengo-cli also always sets the APPID variable so the application can be aware of its own unique identifier (Tip: this is often useful for uninstalling).

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

