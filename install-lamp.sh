#!/bin/bash
echo "============================================"
echo "Install Lemp stack with bash"
echo "============================================"

echo "Add repo PPA for PHP 7.4"
sudo apt install software-properties-common 
sudo add-apt-repository ppa:ondrej/php

echo "update"
apt-get udpate -y

echo "Install apache2 web server"
apt install apache2 -y

echo "apache2 web server terinstall"

echo "Install database"
apt install mysql-server -y
echo "Database terinstall"

apt install php7.4-fpm php7.4-common php7.4-xml php7.4-zip php7.4-mysql php7.4-mbstring php7.4-json php7.4-curl php7.4-gd php7.4-pgsql -y   
echo "install php & modules"

echo "Start services"
systemctl restart apache2
systemctl restart mysql

echo "enable service"
systemctl enable apache2
systemctl enable mysql


echo "check status services"
echo apache2 service status $(systemctl show -p ActiveState --value apache2)
echo Database service status $(systemctl show -p ActiveState --value mysql)

echo "lamp install di ubuntu success"

echo "============================================"
echo "Create database & user for wordpress"
echo "============================================"

#variable database
user="wp_user"
pass="wordpress123513"
dbname="wp_db"

echo "create db name"
mysql -e "CREATE DATABASE $dbname;"

echo "Creating new user..."
mysql -e "CREATE USER '$user'@'%' IDENTIFIED BY '$pass';"
echo "User successfully created!"

echo "Granting ALL privileges on $dbname to $user!"
mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$user'@'%';"
mysql -e "FLUSH PRIVILEGES;"
echo "Success :)"


echo "============================================"
echo "Install Wordpress menggunakan Bash Script   "
echo "============================================"
#download wordpress
curl -O https://wordpress.org/latest.tar.gz
#unzip wordpress
tar -zxvf latest.tar.gz

#Change owner & chmod
chown -R www-data:www-data wordpress/
chmod -R 755 wordpress/

#change dir to wordpress
cd wordpress

#create wp config
cp wp-config-sample.php wp-config.php
chown -R www-data:www-data wp-config.php
#set database details with perl find and replace
perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
perl -pi -e "s/username_here/$user/g" wp-config.php
perl -pi -e "s/password_here/$pass/g" wp-config.php

#set WP salts
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php

#create uploads folder and set permissions
mkdir wp-content/uploads
chmod 775 wp-content/uploads


#Create VirtualHost apache2 for wordpress
touch /etc/apache2/sites-available/wordpress.conf
cat > /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@rodpres.online
    ServerName $your_domain
    # ServerAlias 
    DocumentRoot /home/oprek/wordpress
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

<Directory /home/oprek/wordpress/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
</VirtualHost>
EOF

#enable apache2
a2ensite wordpress.conf
a2enmod rewrite
a2dissite 000-default.conf
systemctl restart apache2

echo "Restart service Apache2"
systemctl restart apache2


echo "SSL generate with certbot"
apt install certbot python3-certbot-apache -y
certbot run -n --apache --agree-tos -d wp.igunawan.com -m admin@igunawan.com  --redirect

echo "========================="
echo "Installation is complete."
echo "=========================" 

