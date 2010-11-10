#!/bin/bash

# root
sudo su -

apt-get update && apt-get upgrade

# install Ruby
apt-get install ruby-full

# install RubyGems
wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
tar zxvf rubygems-1.3.7.tgz
cd rubygems-1.3.7
chmod a+x setup.rb
ruby setup.rb

## using tarball method instead of apt-get!
## apt-get install rubygems

aptitude install build-essential zlib1g-dev tcl-dev libexpat-dev libcurl4-openssl-dev postfix apache2 mysql-server mysql-client apg geoip-bin libgeoip1 libgeoip-dev sqlite3 libsqlite3-dev  imagemagick libpcre3 libpcre3-dev zlib1g zlib1g-dev libyaml-dev libmysqlclient15-dev apache2-dev libonig-dev ruby-dev libopenssl-ruby phpmyadmin libdbd-mysql-ruby libmysql-ruby libmagick++-dev  zip unzip memcached git-core git-svn git-doc git-cvs irb

gem install -b --no-ri --no-rdoc rmagick chronic geoip daemons hoe echoe ruby-yadis ruby-openid mime-types diff-lcs json ruby-hmac rake stompserver passenger rails

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
cp git-daemon /etc/init.d/git-daemon
cp git-ultrasphinx /etc/init.d/git-ultrasphinx
cp gitorious /etc/logrotate.d/gitorious
cp stomp /etc/init.d/stomp
cp git-poller /etc/init.d/git-poller

chmod 755 /etc/init.d/git-ultrasphinx /etc/init.d/git-daemon /etc/init.d/stomp /etc/init.d/git-poller
update-rc.d stomp defaults
update-rc.d git-daemon defaults
update-rc.d git-ultrasphinx defaults
update-rc.d git-poller defaults

gem install mongrel
gem install thin

# add user 'git'
adduser --system --home /var/www/gitorious/ --no-create-home --group --shell /bin/bash git
chown -R git:git /var/www/gitorious

# git
su - git

mkdir .ssh
touch .ssh/authorized_keys
chmod 700 .ssh
chmod 600 .ssh/authorized_keys
mkdir tmp/pids
mkdir repositories
mkdir tarballs

cp config/database.sample.yml config/database.yml
cp config/gitorious.sample.yml config/gitorious.yml
cp config/broker.yml.example config/broker.yml

# Edit config/database.yml: Remove every section but production
# Edit config/gitorious.yml: Remove every section but production

export RAILS_ENV=production
rake db:create   
rake db:migrate
rake ultrasphinx:bootstrap

#crontab -e
#* * * * * cd /var/www/gitorious && /usr/bin/rake ultrasphinx:index RAILS_ENV=production
