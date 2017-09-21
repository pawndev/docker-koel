FROM php:7.1-apache

MAINTAINER Coquelet Christophe <coquelet.c@gmail.com>

RUN apt-get update \
    && apt-get -y -q install git curl build-essential\
    && docker-php-ext-install pdo_mysql mbstring\
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt-get install -y -q nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && npm install -g yarn@0.27.5

RUN apt-get update && apt-get install inotify-tools -yq

## php conf

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    libbz2-dev \
    libc-client2007e-dev \
    libcurl4-gnutls-dev \
    libedit-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libkrb5-dev \
    libmcrypt-dev \
    libpng12-dev \
    libpq-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxslt1-dev \
    php-pear

RUN mkdir -p /usr/kerberos
RUN ln -s /usr/lib/x86_64-linux-gnu /usr/kerberos/lib

RUN docker-php-ext-install -j$(nproc) \
    bz2 \
    curl \
    exif \
    iconv \
    intl \
    json \
    mbstring \
    mcrypt \
    mysqli \
    opcache \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pgsql \
    readline \
    soap \
    xml \
    xmlrpc \
    xsl \
    zip

RUN docker-php-ext-configure imap --with-kerberos=/usr/kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) imap

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

WORKDIR /app

## koel

RUN groupadd -r koel -g 1000 \
    && useradd -u 1000 -r -g koel -d /app -s /sbin/nologin -c "Docker image user" koel\ 
    && mkdir -p /app \
    && chown -R koel:koel /app

USER koel

RUN git clone https://github.com/phanan/koel \
    && cd koel \
    && git checkout v3.6.2 \
    && composer install

WORKDIR /app/koel

RUN yarn

VOLUME /music

COPY env .env
COPY run.sh run.sh
COPY watcher.sh watcher.sh

USER root

RUN chmod +x watcher.sh

ADD 000-koel.conf /etc/apache2/sites-enabled/000-koel.conf

RUN chown -R koel:koel /app \
    && sed -i 's/Listen 80/Listen 8000/' /etc/apache2/apache2.conf \
    && usermod -aG koel www-data \
    && a2enconf charset \
    && a2enmod rewrite

EXPOSE 8000

ENTRYPOINT ["/app/koel/./run.sh"]