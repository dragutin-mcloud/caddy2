FROM docker.io/golang:1.13.1-alpine3.10
LABEL maintainer "Abiola Ibrahim <abiola89@gmail.com>"

# PHP www-user UID and GID
ARG PUID="1000"
ARG PGID="1000"

RUN apk add --no-cache \
  ca-certificates \
  curl \
  git \
  mailcap \
  openssh-client \
  php7-fpm \
  tar \
  tzdata

# Essential PHP Extensions
RUN apk add --no-cache \
  php7-bcmath \
  php7-ctype \
  php7-curl \
  php7-dom \
  php7-exif \
  php7-fileinfo \
  php7-gd \
  php7-iconv \
  php7-json \
  php7-mbstring \
  php7-mysqli \
  php7-opcache \
  php7-openssl \
  php7-pdo \
  php7-pdo_mysql \
  php7-pdo_pgsql \
  php7-pdo_sqlite \
  php7-pgsql \
  php7-phar \
  php7-session \
  php7-simplexml \
  php7-sqlite3 \
  php7-tokenizer \
  php7-xml \
  php7-xmlreader \
  php7-xmlwriter \
  php7-zip

# Symlink php7 to php
RUN ln -sf /usr/bin/php7 /usr/bin/php

# Symlink php-fpm7 to php-fpm
RUN ln -sf /usr/bin/php-fpm7 /usr/bin/php-fpm

# Add a PHP www-user instead of nobody
RUN addgroup -g ${PGID} www-user && \
  adduser -D -H -u ${PUID} -G www-user www-user && \
  sed -i "s|^user = .*|user = www-user|g" /etc/php7/php-fpm.d/www.conf && \
  sed -i "s|^group = .*|group = www-user|g" /etc/php7/php-fpm.d/www.conf

# Composer
RUN curl --silent --show-error --fail --location \
  --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" \
  "https://getcomposer.org/installer" \
  | php -- --install-dir=/usr/bin --filename=composer

# Allow environment variable access
RUN echo "clear_env = no" >> /etc/php7/php-fpm.conf

# Install Caddy
RUN cd /root && \
  git clone https://github.com/caddyserver/caddy.git -b v2 && \
  cd caddy/cmd/caddy && \
  go build && \
  go install

RUN mv /go/bin/caddy /usr/bin/caddy
RUN rm -rf /root/caddy > /dev/null

COPY Caddyfile /etc/caddy/Caddyfile
COPY index.php /var/www/html/index.php

# Validate install
RUN /usr/bin/caddy version
RUN /usr/bin/caddy list-modules

EXPOSE 80 443 2019
VOLUME /var/www/html

RUN apk add --update supervisor && rm  -rf /tmp/* /var/cache/apk/*
ADD supervisord.conf /etc/
RUN apk add bash net-tools

CMD ["/usr/bin/supervisord","--configuration","/etc/supervisord.conf"]
