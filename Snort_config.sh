#!/bin/bash

snort_config(){
echo "Realizando os updates!!!"
echo "Apos os updates reinicie a maquina"
sleep 3
clear
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get install -y openssh-server
echo "Reinicie o equipamento se ainda nao o fez"
sleep 10

echo "Iniciando configuraçao do Snort"
sleep 3

#Instalando pre-requisitos
sudo apt-get install -y build-essential
sudo apt-get install -y libpcap-dev libpcre3-dev libdumbnet-dev

#Criando pasta de instalaçao
mkdir ~/snort_src
cd ~/snort_src

sudo apt-get install -y bison flex

#Instalando DAQ 2.0.6
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
tar xvfz daq-2.0.6.tar.gz
cd daq-2.0.6
./configure && make && sudo make install

#Iniciando instalaçao do Snort
#Instalando dependencias
sudo apt-get install -y zlib1g-dev liblzma-dev openssl libssl-dev

#Instalando Snort
cd ~/snort_src
wget https://www.snort.org/downloads/snort/snort-2.9.8.2.tar.gz
tar xvfz snort-2.9.8.2.tar.gz
cd snort-2.9.8.2
./configure --enable-sourcefire && make && sudo make install

#Atualizando bibliotecas compartilhadas
sudo ldconfig

#Gerando symlink do Snort
sudo ln -s /usr/local/bin/snort /usr/sbin/snort

#Verificando versao
echo "Versao do Snort:"
snort -V
sleep 5

# Create the snort user and group:
sudo groupadd snort
sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

# Criando diretorios do Snort
sudo mkdir /etc/snort
sudo mkdir /etc/snort/rules
sudo mkdir /etc/snort/rules/iplists
sudo mkdir /etc/snort/preproc_rules
sudo mkdir /usr/local/lib/snort_dynamicrules
sudo mkdir /etc/snort/so_rules

# Criando arquivos das regras 
sudo touch /etc/snort/rules/iplists/black_list.rules
sudo touch /etc/snort/rules/iplists/white_list.rules
sudo touch /etc/snort/rules/local.rules
sudo touch /etc/snort/sid-msg.map

# Gerando diretorios de logs:
sudo mkdir /var/log/snort
sudo mkdir /var/log/snort/archived_logs

# Definindo permissoes:
sudo chmod -R 5775 /etc/snort
sudo chmod -R 5775 /var/log/snort
sudo chmod -R 5775 /var/log/snort/archived_logs
sudo chmod -R 5775 /etc/snort/so_rules
sudo chmod -R 5775 /usr/local/lib/snort_dynamicrules

# Definindo donos dos diretorios:
sudo chown -R snort:snort /etc/snort
sudo chown -R snort:snort /var/log/snort
sudo chown -R snort:snort /usr/local/lib/snort_dynamicrules

cd ~/snort_src/snort-2.9.8.2/etc/
sudo cp *.conf* /etc/snort
sudo cp *.map /etc/snort
sudo cp *.dtd /etc/snort
cd ~/snort_src/snort-2.9.8.2/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/
sudo cp * /usr/local/lib/snort_dynamicpreprocessor/

#Gerando copia de segurança das configuraçoes
sudo cp /etc/snort/snort.conf /etc/snort/snort.BAK_INIT

sudo sed -i "s/include \$RULE\_PATH/#include \$RULE\_PATH/" /etc/snort/snort.conf
#Escolhendo IP da rede a ser protegida
sudo sed -i "s/ipvar HOME_NET any/ipvar HOME_NET 192.168.0.0\/24/g" /etc/snort/snort.conf

#Escrevendo caminho das regras
sudo sed -i "s/var RULE_PATH ..\/rules/var RULE_PATH \/etc\/snort\/rules/g" /etc/snort/snort.conf
sudo sed -i "s/var SO_RULE_PATH ..\/so_rules/var SO_RULE_PATH \/etc\/snort\/so_rules/g" /etc/snort/snort.conf
sudo sed -i "s/var PREPROC_RULE_PATH ..\/preproc_rules/var PREPROC_RULE_PATH \/etc\/snort\/preproc_rules/g" /etc/snort/snort.conf

#Caminhos das regras de IP
sudo sed -i "s/var WHITE_LIST_PATH ..\/rules/var WHITE_LIST_PATH \/etc\/snort\/rules\/iplists/g" /etc/snort/snort.conf
sudo sed -i "s/var BLACK_LIST_PATH ..\/rules/var BLACK_LIST_PATH \/etc\/snort\/rules\/iplists/g" /etc/snort/snort.conf

#Ativando regras locais
sudo sed -i "s/#include \$RULE\_PATH\/local.rules/include \$RULE\_PATH\/local.rules/g" /etc/snort/snort.conf

#Validando configuraçao
sudo snort -T -i eth0 -c /etc/snort/snort.conf
sleep 5
#Copia das configuraçoes feitas
sudo cp /etc/snort/snort.conf /etc/snort/snort.BAK_RULES

#Iniciando instalaçao do Barnyard2

sudo apt-get install -y mysql-server libmysqlclient-dev mysql-client autoconf libtool

#Outputs snort em binario
sudo sed -i "s/# output unified2: filename merged.log, limit 128, nostamp, mpls_event_types, vlan_event_types/output unified2: filename snort.u2, limit 128/g" /etc/snort/snort.conf

#Baixando e instalando Barnyard2
cd ~/snort_src
wget https://github.com/firnsy/barnyard2/archive/7254c24702392288fe6be948f88afb74040f6dc9.tar.gz \
-O barnyard2-2-1.14-336.tar.gz
tar zxvf barnyard2-2-1.14-336.tar.gz
mv barnyard2-7254c24702392288fe6be948f88afb74040f6dc9 barnyard2-2-1.14-336
cd barnyard2-2-1.14-336
autoreconf -fvi -I ./m4
sudo ln -s /usr/include/dumbnet.h /usr/include/dnet.h
sudo ldconfig

#Arquitetura do OS

echo "Escolha a arquitetura de seu sistema:"
echo "1 --> x86"
echo "2 --> x64"
read arch

if [ "$arch" = "1" ];then
	./configure --with-mysql --with-mysql-libraries=/usr/lib/i386-linux-gnu
else
	./configure --with-mysql --with-mysql-libraries=/usr/lib/x86_64-linux-gnu
fi

make && sudo make install

#Realizando copias para funcionamento do Barnyard2
cd ~/snort_src/barnyard2-2-1.14-336/
sudo cp etc/barnyard2.conf /etc/snort/
sudo mkdir /var/log/barnyard2
sudo chown snort.snort /var/log/barnyard2

#Arquivos Barnyard2
sudo touch /var/log/snort/barnyard2.waldo
sudo chown snort.snort /var/log/snort/barnyard2.waldo

#Configurando SQL
echo "Nome de seu banco de dados:"
read datab
echo "Nome do usuario para o banco de dados: "
read dbuser
echo "Senha do usuario: "
read dbpass

SQL="create database $datab; use $datab; source ~/snort_src/barnyard2-2-1.14-336/schemas/create_mysql; CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass'; grant create, insert, select, delete, update on $datab.* to '$dbuser'@'localhost';"
mysql -u root -psenha -e "$SQL" mysql

sudo chmod 777 /etc/snort/barnyard2.conf
sudo echo "output database: log, mysql, user=$dbuser password=$dbpass dbname=$datab host=localhost" >> /etc/snort/barnyard2.conf
sudo chmod 644 /etc/snort/barnyard2.conf

sudo chmod o-r /etc/snort/barnyard2.conf

# Instalaçao PulledPork

#Instalando Pre-requisitos
sudo apt-get install -y libcrypt-ssleay-perl liblwp-useragent-determined-perl 

#Baixando PulledPork
cd ~/snort_src
wget https://github.com/finchy/pulledpork/archive/8b9441aeeb7e1477e5be415f27dbc4eb25dd9d59.tar.gz \
-O pulledpork-0.7.2-196.tar.gz
tar xvfvz pulledpork-0.7.2-196.tar.gz
mv pulledpork-8b9441aeeb7e1477e5be415f27dbc4eb25dd9d59 pulledpork-0.7.2-196
cd pulledpork-0.7.2-196/
sudo cp pulledpork.pl /usr/local/bin
sudo chmod +x /usr/local/bin/pulledpork.pl
sudo cp etc/*.conf /etc/snort

#Teste
/usr/local/bin/pulledpork.pl -V
sleep 3

#Alterando configuraçao do PulledPork
sudo mv /etc/snort/pulledpork.conf /etc/snort/pulledpork.BAK
sudo cp  ~/Snort-config/pulledpork.conf /etc/snort/pulledpork.conf

#Baixando regras
sudo /usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l

#Definindo caminho das configurações do Snort
sudo sed -i "s/#include \$RULE\_PATH\/app-detect.rules/include \$RULE\_PATH\/snort.rules/g" /etc/snort/snort.conf

#Validando regras
sudo snort -T -c /etc/snort/snort.conf -i eth0

#Script de inicializaçao
sudo cp ~/Snort-config/snort.script /etc/init/snort.conf
sudo chmod +x /etc/init/snort.conf
initctl list | grep snort

sudo cp ~/Snort-config/barnyard2.script /etc/init/barnyard2.conf
sudo chmod +x /etc/init/barnyard2.conf
initctl list | grep barnyard

sudo apt-get install -y imagemagick apache2 libyaml-dev libxml2-dev libxslt-dev git ruby1.9.3

echo "gem: --no-rdoc --no-ri" > ~/.gemrc
sudo sh -c "echo gem: --no-rdoc --no-ri > /etc/gemrc"

#Instalando dependencias
sudo gem install wkhtmltopdf
sudo gem install bundler
sudo gem install rake --version=0.9.2

#Instalando dependencia do Rails
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby
\curl -sSL https://get.rvm.io | bash -s stable
\curl -sSL https://get.rvm.io | bash -s -- --ignore-dotfiles
echo "source $HOME/.rvm/scripts/rvm" >> ~/.bash_profile
\curl -sSL https://get.rvm.io | sudo bash -s stable
source /etc/profile
rvm get stable --autolibs=enable
rvm install ruby
rvm --default use ruby-2.3.0
gem update --system
rvm gemset list
rvm gemset use global
gem list
gem outdated
gem update
rvm use ruby-2.3.0@rails4.2 --create
gem install rails

#Baixando e instalando Snorby
cd ~/snort_src/
wget https://github.com/Snorby/snorby/archive/v2.6.2.tar.gz -O snorby-2.6.2.tar.gz
tar xzvf snorby-2.6.2.tar.gz
sudo cp -r ./snorby-2.6.2/ /var/www/html/snorby/
cd /var/www/html/snorby
sudo bundle install

sudo cp /var/www/html/snorby/config/database.yml.example /var/www/html/snorby/config/database.yml

#Inserindo Root para criar banco de dados Snorby
echo "Insira sua senha de root do MySQL"
read sqlpass
sudo sed -i "s/Enter Password Here/$sqlpass/g" /var/www/html/snorby/database.yml 

#Copiando configuraçoes do Snorby
sudo cp /var/www/snorby/config/snorby_config.yml.example /var/www/snorby/config/snorby_config.yml
sudo sed -i s/"\/usr\/local\/bin\/wkhtmltopdf"/"\/usr\/bin\/wkhtmltopdf"/g \
/var/www/snorby/config/snorby_config.yml

#Configurando Snorby
cd /var/www/snorby
sudo bundle exec rake snorby:setup

#Criando banco de dados Snorby

echo "Nome do usuario para o banco de dados: "
read dbuser1
echo "Senha do usuario: "
read dbpass1

SQL1="create user '$dbuser1'@'localhost' IDENTIFIED BY ' $dbpass1 ' ; grant all privileges on snorby.* to '$dbuser1'@'localhost' with grant option; flush privileges;"
mysql -u root -psenha -e "$SQL1" mysql

#Colocando Nova senha
sudo sed -i "s/root/$dbuser1/g" /var/www/html/snorby/database.yml 
sudo sed -i "s/$sqlpass/$dbpass1/g" /var/www/html/snorby/database.yml 

cd /var/www/html/snorby/

#Configurando o Apache
#Instalando Pre-requisitos
sudo apt-get install -y libcurl4-openssl-dev apache2-threaded-dev libaprutil1-dev libapr1-dev
sudo gem install passenger
sudo passenger-install-apache2-module

#Gerando arquivos de configuraçao Apache
sudo touch /etc/apache2/mods-available/passenger.load
sudo chmod 777 /etc/apache2/mods-available/passenger.load

#Esta opçao pode variar em sua instalaçao
#Faça a verificaçao e caso necessario aletere no arquivo passanger.load
sudo echo "LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-5.0.27/buildout/apache2/mod_passenger.so" >> /etc/apache2/mods-available/passenger.load
sudo chmod 644 /etc/apache2/mods-available/passenger.load 

sudo touch /etc/apache2/mods-available/passenger.conf
sudo chmod 777 /etc/apache2/mods-available/passenger.conf
#Estas sao outras opçoes podem variar de acordo com instalaçao
echo "PassengerRoot /var/lib/gems/1.9.1/gems/passenger-5.0.27" >> /etc/apache2/mods-available/passenger.conf
echo "PassengerDefaultRuby /usr/bin/ruby1.9.1" >> /etc/apache2/mods-available/passenger.conf
sudo chmod 644 /etc/apache2/mods-available/passenger.conf 


#Reiniciando o Serviço Apache
sudo service apache2 restart
sudo a2enmod passenger

#Copiando site do Snorby
sudo cp ~/Snort-config/snorby.script /etc/apache2/sites-available/snorby.conf

#Carregando as configuraçoes
cd /etc/apache2/sites-available/
sudo service apache2 reload
sudo a2ensite snorby.conf


cd /etc/apache2/sites-enabled
sudo service apache2 reload
sudo a2dissite 000-default


sudo chmod 777 /etc/snort/barnyard2.conf
sudo echo "output database: log, mysql, user=snorby password=PASSWORD123 dbname=snorby host=localhost sensor_name=sensor1" >> /etc/snort/barnyard2.conf
sudo chmod 644 /etc/snort/barnyard2.conf
sudo chmod o-r /etc/snort/barnyard2.conf

#Reiniciando serviços
sudo service barnyard2 restart

#Fazendo script de inicializaçao
sudo cp ~/Snort-config/snorby_init.script /etc/init/snorby_worker.conf
sudo chmod +x /etc/init/snorby_worker.conf

}

ROT=$(id -u)

if [ "$ROT" = "0" ];then
	snort_config

else
	echo "O script abre apenas com ROOT"
	exit

fi
