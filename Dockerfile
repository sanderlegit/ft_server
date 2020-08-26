# Container OS
FROM debian:buster

#Expose port 80 for HTTP, 443 for HTTPS
EXPOSE 80 443
WORKDIR /root/

#Installing packages
RUN apt-get update && \
	apt-get -y upgrade && \
	apt-get install -y \
		mariadb-server \
		mariadb-client \
		unzip \
		wget \
		php \
		sudo \
		#sendmail \
		php-cli \
		php-cgi \
		php7.3-zip \
		php-json \
		php-mbstring \
		php-fpm \
		php-mysql \
		#libnss3-tools \
		nginx

#Setting up phpmyadmin
RUN		mkdir -p /var/www/html/wordpress
COPY	/srcs/phpMyAdmin-4.9+snapshot-all-languages.tar.gz /tmp/
RUN		tar -zxvf /tmp/phpMyAdmin-4.9+snapshot-all-languages.tar.gz -C /tmp
RUN		cp -r /tmp/phpMyAdmin-4.9+snapshot-all-languages/. \
		/var/www/html/wordpress/phpmyadmin
RUN		chmod a+rwx,g-w,o-w /var/www/html/wordpress/phpmyadmin/
COPY	/srcs/config.inc.php /var/www/html/wordpress/phpmyadmin

#Create wordpress database
RUN service mysql start && \
	mysql -u root -e "CREATE DATABASE wordpress;" && \
	mysql -u root -e "GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'admin' WITH GRANT OPTION;" && \
	mysql -u root -e "FLUSH PRIVILEGES;"

#Creating phpmyadmin configuration storage
RUN service mysql start && \
	mysql < /var/www/html/wordpress/phpmyadmin/sql/create_tables.sql

#Giving nginx user group rights over page files
RUN		chown -R www-data:www-data /var/www/html/*

#Copying nginx files
COPY	/srcs/localhost.cert /etc/ssl/certs/server.cert
COPY	/srcs/localhost.key /etc/ssl/private/server.key
COPY	/srcs/server.conf /etc/nginx/sites-available/server.conf
RUN		ln -s /etc/nginx/sites-available/server.conf /etc/nginx/sites-enabled/server.conf
RUN		rm -rf /etc/nginx/sites-enabled/default

#Copying and allowing autoindex controller
#COPY	/srcs/set_autoindex.sh /
#RUN		chmod +x /set_autoindex.sh

#Commands to initialize container
CMD     service mysql start && \
		service php7.3-fpm start && \
		service nginx start && \
		#service sendmail start && \
        bash
	#Keep container running
		#tail -f /dev/null
