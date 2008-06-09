#!/bin/bash
#Xfvb :3 -ac
#su -c "umask 0000;DISPLAY=:3 /root/OpenOffice.org1.1.0/soffice \"-accept=socket,host=localhost,port=2002;urp;\"" www-data 
#su -c "xclock -display :3" www-data 
su -c "xvfb-run /root/OpenOffice.org1.1.0/soffice \"-accept=socket,host=localhost,port=2002;urp;\""  www-data
