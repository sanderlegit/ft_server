CURR_VAL=$(cat /etc/nginx/sites-available/server.conf | grep autoindex)

if [ -n "$1" ] 
then
	if [ $1 == "on" ] || [ $1 == "off" ]
	then
		if [[ $CURR_VAL != *$1* ]]
		then
			sed -i "/autoindex/c autoindex $1;" /etc/nginx/sites-available/server.conf
			sed -i "s/autoindex/\t\tautoindex/g" /etc/nginx/sites-available/server.conf
			echo "Value set"
			service nginx restart
		else
			echo "Value already set"
		fi
	else
		echo "Possible options are [on, off]"
	fi
else
	echo "Please supply a value"
fi
