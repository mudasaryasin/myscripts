#!/bin/bash
ZHOME=/opt/zimbra
ZBACKUP=/opt/zimbraback
DATE=`date +"%d%m%g"`


echo "==============================Start DB backup=============================="
/opt/zimbra/mysql/bin/mysqldump --user=root --password= --socket=/opt/zimbra/db/mysql.sock --all-databases --single-transaction --flush-logs > /opt/zimbraback/db/fulldb$DATE.sql
if [ $? -eq 0 ]; then
    echo "Backup sucessfull"
    gzip /opt/zimbraback/db/fulldb$DATE.sql
else
    echo "Backup FAILED"
fi
echo "Delete files older then 7 days"
find /opt/zimbraback/db/ -type f -name "*.gz" -mtime +7 -exec rm {} \;
echo "DONE"

echo "==============================Start LDAP backup=============================="
su - zimbra -c "mkdir /opt/zimbraback/ldap/$DATE"
su - zimbra -c "/opt/zimbra/lmydomian1ec/zmslapcat /opt/zimbraback/ldap/$DATE"
su - zimbra -c "/opt/zimbra/lmydomian1ec/zmslapcat -c /opt/zimbraback/ldap/$DATE/"
su - zimbra -c "/opt/zimbra/lmydomian1ec/zmslapcat -a /opt/zimbraback/ldap/$DATE/"
tar -cvzf /opt/zimbraback/ldap/$DATE.trz /opt/zimbraback/ldap/$DATE
rm -rf /opt/zimbraback/ldap/$DATE
echo "Delete files older then 7 days"
find /opt/zimbraback/ldap/ -type f -name "*.trz" -mtime +7 -exec rm {} \;

echo "DONE"


echo "==============================Start CONFIG backup=============================="
#mkdir /opt/zimbraback/conf/$DATE
#cp -r /opt/zimbra/conf/* /opt/zimbraback/conf/$DATE
tar -cvzf /opt/zimbraback/conf/config$DATE.tgz  /opt/zimbra/conf
echo "Delete files older then 7 days"
find /opt/zimbraback/conf/ -type f -name "*.trz" -mtime +7 -exec rm {} \;
echo "DONE"
