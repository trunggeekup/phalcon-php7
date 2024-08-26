FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt install -y --no-install-recommends apt-utils && apt install -y software-properties-common

RUN PACKAGES_TO_INSTALL="curl unzip libc-dev libpcre3-dev pkg-config autoconf gcc make git gnupg2 ca-certificates lsb-release cron php7.4-dev php7.4-gd php7.4-intl php7.4-xml php-xml php7.4-mbstring php7.4-zip php7.4-curl php7.4-fpm supervisor libyaml-dev php7.4-mysql libgeoip-dev php7.4-redis ubuntu-keyring" && \
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && \
    apt update && \
    apt install -y $PACKAGES_TO_INSTALL

# Install nginx
RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list && \
    echo "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99-nginx && \
    apt update && \
    apt install -y nginx

# config default version php using php7.4
RUN update-alternatives --set php /usr/bin/php7.4

# clear apt cache and remove unnecessary packages
RUN apt update && apt upgrade -y && \
    apt autoremove -y && \
    apt clean && \
    apt autoclean

RUN pecl channel-update pecl.php.net
RUN pecl install psr

RUN echo -e "\nextension=psr.so\n" >> /etc/php/7.4/fpm/php.ini && \
    echo -e "\nextension=psr.so\n" >> /etc/php/7.4/cli/php.ini

RUN pear update-channels

RUN pecl channel-update pecl.php.net

RUN pecl install phalcon-4.1.2

RUN echo -e "\nextension=phalcon.so\n" >> /etc/php/7.4/fpm/php.ini && \
    echo -e "\nextension=phalcon.so\n" >> /etc/php/7.4/cli/php.ini

# # Install geoip
RUN pecl install geoip-beta
RUN echo -e "\nextension=geoip.so\n" >> /etc/php/7.4/fpm/php.ini && \
    echo -e "\nextension=geoip.so\n" >> /etc/php/7.4/cli/php.ini

# Install OpenSSL
ENV OPENSSL_VERSION=3.3.1
ENV OPENSSL_CHECKSUM=777cd596284c883375a2a7a11bf5d2786fc5413255efab20c50d6ffe6d020b7e

RUN curl -fsSL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o /tmp/openssl-${OPENSSL_VERSION}.tar.gz && \
    echo "${OPENSSL_CHECKSUM}  /tmp/openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzvf /tmp/openssl-${OPENSSL_VERSION}.tar.gz -C /tmp && \
    cd /tmp/openssl-${OPENSSL_VERSION} && ./config && make install && \
    rm -rf /tmp/openssl* && \
    rm -rf /usr/local/ssl/certs && \
    ln -s /etc/ssl/certs /usr/local/ssl/


ENV PATH=$PATH:/usr/local/ssl/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

RUN curl http://getcomposer.org/installer --output composer-setup.php && \
    php composer-setup.php  && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/bin/composer

# configure NGINX as non-daemon
COPY nginx.conf /etc/nginx/nginx.conf

# copy local defualt config file for NGINX
COPY default /etc/nginx/sites-available/default

# Remove default nginx config file
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak

# copy config file for Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# configure php-fpm as non-daemon
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf

# php7.4-fpm will not start if this directory does not exist
RUN mkdir /run/php

# add a phpinfo script for INFO purposes
RUN mkdir -p /var/www/html && echo "<?php phpinfo();" >> /var/www/html/index.php

# NGINX mountable directories for config and logs
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

# NGINX mountable directory for apps
VOLUME ["/var/www"]

# NGINX ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord"]