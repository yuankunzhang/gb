#!/bin/bash
# install-and-setup-drupal.sh
# ---------------------------
# Install and setup a full functional Drual environment, sudo required.
#
# Usage:
#     sudo ./install-and-setup-drupal.sh
#

set -e
#set -x

DB_ROOT_PASS=changeme
DB_NAME=drupal
DB_USER=drupal
DB_PASS=changeme

DRUPAL_VERSION=8.6.10
DRUPAL_MD5=5aee2dacfb525f146fc28b4535066d1c
DRUPAL_DIR=/var/www/html/drupal

SITE_NAME="My Site"
SITE_MAIL="site@yuankun.me"
SITE_ADMIN_NAME="Yuankun"
SITE_ADMIN_MAIL="admin@yuankun.me"
SITE_ADMIN_PASS="changeme"

prepare_env() {
	echo "Preparing the environment..."
	apt-get update
	# Enable Dynamic Swap Space to prevent OOM crashes
	apt-get install -y swapspace
	apt-get install -y zip unzip
}

install_apache() {
	echo "Installing Apache..."
	apt-get install -y apache2

	# required by drupal clean urls
	ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load
}

install_mysql() {
	echo "Installing MySQL..."

	# disable prompt
	echo mysql-server mysql-server/root_password password $DB_ROOT_PASS | debconf-set-selections
	echo mysql-server mysql-server/root_password_again password $DB_ROOT_PASS | debconf-set-selections

	apt-get install -y mysql-server

	# setup database and user
	mysql -u root -p$DB_ROOT_PASS <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
SQL
}

install_php() {
	echo "Installing PHP..."
	apt-get install -y php php-mysql php-curl php-zip libapache2-mod-php php-cli php-xml php-mbstring php-gd php-simplexml
}

install_drupal() {
	echo "Installing Drupal..."

	if [ ! -d "/var/www/html" ]; then
		echo "Directory /var/www/html not exists, make sure Apache is installed"
		exit
	fi

	if [ ! -d "$DRUPAL_DIR" ]; then
		mkdir $DRUPAL_DIR
	fi
	cd $DRUPAL_DIR

	# install drupal
	curl -sSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz
	echo "${DRUPAL_MD5}  drupal.tar.gz" | md5sum -c - >/dev/null
	tar -xz --strip-components=1 -f drupal.tar.gz
	rm drupal.tar.gz

	# change owner
	chown -R www-data:www-data sites modules themes

	# config apache
	cat << EOF > /etc/apache2/sites-available/site.conf
ServerName localhost

<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/drupal

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/drupal/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
	ln -s /etc/apache2/sites-available/site.conf /etc/apache2/sites-enabled/site.conf
	rm /etc/apache2/sites-enabled/000-default.conf
	apache2ctl restart
}

setup_drupal() {
	echo "Setting up Drupal..."

	if [ ! -d "$DRUPAL_DIR" ]; then
		echo "Directory $DRUPAL_DIR not exists, check previous steps"
		exit
	fi
	cd $DRUPAL_DIR

	# install composer
	curl -sSL https://getcomposer.org/installer | php

	# install drupal-console
	php composer.phar require drupal/console:~1.0 \
		--prefer-dist \
		--optimize-autoloader

	# setup site
	./vendor/bin/drupal site:install standard \
		--langcode="en" \
		--db-type="mysql" \
		--db-host="127.0.0.1" \
		--db-name="$DB_NAME" \
		--db-user="${DB_USER}" \
		--db-pass="${DB_PASS}" \
		--db-port="3306" \
		--db-prefix="dp_" \
		--site-name="$SITE_NAME" \
		--site-mail="$SITE_MAIL" \
		--account-name="$SITE_ADMIN_NAME" \
		--account-mail="$SITE_ADMIN_MAIL" \
		--account-pass="$SITE_ADMIN_PASS"
}

prepare_env
install_apache
install_mysql
install_php
install_drupal
#setup_drupal
