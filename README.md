## Pre-Requisites
* Install Terraform onto your machine
* Install AWS CLI
* Generate SSH key


## Configure AWS Provider
You will need to install the AWS CLI onto the machine

Generate SSH key
`ssh-keygen -f ~/.ssh/id_rsa_terraform`

Create keys and secrets in AWS.

Create a `secrets` folder locally. This folder is not tracked in Git. 
DO NOT TRACK THIS FOLDER IN GIT IT HAS SENSITIVE INFORMATION.

Add a valid XSOAR license to `secrets` directory and call it `license.lic`.
Add an `otc.conf.json` file to the secrets directory with a preconfigured user, password, and API key.

Example `otc.conf.json` file.

```
{
  "users": [{
    "username": "someadmin",
    "password": "SomePassword",
    "email": "admin@company.com",
    "phone": "+650-123456",
    "name": "Your Name",
    "roles": {
      "demisto": [
        "Administrator"
      ]
    }
  }],
  "apikeys": [
   {
     "name": "installAPIKey",
     "username": "someadmin",
     "apikey": "OFTHEFORMAAADDDDBBBBBBB"
   }
 ]
}
```

Export environment variables

```
export AWS_ACCESS_KEY_ID="<key_id>"
export AWS_SECRET_ACCESS_KEY="<secret_access_key>"
export AWS_SESSION_TOKEN="<session_token>"
export TF_VAR_PUBLIC_KEY="<path_to_key>/id_rsa_terraform.pub"
export TF_VAR_PRIVATE_KEY="<path_to_key>/id_rsa_terraform"
export TF_VAR_DOWNLOAD_TOKEN="<token_for_download_url>"
export TF_VAR_DOWNLOAD_EMAIL="<email_for_download_url>"
export TF_VAR_API_KEY="<API_KEY>"
export TF_TRUSTED_IP_CIDR="0.0.0.0/0"
```

The AWS access key, secret, and session token are generated from AWS.
The Public key and private key variables are the path to the keys generated with `ssh-keygen`.
The download token and download email are for the url in the form
The trusted IP cidr range will allow access over port 22 and 443 for the specified IP.

```
https://download.demisto.works/download-params/?token=<token>&email=<email>
```
The API Key should match the pre generated XSOAR API key in the otc.conf.json file.

The install script for xsoar is found in the `bin` directory of this repository.
It accepts the API key, download token and download email as parameters.        

### XDR Vulnerable Host
A vulnerable host can be deployed with a randomly selected vulnerablilty from vulhub by uncommenting
the "Vulnerable Host" section of the `aws.tf` file.

The XDR agent Linux installer should be placed in the `secrets` directory and should be called `Linux_Agent.sh`.


## Deploy Environment
```
terraform init
terraform plan
terraform apply
```
