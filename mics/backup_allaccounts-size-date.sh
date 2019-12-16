#test
ZHOME=/opt/zimbra
ZBACKUP=/opt/backup/mailbox
ZCONFD=$ZHOME/conf
DATE=`date +"%d%m%g"`
ZDUMPDIR=$ZBACKUP/$DATE
ZMBOX=/opt/zimbra/bin/zmmailbox
ZMPROV=/opt/zimbra/bin/zmprov

#DATE=`date --date='-1 month' +%D`
DATE="07/27/16"
FOLDER="inbox"

if [ ! -d $ZDUMPDIR ]; then
mkdir -p $ZDUMPDIR
chown -R zimbra:zimbra $ZDUMPDIR
fi

for mailbox in `zmprov -l gaa`
do
echo "------------------------------------------"  | tee -a  /tmp/report.txt
#echo " Generating files from backup $mailbox ..."
#       $ZMBOX -z -m $mailbox getRestURL "//?fmt=zip" > $ZDUMPDIR/$mailbox.zip
	echo "Inbox size of $mailbox......." | tee -a /tmp/report.txt
#	$ZMBOX -z -m $mailbox gms 
	quota=`$ZMPROV -l ga $mailbox | grep zimbraMailQuota| awk '{print $2}'` #get assigned quota
	mboxsize=`$ZMBOX -z -m $mailbox gms` #Current Mail box Size 
	
	#If we want to Take backup of all account, uncomment the following Section, and comment line marked "Alfa" 
	#---------------------
	#echo "Backup of Inbox only" | tee -a /tmp/report.txt
	#$ZMBOX -z -m $mailbox getRestURL "//?fmt=zip" > $ZDUMPDIR/$mailbox.zip
	#---------------------
	quota=$((($quota/1024)/1024)) # Convert Quota in MB
	echo "Assigned Quota,0 mean unlimited = $quota" | tee -a /tmp/report.txt
	#if quota id 0 mean it has unlimited quota, assign 10MB
	if [ $quota -eq 0 ]; then
	    quota=10  #########chnage it to 100 before go to production 
	fi

	i="$(echo $mboxsize | awk '{print $2}')" # KB or MB
	used="$(echo $mboxsize | awk '{print $1}')"
	per=`echo "(100 * $used)/$quota" | bc -l| cut -d"." -f1`
	#per=`echo $per | cut -d"." -f1`
	echo "% of Used - - - - - - - - - - - =$per$i"  | tee -a /tmp/report.txt
	if [[ "$i" == *"KB"* ]]; then
	      echo "Current Usage less then 1 MB ..... NOT DELETED"  | tee -a /tmp/report.txt
	elif [[ "$i" == *"MB"* ]]; then
	      #echo "MB"
	      if [[ $per -gt 20 ]]; then ###############Set your quota################
		#-----------Alfa-----------
		echo "Backup of Inbox only"  | tee -a /tmp/report.txt
	        $ZMBOX -z -m $mailbox getRestURL "//?fmt=zip" > $ZDUMPDIR/$mailbox.zip #Alfa 
		#-----------Alfa-----------
 
		echo "Mail box of $mboxsize is greater then 90% ......DELETED"  | tee -a /tmp/report.txt
		echo "       Emails older then 30 days"  | tee -a /tmp/report.txt
		####################################Delete Complete Folder ######################
		#$ZMBOX -z -m $mailbox emptyFolder /Inbox
		####################################Delete 30 Day old emails ######################
		touch /tmp/deleteOldMessagesList.txt
		> /tmp/deleteOldMessagesList.txt
		totalmails=`$ZMBOX -z -m  $mailbox gaf | grep Inbox | awk '{print $4}'`
	        if [ $totalmails -gt 4 ]; then
		while [ $totalmails -gt 4 ]
		do
			        #echo "Emails are greter then 1000"
       				totalmails=$[$totalmails - 2]
        			#echo "Delete 1000  mail , current mails are = $totalmails"
			#get message IDs
			for i in `$ZMBOX -z -m $mailbox search -l 5 "in:/$FOLDER (before:$DATE)" | grep conv | sed -e "s/^\s\s*//" | sed -e "s/\s\s*/ /g" | cut -d" " -f2`
			do
				if [[ $i =~ [-]{1} ]]
				then
				MESSAGEID=${i#-}
				echo "deleteMessage $MESSAGEID" >> /tmp/deleteOldMessagesList.txt
				else
				echo "deleteConversation $i" >> /tmp/deleteOldMessagesList.txt
				fi
			done
			$ZMBOX -z -m $mailbox < /tmp/deleteOldMessagesList.txt >> /tmp/process.log
		   done
		else 
                        for i in `$ZMBOX -z -m $mailbox search -l 5 "in:/$FOLDER (before:$DATE)" | grep conv | sed -e "s/^\s\s*//" | sed -e "s/\s\s*/ /g" | cut -d" " -f2`
                        do
                                if [[ $i =~ [-]{1} ]]
                                then
                                MESSAGEID=${i#-}
                                echo "deleteMessage $MESSAGEID" >> /tmp/deleteOldMessagesList.txt
                                else
                                echo "deleteConversation $i" >> /tmp/deleteOldMessagesList.txt
                                fi
                        done
                        $ZMBOX -z -m $mailbox < /tmp/deleteOldMessagesList.txt >> /tmp/process.log

		fi
		#rm -f /tmp/deleteOldMessagesList.txt		
		cat /tmp/deleteOldMessagesList.txt

		
	       fi
	fi
done

echo "Detail report /tmp/report.txt"
