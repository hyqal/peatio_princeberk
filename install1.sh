#!bin/bash
sudo apt-get update
sudo apt-get upgrade -y
wget https://gist.githubusercontent.com/scatterp2/3f6b1ae1965de18057a896bedc9a6132/raw/cb230dc8b9cc5dab6da64f7e34cf5e50ae373092/passenger.conf
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev imagemagick gsfonts nodejs nginx-extras redis-server software-properties-common python-software-properties nano dialog
sudo apt-get update
cd

git clone git://github.com/sstephenson/rbenv.git /home/deploy/.rbenv
git clone https://github.com/sstephenson/ruby-build.git /home/deploy/.rbenv/plugins/ruby-build
sudo /home/deploy/.rbenv/plugins/ruby-build/install.sh

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

rbenv install 2.6.2
rbenv global 2.6.2

echo "gem: --no-ri --no-rdoc" > ~/.gemrc
gem install bundler -v 1.17.2
rbenv rehash

sudo apt-get update
sudo apt-get install -y rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management
sudo service rabbitmq-server restart
wget http://localhost:15672/cli/rabbitmqadmin
chmod +x rabbitmqadmin
sudo mv rabbitmqadmin /usr/local/sbin

sudo add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe'
sudo apt-get update
sudo apt-get install -y mysql-server-5.6 redis-server libmysqlclient-dev
sudo apt-get install -y dirmngr gnupg
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates

# Add our APT repository
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update

# Install Passenger + Nginx
sudo apt-get install -y --allow-unauthenticated nginx-extras passenger
sudo cp passenger.conf /etc/nginx/passenger.conf

cp /etc/nginx/nginx.conf .
sed -i '64i\passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;' nginx.conf
sed -i '65i\passenger_ruby /home/deploy/.rbenv/shims/ruby;' nginx.conf
sudo cp nginx.conf /etc/nginx/nginx.conf
echo "remaining steps 10"
echo "export RAILS_ENV=production" >> ~/.bashrc
source ~/.bashrc
mkdir -p ~/peatio

git clone https://github.com/scatterp/peatio.git ~/peatio/current

cd ~/peatio/current/
pwd

bundle install --without development test --path vendor/bundle
bundle update

bin/init_config
dialog --msgbox "enter database password  in settings and save" 10 20
sudo nano ~/peatio/current/config/database.yml
cd ~/peatio/current/
sudo /etc/init.d/mysql stop
sudo /etc/init.d/mysql start
sleep 5;

sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /home/deploy/peatio/current/config/nginx.conf /etc/nginx/conf.d/peatio.conf
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y python-certbot-nginx
sudo service nginx stop
bundle exec rake db:setup
bundle exec rake assets:precompile
sudo service nginx start
bundle exec rake daemons:start

bundle exec rake daemons:status
mv pc ..
echo "you can now setup ssl optionally start bitcoind if you have over 2gb or visit the website (its up and running)"
