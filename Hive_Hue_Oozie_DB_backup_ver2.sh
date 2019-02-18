#!bin/bash
#hbabu@mapr.com
#Script to take the Mysql back
#source /opt/mapr/health_check_Scripts/hive_scripts/hive_conf_properties.sh

clustername=$(cat /opt/mapr/conf/mapr-clusters.conf | grep -v ^# | head -1 | cut -d" " -f1)
DATE=$(date '+%Y-%m-%d-%H-%M-%S')
logfile=/opt/mapr/logs/managed_services/$(basename $0).log.${DATE}
mkdir -p $(dirname $logfile)

#DB Parameters
HIVE_DB_SCHEMA_NAME=hive
HIVE_DB_USR=hive
HIVE_DB_PWD=mapr
########################
HUE_DB_SCHEMA_NAME=hue
HUE_DB_USR=hue
HUE_DB_PWD=mapr
########################
OOZIE_DB_SCHEMA_NAME=oozie
OOZIE_DB_USR=oozie
OOZIE_DB_PWD=mapr


#Please provide the no.of Days to maintains logs backup . previous logs will be zipped/cleared
BKP_DAYS=60
#Path to mainitain DB_Bakups
DATE1=$(date '+%Y-%m-%d')
BACKUP_DIR=/mapr/${clustername}/managed_services/mapr_db_bkps/$DATE1
if [ ! -d $BACKUP_DIR ];then
mkdir -p $BACKUP_DIR
fi

#Clearing Old_Backups:
echo -e "Clearing Old_Backups....\n" >> $logfile
find $BACKUP_DIR -type f -name '*.sql' -mtime +$BKP_DAYS -exec rm {} \;
echo -e "Old_Backups before $BKP_DAYS days cleared successfully ....\n" >> $logfile
echo -e "Backup Activity Completed.....  Please Validate" >> $logfile


#Hive Metastore:
hive()
{
  local hive_host=$(maprcli node list -columns csvc | egrep "hivemeta" | awk '{print $1}')
  echo -e "Starting Hive Metastore DB-Backup ---> $BACKUP_DIR" >> $logfile
  echo -e "---------------------------------------" >> $logfile
  echo -e "mysqldump -h ${hive_host} --databases $HIVE_DB_SCHEMA_NAME -u $HIVE_DB_USR -p$HIVE_DB_PWD>> $BACKUP_DIR/mapr_hive_db_dump-${DATE}.sql"  >> $logfile
  mysqldump -h ${hive_host} --databases $HIVE_DB_SCHEMA_NAME -u $HIVE_DB_USR -p$HIVE_DB_PWD>> $BACKUP_DIR/mapr_hive_db_dump-${DATE}.sql
  echo -e "Hive DB-Backup Completed .....\n" >> $logfile
}

#Hue:
hue()
{
  local hue_host=$(maprcli node list -columns csvc | egrep -i "hue" | awk '{print $1}'| head -n 1)
  CMD="find /opt/mapr -maxdepth 2 -type d -name 'hue-[0-9].[0-9]*' -exec ls -dv '{}' ';' 2>/dev/null | sort --version-sort | tail -n 1 | cut -d'/' -f4-"
  HUE_VERSION=$(clush -w ${hue_host} ${CMD} | cut -d'/' -f2-)
  echo -e "Starting Hue DB-Backup\t --->  $BACKUP_DIR" >> $logfile
  echo -e "---------------------------------------" >> $logfile
  echo -e "clush -w ${hue_host} 'source /opt/mapr/hue/${HUE_VERSION}/build/env/bin/activate; hue dumpdata > $BACKUP_DIR/dump-hue-${DATE}.json; deactivate'" >> $logfile
  clush -w ${hue_host} "source /opt/mapr/hue/${HUE_VERSION}/build/env/bin/activate; hue dumpdata > $BACKUP_DIR/dump-hue-${DATE}.json; deactivate"
  echo -e "mysqldump -h ${hue_host} --databases $HUE_DB_SCHEMA_NAME -u$HUE_DB_USR -p$HUE_DB_PWD  > $BACKUP_DIR/mapr_hue_db_backup-${DATE}.sql" >> $logfile
  mysqldump -h ${hue_host} --databases $HUE_DB_SCHEMA_NAME  -u $HUE_DB_USR -p$HUE_DB_PWD  > $BACKUP_DIR/mapr_hue_db_backup-${DATE}.sql
  echo -e "Hue DB-Backup Completed .....\n" >> $logfile
}


oozie()
{
  local oozie_host=$(maprcli node list -columns csvc | egrep "oozie" | awk '{print $1}')
  echo -e "Starting Oozie Backup ---> $BACKUP_DIR" >> $logfile
  echo -e "---------------------------------------" >> $logfile
  echo -e "mysqldump -h ${oozie_host} --databases $OOZIE_DB_SCHEMA_NAME -u $OOZIE_DB_USR -p$OOZIE_DB_PWD>> $BACKUP_DIR/mapr_oozie_db_dump-${DATE}.sql"  >> $logfile
  mysqldump -h ${oozie_host} --databases $OOZIE_DB_SCHEMA_NAME -u $OOZIE_DB_USR -p$OOZIE_DB_PWD>> $BACKUP_DIR/mapr_oozie_db_dump-${DATE}.sql
  echo -e "oozie DB-Backup Completed .....\n" >> $logfile
}


#Please call the Required Functions based on Environment to take backup. Disable the fuctions not required to take backup.
#Available Functions : hive,hue,oozie
hive
hue
oozie
