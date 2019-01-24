#!/bin/bash
#hbabu@mapr.com
#Script To take backup of various hadoop configurations & its ecosystems.
##mapr_config_dumps  Job execution @ 01:30 AM CST
#30 01 * * * /opt/mapr/health_check_Scripts/mapr_configs_dump.sh

clustername=$(cat /opt/mapr/conf/mapr-clusters.conf | grep -v ^# | head -1 | cut -d" " -f1)
IP_ADD=$(clush -a date | awk -F':' '{print $1}')
DATE=$(date '+%Y-%m-%d-%H-%M-%S')
DATE1=$(date '+%Y-%m-%d')
logfile=/opt/mapr/logs/managed_services/$(basename $0).log.${DATE}
mkdir -p $(dirname $logfile)
BACKUP_DIR="/mapr/${clustername}/managed_services/mapr_conf_bkps/$DATE1"
LOCAL_BKP="/var/tmp/mapr_backup_configs_$DATE1.tgz"
if [ -d $BACKUP_DIR ];then
:
else
mkdir -p $BACKUP_DIR
fi
#TAR_FILE="${BACKUP_DIR}/$(hostname).maprbackup.${DATE1}.tgz"

#Files to take backup
HOSTID=hostid
HOST_NAME=hostname
BUILD_VERSION=MapRBuildVersion
CONFIGS=conf
ROLES=roles
HADOOP_CONFIGS=hadoop/hadoop-2.7.0/etc/hadoop/
HTTPS_CONF=$(find /opt/mapr/httpfs/httpfs-1.0/ -type f -name '*.xml' | cut -d'/' -f4-)
ZOOKEEPER_DATA=zkdata

#EchoSystem Components
HIVE=$(find /opt/mapr -maxdepth 2 -type d -name 'hive-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4-)
DRILL=$(find /opt/mapr -maxdepth 2 -type d -name 'drill-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4-)
SQOOP=$(find /opt/mapr -maxdepth 2 -type d -name 'sqoop-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4-)
SPARK=$(find /opt/mapr -maxdepth 2 -type d -name 'spark-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4-)
HUE=$(find /opt/mapr -maxdepth 2 -type d -name 'hue-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4-)
#FLUME=$(find /opt/mapr -maxdepth 2 -type d -name 'flume-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4)
#PIG=$(find /opt/mapr -maxdepth 2 -type d -name 'pig-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4)
#IMPALA=$(find /opt/mapr -maxdepth 2 -type d -name 'impala-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4)
#OOZIE=$(find /opt/mapr -maxdepth 2 -type d -name 'oozie-[0-9].[0-9]*' -exec ls -dv '{}' ';' | sort --version-sort | tail -n 1 | cut -d'/' -f4)

echo -e "#Configurations Backup Started ---> $BACKUP_DIR\n" >> $logfile
#EXEC_CMD="cd /opt/mapr/; tar -czf ${LOCAL_BKP} $HOSTID $HOST_NAME $BUILD_VERSION $CONFIGS $ROLES $HIVE/conf $DRILL/conf $SQOOP/conf $SPARK/conf $HUE/desktop/conf/ $HTTPS_CONF $HADOOP_CONFIGS $ZOOKEEPER_DATA"
EXEC_CMD="cd /opt/mapr/; tar fczP ${LOCAL_BKP} $HOSTID $HOST_NAME $BUILD_VERSION $CONFIGS $ROLES $HIVE/conf $DRILL/conf $SQOOP/conf $SPARK/conf $HUE/desktop/conf/ $HTTPS_CONF $HADOOP_CONFIGS $ZOOKEEPER_DATA"
echo -e "clush -a $EXEC_CMD\n" >> $logfile
clush -a $EXEC_CMD > /dev/null 2>&1

for i in $IP_ADD
do
  clush -w $i --rcopy $LOCAL_BKP --dest $BACKUP_DIR > /dev/null 2>&1
  clush -w $i rm $LOCAL_BKP > /dev/null 2>&1

#Cluster_Details
#1.
H_CONF_IN=$(hadoop conf)
H_CONF_OP="${BACKUP_DIR}/hadoop_conf_${DATE1}.txt"
echo -e "hadoop conf > $H_CONF_OP\n" >> $logfile
if [ -f "$H_CONF_OP" ];then
:
else
  echo "$H_CONF_IN" > "$H_CONF_OP"
fi

#2.
maprcli_config_in=$(maprcli config load -json)
maprcli_config_op="${BACKUP_DIR}/maprcli_config_${DATE1}.txt"
echo -e "maprcli config load -json > $maprcli_config_op\n" >> $logfile

if [ -f "$maprcli_config_op" ];then
  :
else
  echo "$maprcli_config_in" > "$maprcli_config_op"
fi

#3.
mapr_rpms_in=$(clush -aB 'rpm -qa | grep mapr | sort')
mapr_rpms_out="${BACKUP_DIR}/mapr_rpms_${DATE1}.txt"
echo -e "clush -aB 'rpm -qa | grep mapr | sort' > $maprcli_config_op\n" >> $logfile
if [ -f "$mapr_rpms_out" ];then
  :
else
  echo "$mapr_rpms_in" > "$mapr_rpms_out"
fi
