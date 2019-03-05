FROM php:7.3.2-apache

LABEL maintainer="Yuankun Zhang <hi@yuankun.me>"

ARG DRUPAL_VERSION=8.6.10
ARG DRUPAL_MD5=5aee2dacfb525f146fc28b4535066d1c

WORKDIR /var/www/html

ADD site.conf /etc/apache2/sites-available/

RUN apt-get update && apt-get install -y curl libpng-dev \
    # install required php extensions
    && docker-php-ext-install gd opcache pdo_mysql \
    # configure opcache, refer to https://secure.php.net/manual/en/opcache.installation.php
    && echo '\n\
opcache.memory_consumption=128\n\
opcache.interned_strings_buffer=8\n\
opcache.max_accelerated_files=4000\n\
opcache.revalidate_freq=60\n\
opcache.fast_shutdown=1\n\
opcache.enable_cli=1\n\
' > /usr/local/etc/php/conf.d/opcache.ini \
    # download and install drupal
    && curl -sSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz \
    && echo "${DRUPAL_MD5}  drupal.tar.gz" | md5sum -c - >/dev/null \
    && tar -xz --strip-components=1 -f drupal.tar.gz \
    && chown -R www-data:www-data sites modules themes \
    # enable site configuration
    && ln -s /etc/apache2/sites-available/site.conf /etc/apache2/sites-enabled/site.conf \
    # enable rewrite module, required by clean urls
    && ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load \
    # clean up
    && rm drupal.tar.gz \
    && rm -rf /var/lib/apt/lists/*
