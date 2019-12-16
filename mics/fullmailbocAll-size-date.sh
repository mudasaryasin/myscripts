#Mudasar Yasin
> /tmp/report.txt
echo "< IT will take backup of all accounts, If User Quota is >"  | tee -a  /tmp/report.txt
echo "< more then 90%, delete emails older then 1 month...... >"  | tee -a  /tmp/report.txt
echo "< ===================================================== >"  | tee -a  /tmp/report.txt
#echo Start time = $(date +%T)  
echo ""
ZHOME=/opt/zimbra
ZBACKUP=$ZHOME/backup/mailbox
echo "Wait ...Generating Mailbox size ..."  | tee -a  /tmp/report.txt
su - zimbra -c "/opt/zimbra/script/backup_allaccounts-size-date.sh"
