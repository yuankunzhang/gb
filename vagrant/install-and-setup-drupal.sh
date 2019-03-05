#!/bin/bash
# install-and-setup-drupal.sh
# ---------------------------
# Install and setup a full functional Drual environment, sudo required.
#
# Usage:
#     sudo ./install-and-setup-drupal.sh
#

set -e
# Uncomment this line for debugging.
#set -x

# Database variables.
DB_ROOT_PASS=changeme
DB_NAME=drupal
DB_USER=drupal
DB_PASS=changeme

# Drupal variables.
DRUPAL_VERSION=8.6.10
DRUPAL_MD5=5aee2dacfb525f146fc28b4535066d1c
DRUPAL_DIR=/var/www/html/drupal

# Site variables.
SITE_NAME="My Site"
ACCOUNT_NAME="Yuankun"
ACCOUNT_PASS="changeme"

prepare_env() {
	echo "Preparing the running environment..."

	export DEBIAN_FRONTEND=noninteractive

	apt-get update
	# Enable Dynamic Swap Space to prevent OOM crashes.
	apt-get install -y swapspace
	# Required by Drupal.
	apt-get install -y zip unzip
}

install_apache() {
	echo "Installing Apache..."

	if type "apache2" > /dev/null 2>&1; then
		echo "Apache2 exists. Environment already provisioned?"
		exit 1
	fi

	# Install the apache2 package, should automatically run after the install.
	apt-get install -y apache2

	# The "rewrite module" is required by Drupal clean URLs.
	# See:
	#   - https://www.drupal.org/docs/8/clean-urls-in-drupal-8/fix-drupal-8-clean-urls-problems
	a2enmod rewrite
}

install_mysql() {
	echo "Installing MySQL..."

	if type "mysql" > /dev/null 2>&1; then
		echo "MySQL exists. Environment already provisioned?"
		exit 1
	fi

	# Disable prompt.
	echo mysql-server mysql-server/root_password password $DB_ROOT_PASS | debconf-set-selections
	echo mysql-server mysql-server/root_password_again password $DB_ROOT_PASS | debconf-set-selections

	# Install the mysql-server package, should automatically run after the install.
	apt-get install -y mysql-server

	# Create database and user, and grant necessary privileges.
	mysql -u root -p$DB_ROOT_PASS <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
SQL
}

install_php() {
	echo "Installing PHP..."

	if type "php" > /dev/null 2>&1; then
		echo "PHP exists. Environment already provisioned?"
		exit 1
	fi

	# Install php and necessary extensions.
	apt-get install -y php php-mysql php-curl php-zip php-cli php-gd \
		php-xml php-mbstring php-simplexml libapache2-mod-php

	# Configure opcache.
	# See:
	#   - https://secure.php.net/manual/en/opcache.installation.php
	cat <<OPCACHE >> /etc/php/7.0/cli/conf.d/10-opcache.ini
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
OPCACHE
}

install_drupal() {
	echo "Installing Drupal..."

	# Sanity check begin.
	if ! type "apache2" > /dev/null 2>&1; then
		echo "Apache not exists. Install Apache first."
		exit 1
	fi

	if ! type "php" > /dev/null 2>&1; then
		echo "PHP not exists. Install PHP first."
		exit 1
	fi

	if ! type "mysql" > /dev/null 2>&1; then
		echo "MySQL not exists. Install MySQL first."
		exit 1
	fi

	if [ ! -d "/var/www/html" ]; then
		echo "Directory /var/www/html not exists, make sure Apache is installed"
		exit 1
	fi

	if [ -d "$DRUPAL_DIR" ]; then
		echo "Drupal directory exists. Environment already provisioned?"
	fi
	# Sanity check end.

	mkdir $DRUPAL_DIR
	cd $DRUPAL_DIR

	# Install Drupal. Also do MD5 sum check.
	# See:
	#   - https://www.drupal.org/project/drupal/releases/
	curl -sSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz
	echo "${DRUPAL_MD5}  drupal.tar.gz" | md5sum -c - > /dev/null
	tar -xz --strip-components=1 -f drupal.tar.gz
	rm drupal.tar.gz
}

setup_drupal() {
	echo "Setting up Drupal..."

	# Sanity check begin.
	if [ ! -d "$DRUPAL_DIR" ]; then
		echo "Directory $DRUPAL_DIR not exists, check previous steps"
		exit
	fi
	# Sanity check end.

	cd $DRUPAL_DIR

	# Install composer.
	curl -sSL https://getcomposer.org/installer | php

	# Install drush.
	# TODO: maybe consider not to run composer as root.
	# See:
	#   - http://docs.drush.org/en/master/install/
	php composer.phar require drush/drush

	# Install new site.
	# See:
	#   - https://drushcommands.com/drush-8x/core/site-install/
	./vendor/bin/drush site-install standard -y \
		--db-url="mysql://$DB_USER:$DB_PASS@localhost:3306/$DB_NAME" \
		--site-name="$SITE_NAME" \
		--account-name="$ACCOUNT_NAME" \
		--account-pass="$ACCOUNT_PASS"

	# Disable CSS & JS aggregation.
	# See:
	#   - https://www.drupal.org/forum/support/installing-drupal/2015-11-24/no-css-loading-on-fresh-install-of-drupal-800
	#   - https://drupal.stackexchange.com/questions/221268/how-to-disable-aggregation-from-either-drush-or-phpmyadmin
	./vendor/bin/drush -y config-set system.performance css.preprocess 0
	./vendor/bin/drush -y config-set system.performance js.preprocess 0

	# Change site owner.
	chown -R www-data:www-data $DRUPAL_DIR

	# Add Apache site config.
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

	# Disable the default site.
	# WARNING: Don't do this in production.
	a2dissite 000-default.conf

    a2ensite site.conf
	apache2ctl restart
}

echo "######################################################"
echo "Installation will start now, please be patient      :)"
echo "######################################################"

prepare_env
install_apache
install_mysql
install_php
install_drupal
setup_drupal

echo "######################################################"
echo "Installation completed, visit http://localhost:8080 :)"
echo "######################################################"
