

# permitir los puertos esenciales para la migración

 sudo firewall-cmd --zone=public --add-service=imap --permanent
 sudo firewall-cmd --zone=public --add-service=imaps --permanent

 firewall-cmd --reload
 firewall-cmd --zone=public --list-all