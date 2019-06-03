#!/usr/bin/env bash

set -o errexit
set -o pipefail
# set -o nounset
# set -o xtrace

install_apache2() {
    sudo apt-get -y upgrade
    sudo apt-get -y update
    sudo apt-get install -y apache2
    sudo sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/apache2/apache2.conf
    sudo apt-get install -y unzip
    sudo systemctl stop apache2.service
    sudo systemctl start apache2.service
    sudo systemctl enable apache2.service
}

install_mariadb() {
    sudo apt-get install -y mariadb-server mariadb-client
    sudo systemctl stop mysql.service
    sudo systemctl start mysql.service
    sudo systemctl enable mysql.service
}

setup_mysql() {
sudo mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('$ROOT_PASSWORD') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

sudo mysql -u root <<-EOF
CREATE DATABASE ${OPEN_CART_DATABASE};
CREATE USER '${OPEN_CART_USER}'@'localhost' IDENTIFIED BY '$OPEN_CART_PASSWORD';
GRANT ALL ON opencart.* TO '${OPEN_CART_USER}'@'localhost' IDENTIFIED BY '$OPEN_CART_PASSWORD' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

sudo systemctl restart mysql.service
}

setup_php_modules() {
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt-get -y update
    sudo apt install -y php7.1 libapache2-mod-php7.1 php7.1-common php7.1-mbstring php7.1-xmlrpc php7.1-soap php7.1-gd php7.1-xml php7.1-intl php7.1-mysql php7.1-cli php7.1-mcrypt php7.1-ldap php7.1-zip php7.1-curl
}

main () {
    install_apache2
    install_mariadb
    setup_mysql
    setup_php_modules
}

main "$@"
