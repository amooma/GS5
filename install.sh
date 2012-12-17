#!/bin/bash

echo -e "Gemeinschaft Version 5.0 Installation for Debian Linux\n"

GS_DIR="/opt/GS5"

aptitude update

# Ask for the Github account data
#
echo -e "github username:\n"
read USERNAME

echo -e "github password:\n"
read PASSWORD

# Upgrade everything to be on the safe side.
#
echo "Upgrade the server ..."
aptitude upgrade

# Install git
#
echo -e "Installing git ...\n"
aptitude install -y git

# Install the mysql server without asking for a password
#
echo "Installing MySQL server ..."
apt-get install -y debconf-utils

mysql_password=
export DEBIAN_FRONTEND=noninteractive 
debconf-set-selections <<< 'mysql-server-5.1 mysql-server/root_password password '$mysql_password''
debconf-set-selections <<< 'mysql-server-5.1 mysql-server/root_password_again password '$mysql_password''
apt-get -y install mysql-server

# Clone the git repository
#
echo -e "Downloading GS5 ...\n"

cd /opt

git clone "https://$USERNAME:$PASSWORD@github.com/amooma/GS5.git" "${GS_DIR}"

if [ -f "${GS_DIR}/config/application.rb" ]
then
  echo " OK"
else
  echo " ERROR"
  exit 1
fi

echo -e "Installing GS5 dependencies ...\n"

aptitude install -y \
  sqlite3 \
  libsqlite3-dev \
  libjpeg62 \
  ghostscript  \
  imagemagick  \
  libtiff-tools \

cd /usr/local/src/

wget "http://65.23.153.46/GS5/freeswitch_1.1.beta2.1-1_i386.deb"
wget "http://65.23.153.46/GS5/freeswitch-lang-en_1.1.beta2.1-1_i386.deb"
wget "http://65.23.153.46/GS5/freeswitch-lang-de_1.1.beta2.1-1_i386.deb"
wget "http://65.23.153.46/GS5/freeswitch-lua_1.1.beta2.1-1_i386.deb"
wget "http://65.23.153.46/GS5/unixodbc_2.3.1-1_i386.deb"
wget "http://65.23.153.46/GS5/mysql-connector-odbc_5.1.11-1_i386.deb"
wget "http://65.23.153.46/GS5/luasql_2.1.1-1_i386.deb"
wget "http://files.freeswitch.org/freeswitch-sounds-en-us-callie-8000-1.0.16.tar.gz"
wget "http://files.freeswitch.org/freeswitch-sounds-en-us-callie-16000-1.0.16.tar.gz"
wget "http://files.freeswitch.org/freeswitch-sounds-music-8000-1.0.8.tar.gz"
wget "http://files.freeswitch.org/freeswitch-sounds-music-16000-1.0.8.tar.gz"

echo -e "Installing FreeSWITCH dependencies ...\n"

aptitude install -y \
  libasound2 \
  libcurl3 \
  libogg0 \
  libvorbis0a

echo -e "Installing FreeSWITCH ...\n"

DEBIAN_FRONTEND=noninteractive  dpkg -i /usr/local/src/freeswitch_1.1.beta2.1-1_i386.deb
DEBIAN_FRONTEND=noninteractive  dpkg -i /usr/local/src/freeswitch-lang-en_1.1.beta2.1-1_i386.deb
DEBIAN_FRONTEND=noninteractive  dpkg -i /usr/local/src/freeswitch-freeswitch-lang-de_1.1.beta2.1-1_i386.deb
DEBIAN_FRONTEND=noninteractive  dpkg -i /usr/local/src/freeswitch-lua_1.1.beta2.1-1_i386.deb
DEBIAN_FRONTEND=noninteractive  dpkg -i /usr/local/src/unixodbc_2.3.1-1_i386.deb
DEBIAN_FRONTEND=noninteractive  dpkg -i /usr/local/src/mysql-connector-odbc_5.1.11-1_i386.deb
DEBIAN_FRONTEND=noninteractive  dpkg -i /usr/local/src/luasql_2.1.1-1_i386.deb

aptitude -f install

