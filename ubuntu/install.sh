#!/bin/bash

function yn
{
    local answer
    read -p 'yes or no ? (y/N) ' answer
    if [ "$answer" != "y" ]||[ "$answer" != "Y" ]; then
        echo 'bye!'
        exit 1;
    fi
}

cat <<END
[ Gitorious 安裝記錄文件 ]
本文件將安裝 Ruby, RubyGems, Git, Apache2, MySQL 等諸多套件，請視需求修改或參考本文件。
本文件需以 root 身份執行，請問當前身份是否爲 root 帳號？
END
yn

apt-get update && apt-get upgrade
echo '將 '`pwd`' 內所有 shell 檔設定爲可執行'
chmod a+x ./*.sh

# install Ruby
apt-get install ruby-full

# install RubyGems
wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
tar zxvf rubygems-1.3.7.tgz
cd rubygems-1.3.7
chmod a+x setup.rb
ruby setup.rb

# install Packages
aptitude install apache2
aptitude install mysql-server mysql-client
aptitude install build-essential zlib1g-dev tcl-dev libexpat-dev libcurl4-openssl-dev postfix apg geoip-bin libgeoip1 libgeoip-dev sqlite3 libsqlite3-dev  imagemagick libpcre3 libpcre3-dev zlib1g zlib1g-dev libyaml-dev libmysqlclient15-dev apache2-dev libonig-dev ruby-dev libopenssl-ruby phpmyadmin libdbd-mysql-ruby libmysql-ruby libmagick++-dev  zip unzip memcached git-core git-svn git-doc git-cvs irb

# install Gems
gem install -b --no-ri --no-rdoc rmagick chronic geoip daemons hoe echoe ruby-yadis ruby-openid mime-types diff-lcs json ruby-hmac rake stompserver
gem install passenger
gem install rails
gem install -v=1.0.1 rack
gem install -b --no-ri --no-rdoc -v 1.3.1.1 rdiscount  
gem install -b --no-ri --no-rdoc -v 1.1 stomp

# if /usr/bin does NOT have 'rake' and 'stompserver' in there
ln -s /var/lib/gems/1.8/bin/rake /usr/bin    
ln -s /var/lib/gems/1.8/bin/stompserver /usr/bin

# setup Sphinx
wget http://www.sphinxsearch.com/downloads/sphinx-0.9.9.tar.gz
tar zxvf sphinx-0.9.9.tar.gz
cd sphinx-0.9.9
./configure --prefix=/usr && make all install

# fetch Gitorious
git clone http://git.gitorious.org/gitorious/mainline.git /var/www/gitorious
ln -s /var/www/gitorious/script/gitorious /usr/bin

# configure services
cp ./git-daemon /etc/init.d/git-daemon
cp ./git-ultrasphinx /etc/init.d/git-ultrasphinx
cp ./gitorious /etc/logrotate.d/gitorious
cp ./stomp /etc/init.d/stomp
cp ./git-poller /etc/init.d/git-poller

chmod 755 /etc/init.d/git-ultrasphinx
chmod 755 /etc/init.d/git-daemon
chmod 755 /etc/init.d/stomp
chmod 755 /etc/init.d/git-poller

update-rc.d stomp defaults
update-rc.d git-daemon defaults
update-rc.d git-ultrasphinx defaults
update-rc.d git-poller defaults

# install Passenger
#/var/lib/gems/1.8/bin/passenger-install-apache2-module
/usr/bin/passenger-install-apache2-module

cp ./passenger.load /etc/apache2/mods-available/passenger.load
a2enmod passenger
a2enmod rewrite  
a2enmod ssl
a2ensite default-ssl

cp ./apache-gitorious /etc/apache2/sites-available/gitorious
cp ./apache-gitorious-ssl /etc/apache2/sites-available/gitorious-ssl

# setting Apache2
a2dissite default
a2dissite default-ssl    
a2ensite gitorious    
a2ensite gitorious-ssl

/etc/init.d/apache2 restart

###########################################################

#gem install mongrel
#gem install thin

# add user 'git'
adduser --system --home /var/www/gitorious/ --no-create-home --group --shell /bin/bash git
chown -R git:git /var/www/gitorious

# git
echo '以下內容請切換成 git 使用者執行。'
echo '先新增一個有管理者權限的 MySQL 帳號 git'
echo '將 MySQL 內 git 帳號的密碼填寫至 database.yml'
#su - git

cat <<GIT
mkdir .ssh
touch .ssh/authorized_keys
chmod 700 .ssh
chmod 600 .ssh/authorized_keys
mkdir tmp/pids
mkdir repositories
mkdir tarballs

cp ./database.yml config/database.yml
cp ./gitorious.yml config/gitorious.yml
cp ./broker.yml config/broker.yml

export RAILS_ENV=production
rake db:create   
rake db:migrate
rake ultrasphinx:bootstrap

#crontab -e
#* * * * * cd /var/www/gitorious && /usr/bin/rake ultrasphinx:index RAILS_ENV=production

# 使用附帶的 ruby script 建立一個 Gitorious 網站管理者
env RAILS_ENV=production ruby1.8 script/create_admin
GIT
