FROM phusion/baseimage:0.9.18
MAINTAINER Marcos Chavarría Teijeiro <chavarria1991@gmail.com>
#Based on the work of Matt Webb "mattrw89@gmail.com"

#Set Language
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen $LANG; echo "LANG=\"${LANG}\"" > /etc/default/locale; dpkg-reconfigure locales

# Upgrade system
RUN apt-get update  && \
    apt-get upgrade -y

# Install basic packages
RUN apt-get install -y wget apt-transport-https software-properties-common curl unzip

# Install Varnish
RUN wget -O - https://repo.varnish-cache.org/ubuntu/GPG-key.txt | apt-key add -  && \
    echo deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.0 >> /etc/apt/sources.list.d/varnish-cache.list  && \
    apt-get update && apt-get install -y varnish

# Install HHVM
RUN wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add - && \
    echo deb http://dl.hhvm.com/ubuntu trusty main | tee /etc/apt/sources.list.d/hhvm.list && \
    apt-get update  && \
    apt-get install -y hhvm

# Install NGINX
RUN echo deb http://archive.ubuntu.com/ubuntu trusty main universe | tee /etc/apt/sources.list  && \
    add-apt-repository -y ppa:nginx/stable  && \
    apt-get update  && \
    apt-get install -y nginx

# Wordpress Requirements
RUN apt-get update && \
    apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl

# Upgrade to PHP 5.6
RUN echo "deb http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu trusty main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-key E5267A6C  && \
    apt-get update && \
    apt-get -y install php5 php5-gd php5-ldap php5-sqlite php5-pgsql php-pear php5-mysql php5-mcrypt php5-xmlrpc php5-fpm

# Create user wordpress
RUN adduser --system --home /home/wordpress --group --disabled-login --disabled-password wordpress

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  && \
    mv wp-cli.phar /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Install HHVM Fast CGI
RUN /usr/share/hhvm/install_fastcgi.sh

# Configure NGINX
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf

# Configure varnish
COPY config/varnish/varnish4-wordpress /etc/varnish/default.vcl

# Copy entrypoint and wp config files
COPY start.sh /home/wordpress/entrypoint.sh
COPY config/wordpress/enviroment /home/wordpress/.env
COPY config/wordpress/appsettings.yml /home/wordpress/appsettings.yml
RUN chown wordpress:wordpress /home/wordpress/.env /home/wordpress/appsettings.yml /home/wordpress/entrypoint.sh && \
    chmod +x /home/wordpress/entrypoint.sh

# Create site and logs directories
RUN mkdir /home/wordpress/site /home/wordpress/logs
RUN chown wordpress:wordpress /home/wordpress/site /home/wordpress/logs
VOLUME /home/wordpress/site
VOLUME /home/wordpress/logs

# Install wp-bootstrap wp-cli package
USER wordpress
RUN wp package install eriktorsner/wp-bootstrap

EXPOSE 80

ENTRYPOINT ["/home/wordpress/entrypoint.sh"]
