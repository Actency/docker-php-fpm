# Pull base image.
FROM php:8.2-fpm

# Some definitions
LABEL php-version="8.2-fpm"
LABEL description="Production PHP-FPM image"
LABEL company="SCALE SAFELY"
LABEL author="ZAKARIA KASSRAOUI"

COPY config/php.ini /usr/local/etc/php/

#Fix allow SU
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get clean && apt-get update && apt-get install --fix-missing wget apt-transport-https lsb-release ca-certificates gnupg2 -y
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN cd /tmp && wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

#Install SQL Server packages
ENV ACCEPT_EULA=Y
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list 
RUN apt-get update 
RUN ACCEPT_EULA=Y apt-get -y --no-install-recommends install msodbcsql17 unixodbc-dev mssql-tools18
RUN pecl install sqlsrv
RUN pecl install pdo_sqlsrv
RUN docker-php-ext-enable sqlsrv pdo_sqlsrv

RUN apt-get update && apt-get install apt-file -y && apt-file update 
RUN apt-get clean && apt-get update && apt-cache search php-mysql && apt-get install --fix-missing -y \
  ruby-dev \
  rubygems \
  graphviz \
  sudo \
  libmemcached-tools \
  libmemcached-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  libmcrypt-dev \
  libxml2-dev \
  libxslt1-dev \
  linux-libc-dev \
  libyaml-dev \
  zlib1g-dev \
  libicu-dev \
  libpq-dev \
  bash-completion \
  libldap2-dev \
  libssl-dev \
  libonig-dev \
  npm \
  libzip-dev \
  git \
  postgresql \ 
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install others php modules
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/
RUN docker-php-ext-configure ldap 
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pgsql pdo_pgsql
RUN docker-php-ext-install \
  gd \
  mbstring \
  zip \
  soap \
  opcache \
  calendar \
  intl \
  exif \
  ftp \
  bcmath \
  ldap

# Install YAML extension
RUN pecl install yaml-2.2.2 && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/ext-yaml.ini

# Installation ex
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
	apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Installation of Composer
RUN cd /usr/src && curl -sS http://getcomposer.org/installer | php
RUN cd /usr/src && mv composer.phar /usr/bin/composer

# Installation of drush 11
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
RUN cp -r /usr/local/src/drush/ /usr/local/src/drush11/
RUN cd /usr/local/src/drush11 && git checkout 11.1.0
RUN cd /usr/local/src/drush11 && composer update && composer install
RUN ln -s /usr/local/src/drush11/drush /usr/bin/drush11

# install msmtp
RUN set -x \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y --no-install-recommends msmtp && rm -r /var/lib/apt/lists/*
ADD core/msmtprc.conf /usr/local/etc/msmtprc
ADD core/php-smtp.ini /usr/local/etc/php/conf.d/php-smtp.ini

# Installation of Opcode cache
RUN ( \
  echo "opcache.memory_consumption=128"; \
  echo "opcache.interned_strings_buffer=8"; \
  echo "opcache.max_accelerated_files=20000"; \
  echo "opcache.revalidate_freq=5"; \
  echo "opcache.fast_shutdown=1"; \
  echo "opcache.enable_cli=1"; \
  ) > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Create new web user for apache and grant sudo without password
RUN useradd web -d /var/www -g www-data -s /bin/bash
RUN usermod -aG sudo web
RUN echo 'web ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Add sudo to www-data
RUN echo 'www-data ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# create directory for ssh keys
RUN mkdir /var/www/.ssh/
RUN chown -R www-data:www-data /var/www/
RUN chmod -R 600 /var/www/.ssh/

# Set timezone to Europe/Paris
RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# Add web .bashrc config
COPY config/bashrc /var/www/
RUN mv /var/www/bashrc /var/www/.bashrc
RUN chown www-data:www-data /var/www/.bashrc
RUN echo "source .bashrc" >> /var/www/.profile ;\
    chown www-data:www-data /var/www/.profile

# Connect as web by default
RUN echo 'su web' >> /root/.bashrc

# Set and run a custom entrypoint
COPY core/docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-entrypoint

#Install libwebp-dev and imagemagick
RUN apt-get update && \
   apt-get install --fix-missing -y \
   libwebp-dev \
   imagemagick \
&& rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

RUN docker-php-ext-configure gd --with-jpeg --with-webp
RUN docker-php-ext-install gd

# Upgrade to composer 2
RUN composer self-update --2

#required for log
RUN docker-php-ext-install sockets

VOLUME /var/www/html

ENTRYPOINT ["docker-php-entrypoint"]
EXPOSE 9000
CMD ["php-fpm"]
