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
BACKUP_DIR="/opt/mapr/backups/$DATE1"
mkdir -p $(dirname $logfile)
SPARK_PACKAGE_DIR="/opt/mapr/Downloads/spark-packages"

#Stopping of Spark Services
SPARK_HOST=$(maprcli node list -columns csvc | egrep "spark" | awk '{print $1}')
echo -e "Stopping Spark Service" >> $logfile
echo -e "maprcli node services -nodes ${SPARK_HOST} -name spark-historyserver -action stop">> $logfile
maprcli node services -nodes ${SPARK_HOST} -name spark-historyserver -action stop

##3.Creating Repository
if [ ! -d $SPARK_PACKAGE_DIR ];then
  echo -e "#Creating SPARK_PACKAGE Directory : $SPARK_PACKAGE_DIR" >> $logfile
  mkdir -p $SPARK_PACKAGE_DIR
fi

cd $SPARK_PACKAGE_DIR
#Downloading Spark packages #pacakges from the location Home--> ecosystem --> rpm --> spark --> 2.4.0
echo "Downloading the package mapr-saprk" >> $logfile
wget https://sftp.mapr.com/Home/ecosystem/rpm/spark/2.4.0/mapr-spark-2.4.0.3.201911210315-1.noarch.rpm
echo "Downloaded the mapr-spark successfully" >> $logfile
sleep 5
echo "Downloading the package mapr-saprk-historyserver" >> $logfile
wget https://sftp.mapr.com/Home/ecosystem/rpm/spark/2.4.0/mapr-spark-historyserver-2.4.0.3.201911210315-1.noarch.rpm
echo "Downloaded the spark-historyserver successfully" >> $logfile
sleep 5
echo "Downloading the package mapr-sparkmaster" >> $logfile
wget https://sftp.mapr.com/home/ecosystem/rpm/spark/2.4.0/mapr-spark-master-2.4.0.3.201911210315-1.noarch.rpm
echo "Downloaded the spark-master successfully" >> $logfile
sleep 5
echo "Downloading the package mapr-spark thrift server" >> $logfile
wget https://sftp.mapr.com/home/ecosystem/rpm/spark/2.4.0/mapr-spark-thriftserver-2.4.0.3.201911210315-1.noarch.rpm
echo "Downloaded the spark thrift server successfully" >> $logfile
sleep 5


#4. update mapr-spark
spark_yum_update="sudo yum update -y mapr-spark mapr-spark-historyserver"
RUN_CONFIGURE="sudo /opt/mapr/server/configure.sh -R"

for host in $SPARK_HOST
do
  echo -e "clush -a $host --copy $SPARK_PACKAGE_DIR" >> $logfile
  clush -a $host --copy $SPARK_PACKAGE_DIR
  echo -e "clush -w $host "cd $SPARK_PACKAGE_DIR ; $spark_yum_update ;sleep 10;$RUN_CONFIGURE"" >> $logfile
  clush -w $host "cd $SPARK_PACKAGE_DIR ; $spark_yum_update ;sleep 10;$RUN_CONFIGURE"
done


#Finding Differences betwen the backup file & current file.
#please provide backup file spark-defaults.conf
echo -e "Finding Difference between OLD and new spark-defaults.conf file" >> $logfile
read -p "Enter backup spark-defaults.conf path: " $OLD_CONFIG_FILE
if [ ! -f $OLD_CONFIG_FILE ]
then
  echo "Enter Correct Backup Path" >> $logfile
  exit 1
else
  SPARK=$(find /opt/mapr -maxdepth 2 -type d -name 'spark-[0-9].[0-9]*' -exec ls -dv '{}' ';' 2>/dev/null | sort --version-sort | tail -n 1)
  NEW_CONFIG_FILE="${SPARK}/conf/spark-defaults.conf"
  echo -e "diff --suppress-common-lines -y $OLD_CONFIG_FILE $NEW_CONFIG_FILE" >> $logfile
  diff --suppress-common-lines -y $OLD_CONFIG_FILE $NEW_CONFIG_FILE  | tee $logfile
  echo "Enter Correct Backup Path" >> $logfile
fi

echo -e "Patch Upgrade completed successfully please validate and confirm " >> $logfile





######
Do find the differences in the backup-config and present config, if no change fine.
check for the spark.yarn.dist.files property in spark-defaults.conf
edit  /opt/mapr/spark/spark-2.4.0/conf/spark-defaults.conf and add below option if missing
spark.yarn.dist.files /opt/mapr/spark/spark-2.4.0/conf/hbase-site.xml
#run configure.sh -R
sudo /opt/mapr/server/configure.sh -R
