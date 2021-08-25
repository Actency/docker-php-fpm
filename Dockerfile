# Pull base image.
FROM actency/docker-php-fpm:7.4

# Some definitions
LABEL php-version="7.4"
LABEL description="Developer PHP-FPM image"
LABEL company="Actency"
LABEL author="Hakim Rachidi"

RUN docker-php-ext-install mysqli && docker-php-ext-install pdo_mysql

RUN apt-get clean && apt-get update && apt-get install --fix-missing wget apt-transport-https lsb-release ca-certificates gnupg2 -y
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN cd /tmp && wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

RUN apt-get clean && apt-get update && apt-get install --fix-missing -y \
  git \
  vim \
  nano \
  wget \
  bash-completion \
  htop \
  npm \
  postgresql-client \
  automake \
  ruby2.7-dev \
  libtool \
  && rm -rf /var/lib/apt/lists/*

# SASS and Compass installation
RUN gem install sass -v 3.7.3 ;\
    gem install compass;

# Installation of LESS
RUN npm install -g less && npm install -g less-plugin-clean-css

# Installation of Grunt
RUN npm install -g grunt-cli

# Installation of Gulp
RUN npm install -g gulp

# Installation of Bower
RUN npm install -g bower

# Install xdebug.
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

RUN touch /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo 'xdebug.remote_autostart=0' >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo 'xdebug.remote_connect_back=0' >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo 'xdebug.remote_port=9000' >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo 'xdebug.remote_log=/tmp/php7-xdebug.log' >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo 'xdebug.remote_host=docker_host' >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo 'xdebug.idekey=PHPSTORM' >> /usr/local/etc/php/conf.d/xdebug.ini

# Installation of PHP_CodeSniffer with Drupal coding standards.
# See https://www.drupal.org/node/1419988#coder-composer
RUN composer global require drupal/coder
RUN ln -s ~/.config/composer/vendor/bin/phpcs /usr/local/bin
RUN ln -s ~/.config/composer/vendor/bin/phpcbf /usr/local/bin
RUN phpcs --config-set installed_paths ~/.composer/vendor/drupal/coder/coder_sniffer

# Add web .bashrc config
COPY config/bashrc /var/www/.bashrc
RUN chown www-data:www-data /var/www/.bashrc

# Set and run a custom entrypoint
COPY core/docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-entrypoint

# Copy php config
COPY config/php.ini /usr/local/etc/php/
