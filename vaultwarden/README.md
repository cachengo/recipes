![VaultWarden Image](https://raw.githubusercontent.com/cachengo/recipes/darwin_recipes/vaultwarden/vault1.png)




# What is VaultWarden?

Vaultwarden is an unofficial Bitwarden server implementation written in Rust. It is compatible with the [official Bitwarden clients](https://bitwarden.com/download/ "Official BitWarden Clients"), and is ideal for self-hosted deployments where running the official resource-heavy service is undesirable.
 
Vaultwarden is targeted towards individuals, families, and smaller organizations. Development of features that are mainly useful to larger organizations (e.g., single sign-on, directory syncing, etc.) is not a priority, though high-quality PRs that implement such features would be welcome.

# Supported Features

### Vaultwarden implements the Bitwarden APIs required for most functionality, including:

1. Web interface (equivalent to https://vault.bitwarden.com/)
2. Personal vault support
3. [Organization](https://bitwarden.com/help/article/getting-started-organizations/ "Organization VaultWarden") vault support
4. [Password Sharing](https://bitwarden.com/help/article/share-to-a-collection/   "Password Sharing VaultWarden") and [access control](https://bitwarden.com/help/article/user-types-access-control/ "Access Control VaultWarden")
5. [Collections](https://bitwarden.com/help/article/about-collections/ "Collections")
6. [File attachments](https://bitwarden.com/help/article/attachments/ "File attachments")
7. [Folders](https://bitwarden.com/help/article/folders/ "Folders")
8. [Favorites](https://bitwarden.com/help/article/favorites/ "Favorites")
9. [Website icons](https://bitwarden.com/help/article/website-icons/ "Website icons")
10. [Bitwarden Authenticator (TOTP)](https://bitwarden.com/help/article/authenticator-keys/ "Bitwarden Authenticator")
11. [Bitwarden Send](https://bitwarden.com/help/article/about-send/ "Bitwarden Send")
12. [Emergency Access](https://bitwarden.com/help/article/emergency-access/ "Emergency Access")
13. [Live sync](https://bitwarden.com/blog/post/live-sync/ "Live sync") (WebSocket only) for desktop/browser clients/extensions
14. [Trash](https://bitwarden.com/help/article/managing-items/#items-in-the-trash "Trash") (soft delete)
15. [Master password re-prompt](https://bitwarden.com/help/article/managing-items/#protect-individual-items "Master password re-prompt")
16. [Personal API key]()
17. Two-step login via [email](https://bitwarden.com/help/article/setup-two-step-login-email/ "Email"), [Duo](https://bitwarden.com/help/article/setup-two-step-login-duo/ "Duo"), [YubiKey](https://bitwarden.com/help/article/setup-two-step-login-yubikey/ "YubiKey"), and [FIDO2 WebAuthn](https://bitwarden.com/help/article/setup-two-step-login-fido/ "FIDO2 WebAuthn")
18. [Directory Connector](https://bitwarden.com/help/article/directory-sync/ "Directory Connector") support (basic implementation, no group support) 
Only version [v2.9.2](https://github.com/bitwarden/directory-connector/releases/tag/v2.9.2 "v2.9.2") and lower is supported, v2.9.3 and up use a different login 
method not supported yet.

# Certain enterprise policies:
- [Two-Step Login](https://bitwarden.com/help/article/policies/#two-step-login "Two-Step Login")
- [Master Password](https://bitwarden.com/help/article/policies/#master-password "Master Password")
- [Password Generator](https://bitwarden.com/help/article/policies/#password-generator "Password Generator")
- [Personal Ownership](https://bitwarden.com/help/article/policies/#personal-ownership "Personal Ownership")
- [Disable Send](https://bitwarden.com/help/article/policies/#disable-send "Disable Send")
- [Send Options](https://bitwarden.com/help/article/policies/#send-options "Send Options")
- [Single Organization](https://bitwarden.com/help/article/policies/#single-organization "Single Organization")

# Installing VaultWarden
1. Under 'Devices' page, select which server you would like to install VaultWarden on.

2. Then navigate to the 'App Marketplace' page and select the VaultWarden application.

3. At the top of your screen you should see a 'Install now'. Click install now.

4. Give you installtion a name. 

5. Under "parameters" you can set the admin password and login to the admin page from your web browser. (This is optional and not necessarry to use vaultwarden), From there you will be able to create and control vaults, users, organizations, passwords and control who can access them. If you're using vaultwarden your own personal vault and don't want to share your info you can skip the parameters section.

6. Then click install vaultwarden.
# Accessing VaultWarden
## For Local Access to your vault.
(For local access you need to be on the same network as your VaultWarden server)

1. In the cachengo portal, go to your server and beside "Local IP:" you should see an IPV4Address, (Example: Local IP: 192.168.1.1) copy that ip address.

2. Go your web browser and open a new tab. In the URL, type [https://IPv4Address] without brackets and insert the IP of your server. (Example: https://192.168.1.1) Then press enter.

3. You will then be prompted with a Bitwarden login screen. You will need to create an account using an email and password of your choosing.

4. Once you've created your account you will be able to login using your email and password.


# For Remote/Global Access to your vault
For Remote/Global Access your desktop or laptop will need to be added to the cachengo portal and need to be in the same peer-group as your VaultWarden server. (if you have not add your desktop or laptop to the portal, go to this link https:// and follow instructions.)

This method will be used if you're not on the same network as your VaultWarden server)

1. Login to the cachengo portal.

2. Under 'Devices' tab select your desktop or laptop as well as your VaultWarden server.

3. Navigate to the 'Peer Groups' tab.

4. From here you can create a new peer group and add your server to it or add it to an existing one. Then click install at the top of the screen.

5. Once they are both in the same peer group, you should be able to see a unique IPV6 address beside 'IP address:',(Example: IP address: fde5:ef2d:1377:3a9f:2499:93d5:9759:4f20) that will be the ip address you use in your web browser. (Example: [https://fde5:ef2d:1377:3a9f:2499:93f5:9159:4f10]) with brackets. 

6. Also for the Remote/Global access you will be prompted with a Bitwarden login screen and will need to create an account using your email and a password of your choosing. Then login with your email and password.


# Accessing the admin page

1. Open your web browser, in the url use either the local or remote ip address of your server and at the end put /admin. (Example: http://192.168.1.2/admin or [http://fde5:ef2d:1377:3a9f:2499:93f5:9159:4f10/admin]

2. Once you've reached the admin page you should be prompted with a login screen. Use the password you set in the parameters section of the instillation to login.

3. From there you can create and control all the vaults, orgs, and users. 