#!/bin/bash
# install-and-setup-drupal.sh
# ---------------------------
# Install and setup a full functional Drual environment, sudo required.

set -e

DB_ROOT_PASS=changeme
DB_NAME=drupal
DB_USER=drupal
DB_PASS=drupal

install_apache() {
	echo "Installing Apache..."
	apt install -y apache2
}

install_mysql() {
	echo "Installing MySQL..."

	# no prompt
	echo mysql-server mysql-server/root_password password $DB_ROOT_PASS | debconf-set-selections
	echo mysql-server mysql-server/root_password_again password $DB_ROOT_PASS | debconf-set-selections

	apt install -y mysql-server

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
	apt install -y php php-mysql libapache2-mod-php php-cli
}

install_drupal() {
	echo "Installing Drupal..."
}

#apt update
#install_apache
install_mysql
#install_php
#install_drupal
