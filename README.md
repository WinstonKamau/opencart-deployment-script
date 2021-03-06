# OpenCart Deployment Script

The information below explains how to set up our LAMP stack. In the steps below we end up setting up a Linux Virtual Machine, the Apache package, a MySQL database(for this example we use the opensource MySQL version i.e Maria DB) and PHP.

## Creating the Packer Base Image on Google Cloud Platform

The first step towards setting up the Open Cart website begins by creating a base image. A base image in our case refers to snapshot of a Linux Distribution instance, that contains all the services and packages needed for the Open Cart website to run. To achieve this we use [Packer](https://www.packer.io). **Packer** is an open source tool for creating identical machine images for multiple platforms from a single source configuration. We use it to create a machine image that will be used by all deployments for Open Cart.

Currently our Linux Distribution used is **Ubuntu** version 16.04. The reason Ubuntu was chosen is because it is an open source distribution that has a large community supporting it. It is also freely sold in many cloud platforms making it cost friendly. I needed a distribution that centers on it being easy for me to configure, price friendly and one that I can get access to material for configurations. I chose version 16.04 because it is currently stable as per the chart below.
![Ubuntu Chart](docs/images/ubuntu_release_chart.png?raw=true)
Source: https://www.ubuntu.com/about/release-cycle


The second requirement for our Base Image is the installation of the Apache web server, MySQL database and PHP. All this is configured on the [setup](open-cart-base-image/setup.sh) file. This file is configured using **Bash Script**. 

A weakness of our current setup is that the database of the application will be located on the Virtual Machine. This means that the data is ephemeral for every deployment. However the requirements of the task do not require us to meet that scope. 

1. Ensure that:
- You have a [Google Cloud Platform](https://console.cloud.google.com) account.
- That you have created or own a Google Cloud project to create the base image on.
- That the Compute Engine API has been enabled.
- That you have installed the packer package as per directions from this [link](https://www.packer.io/downloads.html) on your machine and that it is executable on your terminal.

2. Clone the Repository

```
mkdir opencart
cd opencart
git clone https://github.com/WinstonKamau/opencart-deployment-script.git
cd opencart-deployment-script
```

3. Setup the service account

You may follow instructions on creating a service account as per this [link](https://cloud.google.com/iam/docs/creating-managing-service-accounts). The most critical part of the service account is the role that the account will be able to perform. Ensure that the service account has at lease admin capabilities of **Compute Image User**, **Compute Instance Admin** and **Service Account Actor**. Download the Service Account JSON key to your machine after giving the Service Account its roles.

Once you have gotten the key, change the name of the file [account.json.example](account-folder/account.json.example) to account.json. *This file is located under the account-folder directory*. Delete the contents in the file and paste your JSON key here.

4. Setup environment variables.

Let's start by changing the name of the [variables.json.example](open-cart-base-image/variables.json.example) file to variables.json.

Next, provide values for each of the keys shown in the table below. A description of the value needed has been given:

| **Key**           | **Value Description**|
|-------------------|----------------------|
| root_password     | Provide the password you'd like the root user for your mysql database to have|
| open_cart_user    | Provide the name of the user you'd like to own your opencart mysql database|
| open_cart_database| Provide the name of the mysql database you'd like opencart to use |
| open_cart_password| Provide the password you'd like the open cart user to authenticate with|
| project_id        | Provide the google project id where you are hosting your application on|



4. Validate and build the base image.

```
cd open-cart-base-image
packer validate --var-file variables.json packer.json
packer build --var-file variables.json packer.json
```

5. Visit GCP console to confirm that your image has been created.

On the menu page under Compute Engine click on Images.
![Images-GCE-Menu](docs/images/images-gce.png)
You should be able to see the image opencart-base-image on the list of images.
![Opencart-Base-Image](docs/images/opencart-base-image.png)

## Deploying the application.

To deploy our application, we need to set up the infrastructure that will be running on Google Cloud Platform. This will require creating a virtual machine for our website, and setting up networking for the VM. This process will need to be done for every deployment, therefore requiring automation. To automate it we need a scripting language to enable us achieve infrastructure as code. To do this we choose **Terraform**. I value [terraform](https://www.terraform.io/) for its ease of use, its integration with many cloud environments, its high support; with new versions being released frequently, its quality of being free with good documentation.


### Setting up Google Cloud Platform for deployment.

1. Create a storage bucket

First we need to start by creating a storage bucket. Terraform needs to store a file in this storage bucket, which it can use to continuously check in the current state and determine what the desired state will be, before building infrastructure on your platform. Instructions for creating a storage bucket can be found [here](https://cloud.google.com/storage/docs/creating-buckets). Once you are done take note of the name of the bucket that you just created as we shall use it later when running terraform commands.

2. Reserve a static external IP address.

Steps for reserving this can be found [here](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address#reserve_new_static). Note that when reserving an IP address, create it in a region where you would like to create your opencart VM so that you may not have difficulty attaching it to an instance. This is as shown below, where the user intends to create the VM in the us-east1 region:
![IP address reservation Image](docs/images/regional-ip-address.png?raw=true)
Most instances are regional and if given a regional IP address in a different region from their own an error is raised when creating the script.

We need an external Static IP address through which we shall be able to access our site. The reason we choose an external Static IP address rather than an ephemeral IP address, is because we need something long-term that we are going to point our domain address to. Take note of the IP address you reserved as we shall also use it later.

3. Enable APIs and services.

Instructions for enabling an API and Services can be found [here](https://cloud.google.com/endpoints/docs/openapi/enable-api).
Ensure that the Compute Engine API is enabled.

4. Setup the service account 

**Note:** *This service account is different from the one we created above for packer*.

You may follow instructions on creating a service account as per this [link](https://cloud.google.com/iam/docs/creating-managing-service-accounts). The most critical part of the service account is the role that the account will be able to perform. Ensure that the service account has at lease admin capabilities of **Compute Admin**, **Compute Network Admin**, **Service Account User** and **Storage Object Admin**. Download the Service Account JSON key to your machine after giving the Service Account its roles.

Once you have gotten the key, change the name of the file [account.json.example](account-folder/account.json.example) to account.json. *This file is located under the account-folder directory*. Delete the contents in the file and paste your JSON key here.


### Running Terraform scripts

1. Pass environment variables

Our deployment script requires some environment variables. Create a file called terraform.tfvars on the root of your repository. You can derive the structure of secrets needed using the [terrafrom.tfvars.example](terraform.tfvars.example) file on the root of your repository. Replace each of the secret with its respective value.


2. Initializing terraform. 
First step involves initializing terraform. To perform this step you need to have the name of your storage bucket that you created on Step 1 of [Setting up Google Cloud Platform for deployment.](#setting-up-google-cloud-platform-for-deployment)

Run the command below on the root of your repository:
```
terraform init
```

You should get a response like the one below. I have blocked the name of my storage bucket in the image below.

![Terraform init](docs/images/terraform-init.png?raw=true)

3. Create a plan.
The second step involves creating a terraform plan. This produces an output on the console indicating the plan that terraform will execute.
Run the command below on the root of your repository:
```
terraform plan
```

![Terraform plan](docs/images/terraform-plan.png?raw=true)

4. Create the infrastructure.

If you are comfortable with the plan shown in the step above, then create the infrastructure needed for the application by running the command below.

```
terraform apply
```

After running the command above you can visit your infrastructure and check whether your VM instance has been created.

**Note**
- If you have an issue with running the `terraform init` command when setting up the environment variables, sometimes deleting the .terraform folder that is created locally on the folder where you ran the command, will help.

## Installing Opencart

This step considers that that you have mapped your domain to the IPv4 address that we created in step 2 of [Setting up Google Cloud Platform for deployment](#setting-up-google-cloud-platform-for-deployment). I provide documentation on doing this [here](https://docs.google.com/document/d/16RkZ9iCD996bVDlCvf0n7sVgz3dM6uMIsmZ8xaMLvSg/edit?usp=sharing).

1. Accept the License Agreement

First start by reading and accepting the license agreement
![License-Agreement-Image](docs/images/opencart-license.png)

2. Visit the Pre-Installation page and continue.

Click the continue button on the Pre-Installation page if all checks out.
![Pre-Installation-Page](docs/images/opencart-pre-installation.png)

3. Visit the configuration page and input the required fields.

    - For the database connection details, it is necesary that you provide the Username of the opencart mysql user, the opencart user's password and the database name that you provided in Step 4 of [Creating the Packer Base Image on Google Cloud Platform](#creating-the-packer-base-image-on-google-cloud-platform). Do not provide the root user's credentials.
    - Create new credentials for an admin for you site. 

![Configuration-page](docs/images/opencart-configuration.png)

4. This should take you to the installation complete page below

![Installation-complete-page](docs/images/opencart-installation-complete.png)

5. After installation you need to ssh into your VM and delete the install directory, as well as move the storage directory out of the web directory. These are application specific requirements.

    - SSH into the instance from your console
    ![SSH-Image](docs/images/ssh-vm-image.png)
    - Change directory into where opencart files and folders were installed and delete the directory
    ```
    cd /var/www/html
    sudo rm -rf install
    ```
    - Change direcrtory to system and move the storage directory
    ```
    cd /var/www/html/system
    sudo mv storage /var/www/
    ```
6. For the storage directory that you moved in step 5 you also need to change some configurations as per the application instructions

    - Edit the config.php and admin/config.php files as shown below: 
![Storage-Instructions](docs/images/admin-security-requirements.png) 

7. You can now use the application and install data by visiting the admin page on /admin/. Get more documentation from https://www.opencart.com/


