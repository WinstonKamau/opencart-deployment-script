#!/usr/bin/env bash

set -o errexit
set -o pipefail
# set -o nounset
# set -o xtrace

get_var() {
  local name="$1"

  curl -s -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/${name}"
}

get_required_variables () {
    export SERVER_ADMIN="$(get_var "serverAdmin")"
    export SERVER_NAME="$(get_var "serverName")"
    export SERVER_ALIAS="$(get_var "serverAlias")"
}

configure_opencart_site() {
cd /tmp && wget https://github.com/opencart/opencart/releases/download/3.0.2.0/3.0.2.0-OpenCart.zip
unzip 3.0.2.0-OpenCart.zip
sudo rm -rf /var/www/html/index.html
sudo mv upload/* /var/www/html/

sudo cp /var/www/html/config-dist.php /var/www/html/config.php
sudo cp /var/www/html/admin/config-dist.php /var/www/html/admin/config.php

sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
}

configure_apache() {
 cat <<EOF | sudo tee -a /etc/apache2/sites-available/opencart.conf
<VirtualHost *:80>
     ServerAdmin ${SERVER_ADMIN}
     DocumentRoot /var/www/html/
     ServerName ${SERVER_NAME}
     ServerAlias ${SERVER_ALIAS}
     <Directory /var/www/html/>
        Options FollowSymlinks
        AllowOverride All
        Order allow,deny
        allow from all
     </Directory>
     ErrorLog ${APACHE_LOG_DIR}/error.log
     CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
sudo a2ensite opencart.conf
sudo a2enmod rewrite
sudo systemctl restart apache2.service
}

main() {
    get_required_variables
    configure_opencart_site
    configure_apache
}

main
