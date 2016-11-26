FROM knowledgearcdotorg/phpfpm
MAINTAINER development@knowledgearc.com

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update

RUN apt-get upgrade -y && \
    apt-get install -y curl php-curl php-gd php-geoip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/piwik.tar.gz "https://builds.piwik.org/piwik.tar.gz" && \
    curl -fsSL -o /tmp/piwik.tar.gz.asc "https://builds.piwik.org/piwik.tar.gz.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver keys.gnupg.net --recv-keys 814E346FA01A20DBB04B6807B5DBD5925590A237 && \
    gpg --batch --verify /tmp/piwik.tar.gz.asc /tmp/piwik.tar.gz && \
    rm -r "$GNUPGHOME" /tmp/piwik.tar.gz.asc && \
    tar -xzf /tmp/piwik.tar.gz -C /var/www/ && \
    rm /tmp/piwik.tar.gz

RUN curl -fsSL -o /var/www/piwik/misc/GeoIPCity.dat.gz "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz" && \
    gunzip /var/www/piwik/misc/GeoIPCity.dat.gz

RUN echo 'geoip.custom_directory=/var/www/piwik/misc' \
>> /etc/php/7.0/mods-available/geoip.ini

RUN chown www-data /var/www/piwik

VOLUME /var/www/piwik
