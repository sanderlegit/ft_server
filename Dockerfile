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
		sendmail \
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
RUN 	service mysql start && \
		mysql -u root -e "CREATE DATABASE wordpress;" && \
		mysql -u root -e "GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'admin' WITH GRANT OPTION;" && \
		mysql -u root -e "FLUSH PRIVILEGES;"

#Add wp application to bin
COPY	/srcs/wp-cli.phar /usr/local/bin/wp
RUN		chmod a+rwx,g-w,o-w /usr/local/bin/wp
RUN		wp cli update

#Adding a super-user to control wp installation
RUN		adduser --disabled-password --gecos "" admin
RUN		sudo adduser admin sudo

#Creating phpmyadmin configuration database
RUN 	service mysql start && \
		mysql < /var/www/html/wordpress/phpmyadmin/sql/create_tables.sql && \
#Downloading wp and configuring database access
		sudo -u admin -i wp core download && \
		sudo -u admin -i wp core config \
			--dbname=wordpress --dbuser=admin --dbpass=admin && \
		sudo -u admin -i wp core install --url=https://localhost/ --title="averheij's ft_server" \
			--admin_user=admin --admin_password=admin --admin_email=admin@gmail.com && \
		mv /home/admin/* /var/www/html/wordpress

#Giving nginx's user-group rights over page files
RUN		chown -R www-data:www-data /var/www/html/*

#Copying certs
COPY	/srcs/localhost.cert /etc/ssl/certs/server.cert
COPY	/srcs/localhost.key /etc/ssl/private/server.key

#Copying nginx confs
COPY	/srcs/server.conf /etc/nginx/sites-available/server.conf
RUN		ln -s /etc/nginx/sites-available/server.conf /etc/nginx/sites-enabled/server.conf

#Removing deault server
RUN		rm -rf /etc/nginx/sites-enabled/default

#Copying and allowing autoindex controller
COPY	/srcs/set_autoindex_internal.sh ./
RUN		chmod u+x ./set_autoindex_internal.sh

#Increase the maximum upload size in the php.ini
RUN		sed -i '/upload_max_filesize/c upload_max_filesize = 20M' /etc/php/7.3/fpm/php.ini
RUN		sed -i '/post_max_size/c post_max_size = 21M' /etc/php/7.3/fpm/php.ini

#Commands to initialize container
CMD	service nginx start && \
	service mysql start && \
	service php7.3-fpm start && \
	echo "127.0.0.1 localhost localhost.localdomain $(hostname)" >> /etc/hosts && \
	service sendmail start && \
	bash

#test all wordpress normal features
	#file upload
	#comment
	#blog post
