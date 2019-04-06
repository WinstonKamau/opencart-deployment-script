# OpenCart Deployment Script

### Creating the Packer Base Image on Google Cloud Platform

This underlying steps creates our LAMP stack. In the steps below we end up setting up a Linux Virtual Machine, the Apache package, a MySQL database(for this example we use the opensource MySQL version i.e Maria DB) and PHP.

The first step towards setting up the Open Cart website begins by creating a base image. A base image in our case refers to snapshot of a Linux Distribution instance, that contains all the services and packages needed for the Open Cart website to run. 
Currently our Linux Distribution used is Ubuntu version 16.04. The reason Ubuntu was chosen is because it is an open source distribution that has a large community supporting it. It is also freely sold in many cloud platforms making it cost friendly. I needed a distribution that centers on it being easy for me to configure, price friendly and one that I can get access to material to configure it. I chose version 16.04 because it is currently stable as per the chart below.
![Ubuntu Chart](docs/images/ubuntu_release_chart.png?raw=true)
Source: https://www.ubuntu.com/about/release-cycle

The second requirement for our Base Image is the installation of the Apache web server, MySQL database and PHP. All this is configured on the [setup](open-cart-base-image/setup.sh) file. A weakness of our current setup is that the database of the application will be located on the Virtual Machine. This means that the data is ephemeral for every deployment. However the requirements of the task do not require us to meet that scope. 

1. Ensure that:
- You have a [Google Cloud Platform](https://console.cloud.google.com) account ready project to create the base image on.
- That the Compute Engine API has been enabled.
- That you have installed the packer package as per directions from this [link](https://www.packer.io/downloads.html) on your preferred terminal.

2. Clone the Repository

```
mkdir opencart
cd opencart
git clone https://github.com/WinstonKamau/opencart-deployment-script.git
cd opencart-deployment-script
```

3. Setup the service account

You may follow instruction on creating a service account as per this [link](https://cloud.google.com/iam/docs/creating-managing-service-accounts). The most critical part of the service account is the role that the account will be able to perform. Ensure that the service account has at lease admin capabilities of Compute Image User, Compute Instance Admin and Service Account Actor. Download the Service Account JSON key to your machine after giving the Service Account its roles.

Create a folder for the key with the name below. The spelling is necessary to be as is since the packer scripts will be looking for a folder with that name.
```
mkdir account-folder
```
Create a file under the folder with the name below.
```
touch account-folder/account.json
```
Copy the contents of the JSON service key into the account.json file.

3. Setup environment variables.

For environment variables you will need to provide your google cloud project id, the root password you would desire for your root mysql password and the password you will require for your opencart user for the database.
```
export PROJECT_ID={place your google cloud project id here}
export ROOT_PASSWORD={place a root password for the root MySQL user here}
export OPEN_CART_PASSWORD={place a root password for the opencart MYSQL user here}
```

4. Validate and build the base image.

```
cd open-cart-base-image
packer validate packer.json
packer build packer.json
```
After running the commands above ensure that you have a custom image called opencart-base-image on your Google Cloud Platform project.









