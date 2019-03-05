#!/bin/bash

set -e

DRUPAL_DIR=/var/www/html

setup_drupal() {
    cd $DRUPAL_DIR

	php composer.phar require drush/drush

	./vendor/bin/drush site-install standard -y \
		--db-url="mysql://$DB_USER:$DB_PASS@$DB_HOST:3306/$DB_NAME" \
		--site-name="$SITE_NAME" \
		--account-name="$ACCOUNT_NAME" \
		--account-pass="$ACCOUNT_PASS"

    ./vendor/bin/drush -y config-set system.performance css.preprocess 0
	./vendor/bin/drush -y config-set system.performance js.preprocess 0

	# Change site owner.
	chown -R www-data:www-data $DRUPAL_DIR
}

# Wait for MySQL connection.
connected=false
for _ in $(seq 1 10); do
	if nc -z "$DB_HOST" 3306; then
		connected=true
		break
	fi
	sleep 6
done

if [ "$connected" = false ]; then
    echo "Unable to connect to $DB_HOST, quit"
    exit 1
fi

if [ ! -f "$DRUPAL_DIR/vendor/bin/drush" ]; then
	echo "####################################################"
	echo "This is the first time you run this image, the setup"
	echo "process will take a while, please be patient      :)"
	echo "####################################################"
    setup_drupal
fi

apache2-foreground
