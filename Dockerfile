# Pull base image.
FROM actency/docker-php-fpm:7.3

# Some definitions
LABEL php-version="7.3"
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

RUN apt-get clean && apt-get update && apt-cache search php-mysql && apt-get install --fix-missing -y \
  git \
  vim \
  nano \
  zip \
  wget \
  bash-completion \
  htop \
  npm \
  && rm -rf /var/lib/apt/lists/*

# postgresql-client-9.5
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list && apt-get update && apt-get install -y postgresql-client-9.5

# Install sass and gem dependency
RUN apt-get install --fix-missing automake ruby2.5-dev libtool -y

# SASS and Compass installation
RUN gem install sass -v 3.7.3 ;\
    gem install compass;

# Installation ex
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
	apt-get update && apt-get install -y nodejs && \
	npm install npm@latest -g

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
RUN ln -s ~/.composer/vendor/bin/phpcs /usr/local/bin
RUN ln -s ~/.composer/vendor/bin/phpcbf /usr/local/bin
RUN phpcs --config-set installed_paths ~/.composer/vendor/drupal/coder/coder_sniffer
