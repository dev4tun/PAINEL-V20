#!/bin/bash
clear
IP=$(wget -qO- ipv4.icanhazip.com)
_dir='/var/www/html'
echo "America/Sao_Paulo" > /etc/timezone
ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime > /dev/null 2>&1
dpkg-reconfigure --frontend noninteractive tzdata > /dev/null 2>&1
echo -e "\E[44;1;37m           PAINEL SSHPLUS V20           \E[0m"
echo -ne "\n\033[1;32mINFORME UMA SENHA PARA O MYSQL\033[1;37m: "; read senha
echo -e "\n\033[1;36mINICIANDO INSTALACAO \033[1;33mAGUARDE..."
apt-get update -y > /dev/null 2>&1
apt-get install cron curl screen unzip dirmngr apt-transport-https -y > /dev/null 2>&1
echo -e "\n\033[1;36mINSTALANDO APACE2 APACHE2 \033[1;33mAGUARDE...\033[0m"
apt-get install apache2 -y > /dev/null 2>&1
apt-get install php5 libapache2-mod-php5 php5-mcrypt -y > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
echo -e "\n\033[1;36mINSTALANDO MySQL \033[1;33mAGUARDE...\033[0m"
echo "debconf mysql-server/root_password password $senha" | debconf-set-selections
echo "debconf mysql-server/root_password_again password $senha" | debconf-set-selections
apt-get install mysql-server -y > /dev/null 2>&1
mysql_install_db > /dev/null 2>&1
(echo $senha; echo n; echo y; echo y; echo y; echo y)|mysql_secure_installation > /dev/null 2>&1
echo -e "\n\033[1;36mINSTALANDO PHPMYADMIN \033[1;33mAGUARDE...\033[0m"
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $senha" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $senha" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $senha" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt-get install phpmyadmin -y > /dev/null 2>&1
php5enmod mcrypt > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
apt-get install libssh2-1-dev libssh2-php -y > /dev/null 2>&1
if [[ "$(php -m |grep ssh2)" != "ssh2" ]]; then
  clear
  echo -e "\033[1;31mERRO CRITICO\033[0m"
  cat /dev/null > ~/.bash_history && history -c
  rm $HOME/install.sh; exit
fi
echo -e "\n\033[1;36mFINALIZANDO INSTALACAO \033[1;33mAGUARDE...\033[0m"
apt-get install php5-curl > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
rm $_dir/sshplus.sql > /dev/null 2>&1
mysql -h localhost -u root -p$senha -e 'CREATE DATABASE sshplus'
cd /var/www/html/
sleep 1
wget https://www.dropbox.com/s/j2s7lg3tboarv7j/PAINELv20.zip > /dev/null 2>&1
[[ -e /var/www/html/PAINELv20.zip ]] && {
unzip PAINELv20.zip > /dev/null 2>&1
sleep 1
rm PAINELv20.zip index.html > /dev/null 2>&1
wget https://raw.githubusercontent.com/dev4tun/PAINEL-V20/main/sshplus.sql > /dev/null 2>&1
mv sshplus.sql /root/sshplus.sql
} || {
clear
echo -e "\033[1;31mERRO\033[0m"
cat /dev/null > ~/.bash_history && history -c
rm $HOME/install.sh; exit
}
if [[ -e "/var/www/html/pages/system/pass.php" ]]; then
sed -i "s;senha;$senha;g" /var/www/html/pages/system/pass.php > /dev/null 2>&1
else
echo -e "\n\033[1;31mERRO CRITICO!\033[0m"
rm $HOME/install.sh > /dev/null 2>&1
sleep 1
clear
exit
fi
cd $HOME
mysql -h localhost -u root -p$senha --default_character_set utf8 sshplus < sshplus.sql
sleep 1
rm /root/sshplus.sql > /dev/null 2>&1
wget -qO- https://raw.githubusercontent.com/dev4tun/PAINEL-V20/main/uteste > /bin/usersteste.sh
wget -qO- https://raw.githubusercontent.com/dev4tun/PAINEL-V20/main/backupauto > /bin/autobackup.sh
chmod 777 /bin/usersteste.sh
chmod 777 /bin/autobackup.sh
_bnco=$(echo $(openssl rand -hex 5))
sed -i "s;bancodir;$_bnco;g" /var/www/html/pages/system/config.php > /dev/null 2>&1
sed -i "s;bancodir;$_bnco;g" /bin/autobackup.sh > /dev/null 2>&1
mkdir /var/www/html/admin/pages/apis/$_bnco
touch /var/www/html/admin/pages/apis/$_bnco/index.html
chmod -R 777 /var/www/html
(crontab -l 2>/dev/null; echo -e "* * * * * /bin/usersteste.sh\n0 */4 * * * /bin/autobackup.sh\n* * * * * /usr/bin/php /var/www/html/pages/system/cron.online.ssh.php\n* * * * * /usr/bin/php /var/www/html/pages/system/cron.ssh.php\n0 */1 * * * /usr/bin/php /var/www/html/pages/system/hist.online.php\n* * * * * /usr/bin/php /var/www/html/pages/system/cron.php\n* * * * * /usr/bin/php /var/www/html/pages/system/cron.servidor.php") | crontab -
/etc/init.d/cron restart > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
/etc/init.d/mysql restart > /dev/null 2>&1
clear
echo -e "\033[1;32mINSTALADO COM SUCESSO!"
echo ""
echo -e "\033[1;36mSEU PANEL\033[1;37m $IP/admin\033[0m"
echo -e "\033[1;36mUSUARIO\033[1;37m admin\033[0m"
echo -e "\033[1;36mSENHA\033[1;37m admin\033[0m"
echo ""
echo -e "\033[1;33mALTERE A SENHA AO LOGAR\033[0m"
cat /dev/null > ~/.bash_history && history -c
cd $HOME; rm install.sh > /dev/null 2>&1
