

# permitir los puertos esenciales para la migración

 sudo firewall-cmd --zone=public --add-service=imap --permanent
 firewall-cmd --zone=public --list-all