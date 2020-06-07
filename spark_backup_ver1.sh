#!/bin/bash
#written by harish
#Script To take backup of Spark hadoop configurations.
#Please make ensure clush is installed on cluster with user mapr to ensure it works as expected .

#1 Run as mapr user

if [[ $EUID -ne 5000 ]]; then
   echo "This script must be run as mapr"
   exit 1
fi

#2 Defining Variables
clustername=$(cat /opt/mapr/conf/mapr-clusters.conf | grep -v ^# | head -1 | cut -d" " -f1)
IP_ADD=$(clush -a date | awk -F':' '{print $1}')
DATE=$(date '+%Y-%m-%d-%H-%M-%S')
DATE1=$(date '+%Y-%m-%d')
logfile=/opt/mapr/logs/support/$(basename $0).log.${DATE}
mkdir -p $(dirname $logfile)
#Please provide the no.of Days to maintains logs backup . previous logs will be zipped/cleared
#BKP_DAYS=180
#Path to mainitain DB_Bakups
BACKUP_DIR="/opt/mapr/backups/$DATE1"


#3 Files to take backup Spark & Sqoop
HOST_NAME=hostname
MAPR_REPO="/etc/yum.repos.d/mapr_*.repo"
SPARK=$(find /opt/mapr -maxdepth 2 -type d -name 'spark-[0-9].[0-9]*' -exec ls -dv '{}' ';' 2>/dev/null | sort --version-sort | tail -n 1 | cut -d'/' -f4-)
SQOOP=$(find /opt/mapr -maxdepth 2 -type d -name 'sqoop-[0-9].[0-9]*' -exec ls -dv '{}' ';' 2>/dev/null | sort --version-sort | tail -n 1 | cut -d'/' -f4-)


echo -e "#Configurations Backup Started ---> $BACKUP_DIR\n" >> $logfile
for host in $IP_ADD
do
LOCAL_BKP="${BACKUP_DIR}/backup_configs_${host}.tgz"
EXEC_CMD="cd /opt/mapr/; tar fczP ${LOCAL_BKP} $SQOOP/conf $SPARK/conf $MAPR_REPO"
echo -e "clush -w $host 'if [ ! -d "$BACKUP_DIR" ];then mkdir -p $BACKUP_DIR; fi'\n" >> $logfile
echo -e "clush -w $host $EXEC_CMD\n" >> $logfile
clush -w $host "if [ ! -d "$BACKUP_DIR" ];then mkdir -p $BACKUP_DIR; fi"
clush -w $host $EXEC_CMD > /dev/null 2>&1
done

echo "Backup Completed : $BACKUP_DIR" >> $logfile


#Clearing Old_Backups:
#echo -e "Clearing Old_Backups....\n" >> $logfile
#find $BACKUP_DIR -type f -name '*-*-*' -mtime +$BKP_DAYS -exec rm {} \;
#echo -e "Old_Backups before $BKP_DAYS days cleared successfully ....\n" >> $logfile
#echo -e "Backup Activity Completed.....  Please Validate" >> $logfile
