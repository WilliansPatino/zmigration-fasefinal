

# permitir los puertos esenciales para la migración

 sudo firewall-cmd --zone=public --add-service=143 --permanent
 sudo firewall-cmd --zone=public --add-service=993 --permanent