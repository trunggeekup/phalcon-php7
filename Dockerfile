FROM ubuntu:xenial

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y software-properties-common python-software-properties

RUN PACKAGES_TO_INSTALL="sudo curl libc-dev libpcre3-dev pkg-config autoconf gcc make git gnupg2 ca-certificates lsb-release cron php-pear php-dev php-xdebug php7.4-gd php7.4-intl php7.4-xml php7.4-mbstring php7.4-zip php7.4-curl php7.4-fpm nginx supervisor libyaml-dev php7.4-mysql php-phalcon4 libgeoip-dev" && \
    apt-add-repository -y ppa:phalcon/stable && \
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y $PACKAGES_TO_INSTALL

RUN echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    apt-key fingerprint ABF5BD827BD9BF62 - && \
    apt-get update && \
    apt-get install -y nginx

RUN apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/bin/composer

# Install geoip
RUN pecl install geoip-beta

RUN echo -e "\nextension=geoip.so\n" >> /etc/php/7.4/fpm/php.ini && \
    echo -e "\nextension=geoip.so\n" >> /etc/php/7.4/cli/php.ini

# configure NGINX as non-daemon
RUN echo "daemon off;" >> /etc/nginx/nginx.conf 

RUN sed -i -e "s/user\s*nginx;/user www-data;/g" /etc/nginx/nginx.conf 

# configure php-fpm as non-daemon
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf

# clear apt cache and remove unnecessary packages
RUN apt-get autoclean && apt-get -y autoremove

# add a phpinfo script for INFO purposes
RUN echo "<?php phpinfo();" >> /var/www/html/index.php

# NGINX mountable directories for config and logs
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

# NGINX mountable directory for apps
VOLUME ["/var/www"]

# copy config file for Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# backup default default config for NGINX
RUN mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# copy local defualt config file for NGINX
COPY default /etc/nginx/sites-available/default

# php7.4-fpm will not start if this directory does not exist
RUN mkdir /run/php

# NGINX ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord"]
