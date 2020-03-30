# Pull base image.
FROM php:7.3-fpm

# Some definitions
LABEL php-version="7.3"
LABEL description="Production PHP-FPM image"
LABEL company="Actency"
LABEL author="Hakim Rachidi"

COPY config/php.ini /usr/local/etc/php/

RUN apt-get clean && apt-get update && apt-get install --fix-missing wget apt-transport-https lsb-release ca-certificates gnupg2 -y
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN cd /tmp && wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

RUN apt-get clean && apt-get update && apt-cache search php-mysql && apt-get install --fix-missing -y \
  ruby-dev \
  rubygems \
  imagemagick \
  graphviz \
  sudo \
  memcached \
  libmemcached-tools \
  libmemcached-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  libmcrypt-dev \
  libxml2-dev \
  libxslt1-dev \
  mariadb-client \
  linux-libc-dev \
  libyaml-dev \
  zlib1g-dev \
  libicu-dev \
  libpq-dev \
  bash-completion \
  htop \
  libldap2-dev \
  libssl-dev \
  npm \
  libzip-dev \
  && rm -rf /var/lib/apt/lists/*

# Install memcached 3.1.5 for PHP 7.3
RUN pecl install memcached-3.1.5 \
    && docker-php-ext-enable memcached

# Install others php modules
COPY docker-php-ext-install /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ext-install
RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/include/
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install \
  gd \
  mbstring \
  zip \
  soap \
  pdo_mysql \
  mysqli \
  opcache \
  calendar \
  intl \
  exif \
  pgsql \
  pdo_pgsql \
  ftp \
  bcmath \
  ldap

RUN pecl install mcrypt-1.0.1 && \
    docker-php-ext-enable mcrypt

# Create new web user for apache and grant sudo without password
RUN useradd web -d /var/www -g www-data -s /bin/bash
RUN usermod -aG sudo web
RUN echo 'web ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Add sudo to www-data
RUN echo 'www-data ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install YAML extension
RUN pecl install yaml-2.0.2 && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/ext-yaml.ini

# Install APCu extension
RUN pecl install apcu-5.1.8

COPY core/memcached.conf /etc/memcached.conf

# Installation ex
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
	apt-get update && apt-get install -y nodejs && \
	npm install npm@latest -g

# Installation of drush 8 & 9
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
RUN cp -r /usr/local/src/drush/ /usr/local/src/drush8/
RUN cp -r /usr/local/src/drush/ /usr/local/src/drush9/
RUN cd /usr/local/src/drush8 && git checkout -f 8.1.0
RUN cd /usr/local/src/drush8 && composer update && composer install
RUN ln -s /usr/local/src/drush8/drush /usr/bin/drush8
RUN cd /usr/local/src/drush9 && git checkout 9.1.0
RUN cd /usr/local/src/drush9 && composer update && composer install
RUN ln -s /usr/local/src/drush9/drush /usr/bin/drush9

# install msmtp
RUN set -x \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y --no-install-recommends msmtp && rm -r /var/lib/apt/lists/*
ADD core/msmtprc.conf /usr/local/etc/msmtprc
ADD core/php-smtp.ini /usr/local/etc/php/conf.d/php-smtp.ini

# Installation of APCu cache
RUN ( \
  echo "extension=apcu.so"; \
  echo "apc.enabled=1"; \
  ) > /usr/local/etc/php/conf.d/ext-apcu.ini

# Installation of Opcode cache
RUN ( \
  echo "opcache.memory_consumption=128"; \
  echo "opcache.interned_strings_buffer=8"; \
  echo "opcache.max_accelerated_files=20000"; \
  echo "opcache.revalidate_freq=5"; \
  echo "opcache.fast_shutdown=1"; \
  echo "opcache.enable_cli=1"; \
  ) > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Install Drupal Console for Drupal 8
RUN curl https://drupalconsole.com/installer -L -o drupal.phar && mv drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal

# Install WKHTMLTOPDF
RUN apt-get update && apt-get remove -y libqt4-dev qt4-dev-tools wkhtmltopdf && apt-get autoremove -y
RUN apt-get install openssl build-essential libssl-dev libxrender-dev git-core libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig -y
RUN mkdir /var/wkhtmltopdf
RUN cd /var/wkhtmltopdf && wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && tar xf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
RUN cp /var/wkhtmltopdf/wkhtmltox/bin/wkhtmltopdf /bin/wkhtmltopdf && cp /var/wkhtmltopdf/wkhtmltox/bin/wkhtmltoimage /bin/wkhtmltoimage
RUN chown -R www-data:www-data /var/wkhtmltopdf
RUN chmod +x /bin/wkhtmltopdf && chmod +x /bin/wkhtmltoimage

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

# Set and run a custom entrypoint
COPY core/docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-entrypoint

VOLUME /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 9000
CMD ["php-fpm"]