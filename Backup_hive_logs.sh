#!/bin/bash
#Script To Move The Log Files From Source to Destination To consume Space and Delete the old logs more than X days.
##Crontab Entry --> Backup_hive_Logs.sh execution @ 12:45 AM CST
#45 12 * * * /opt/mapr/health_check_Scripts/Backup_hive_logs.sh >> /opt/mapr/logs/managedservices/Backup_hive_Logs.out
#Managed Services MFS Logs Paths -->  /mapr/${clustername}/managedservices/
#Managed Services Local Logs Path --> /opt/mapr/logs/managedservices/

clustername=$(cat /opt/mapr/conf/mapr-clusters.conf | grep -v ^# | head -1 | cut -d" " -f1)
SRC_DIR="/opt/mapr/hive/hive-2.3/logs/"
DEST_DIR="/mapr/${clustername}/managedservices/hive_backup_logs/"
#Specify No of Days to remain the old Logs
DAYS=15

echo -e "\n---------------------------------------------------------------------"
echo -e "Starting Backup Activity ..."
echo -e "Finding and Moving the .gz logs to : $DEST_DIR"
find $SRC_DIR -type f -iname "*.log.*.gz" -print | xargs -I {} mv {} $DEST_DIR
echo -e "Deleting logs older than $DAYS days   : $DEST_DIR "
find $DEST_DIR -name '*.gz' -mtime +$DAYS -delete
echo -e "\n$(date) logs Archival & Backup Completed successfully "