sed -i 's/FREESWITCH_ENABLED="false"/FREESWITCH_ENABLED="true"/'  /etc/default/freeswitch
sed -i 's/^FREESWITCH_PARAMS.*/FREESWITCH_PARAMS="-nc"/'   /etc/default/freeswitch

echo -e "Installing Dependencies ...\n"

aptitude -y install \
  curl \
  build-essential \
  libncurses5-dev \
  zlib1g-dev \
  libssl-dev \
  libreadline-dev \
  libcurl4-openssl-dev

# Install RVM
#
bash < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer )

source /etc/profile.d/rvm.sh

rvm install 1.9.2
rvm use 1.9.2 --default

# Install stuff which is needed to build specific gems
#
apt-get -y install libmysqlclient15-dev 
apt-get -y install libxslt-dev libxml2-dev

echo -e "Installing GS5 gems ...\n"
cd "${GS_DIR}"
bundle install

echo -e "Setting up database ...\n"

mysqladmin create gemeinschaft

echo "[ODBC Drivers]
MyODBC = Installed
/usr/local/lib/libmyodbc5.so = Installed

[gemeinschaft]
Description  = MySQL database for Gemeinschaft
Driver = /usr/lib/libmyodbc5.so
" >/usr/local/etc/odbcinst.ini

echo "[gemeinschaft]
Description  = MySQL database for Gemeinschaft
Driver       = /usr/local/lib/libmyodbc5.so
SERVER       = localhost
PORT         = 3306
DATABASE     = gemeinschaft
OPTION       = 67108864
USER         = gemeinschaft
PASSWORD     = gemeinschaft
" >/usr/local/etc/odbc.ini

mysql -e "GRANT ALL PRIVILEGES ON gemeinschaft.* TO gemeinschaft @'%' IDENTIFIED BY 'gemeinschaft';"
mysql -e "FLUSH PRIVILEGES"

bundle exec rake db:migrate RAILS_ENV="production"

echo -e "Extracting FreeSWITCH sounds ...\n"

mkdir -p /opt/freeswitch/sounds
cd /opt/freeswitch/sounds

tar -xzf "/usr/local/src/freeswitch-sounds-en-us-callie-8000-1.0.16.tar.gz"
tar -xzf "/usr/local/src/freeswitch-sounds-en-us-callie-16000-1.0.16.tar.gz"
tar -xzf "/usr/local/src/freeswitch-sounds-music-8000-1.0.8.tar.gz"
tar -xzf "/usr/local/src/freeswitch-sounds-music-16000-1.0.8.tar.gz"

echo -e "Creating FreeSWITCH configuration ...\n"

rm -fr /opt/freeswitch/conf
rm -fr /opt/freeswitch/scripts

ln -s "${GS_DIR}/misc/freeswitch/conf/" /opt/freeswitch/conf
ln -s "${GS_DIR}/misc/freeswitch/scripts/" /opt/freeswitch/scripts

echo -e "Setting up permissions ...\n"

addgroup gemeinschaft || true
adduser freeswitch  gemeinschaft --quiet

chgrp -R gemeinschaft "${GS_DIR}"
chmod -R g+w "${GS_DIR}"

# Create FreeSWITCH log directory
mkdir /var/log/freeswitch/
chown freeswitch:gemeinschaft /var/log/freeswitch/

# Installation of nginx and passenger
#
apt-get -y install libpcre3-dev
gem install passenger
passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx

rm -f /opt/nginx/conf/nginx.conf
ln -s "${GS_DIR}/misc/nginx/nginx.conf" /opt/nginx/conf/nginx.conf

adduser www-data gemeinschaft --quiet

# Generate CSS
#
cd "${GS_DIR}"
RAILS_ENV=production bundle exec rake assets:precompile

echo "Done!"

echo "You can start the webserver with /opt/nginx/sbin/nginx"


# Ensure FreeSWITCH has permission to write to Fax directory
#chmod -R g+w /opt/gemeinschaft/public/uploads/fax_document/
#chgrp -R gemeinschaft /opt/gemeinschaft/public/uploads/fax_document/
#chmod -R g+w /tmp/GS-5.0/
#chgrp -R gemeinschaft /tmp/GS-5.0/
