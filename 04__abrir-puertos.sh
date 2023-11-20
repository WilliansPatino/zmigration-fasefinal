

# permitir los puertos esenciales para la migración

 sudo firewall-cmd --zone=public --add-service=imap --permanent
 sudo firewall-cmd --zone=public --add-service=imaps --permanent

 firewalll-cmd --reload
 firewall-cmd --zone=public --list-all