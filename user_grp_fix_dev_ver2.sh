#!/bin/bash
#hbabu@mapr.com
#Script To Fix User Directory user and group permissions for accessing mapr cluster.
#exec > >(tee -i "$logfile") 2>&1
##User Directory Fix Job execution @ 12:30 AM CST
#30 12 * * * /opt/mapr/health_check_Scripts/hive_scripts/Usr_Dir_Fix.sh

DATE=$(date '+%Y-%m-%d-%H-%M-%S')
logfile=/opt/mapr/logs/managed_services/$(basename $0).log.${DATE}
mkdir -p $(dirname $logfile)
echo "Date=$DATE" >> $logfile
start_time=$(date +%s)

clustername=$(cat /opt/mapr/conf/mapr-clusters.conf | grep -v ^# | head -1 | cut -d" " -f1)
#Posix UserName
USR=svcmr4y
#Posix Groups
GRP1=bdmdevdmgt
GRP2=bdmdevdsvc
GRP3=bdmdevinss
GRP4=bdmdevcorp
GRP5=bdmdevclms
GRP6=mapr
#Posix permissions
PERMS1=3775
PERMS2=2775
#Posix Directory Paths
path1="/mapr/${clustername}/im_dva"
path2="/mapr/${clustername}/im_dvb"
path3="/mapr/${clustername}/im_dvc"
path4="/mapr/${clustername}/im_dvd"
path5="/mapr/${clustername}/im_dve"
path6="/mapr/${clustername}/etl"

#File/Dir to Exclude
exclude1=initial_load

usr_dir_grp_perm()
{
path=$1
USR=$2
GRP=$3
#PERMS=$4
DIR_LIST1=$(find $path -mindepth 0 -maxdepth 1 -print)
DIR_LIST2=$(find $path -mindepth 2 -maxdepth 2 -print)
echo -e "-------------------------------\n" >> $logfile
echo -e "User_Group_Permissions Check : $path" >> $logfile
echo -e "\nCheck 1:Permissions 3775 for the first two levels of folders" >> $logfile
for i in $DIR_LIST1
do
    file="$i"
    perms=$(stat -c "%a" "$i")
    usr=$(stat -c "%U" "$i")
    grp=$(stat -c "%G" "$i")
    if [ -e "$file" ] && [ "$usr" == "$USR" ] && [ "$grp == $GRP" ] && [ "$perms" == "$PERMS1" ];
    then
      echo -e "$perms $usr $grp $file" >> $logfile
    else
      echo -e "\nPermissions Mismatch :$perms $usr $grp $file" >> $logfile
      echo -e "chown $USR:$GRP $file" >> $logfile
      chown $USR:$GRP $file
      echo -e "chmod $PERMS1 $file\n" >> $logfile
      chmod $PERMS1 $file
    fi
  done

echo -e "\nCheck 2: For all lower levels, the permissions should be 2775" >> $logfile
  for j in $DIR_LIST2
  do
    file="$j"
    perms=$(stat -c "%a" "$j")
    usr=$(stat -c "%U" "$j")
    grp=$(stat -c "%G" "$j")
    if [ -e "$file" ] && [ "$usr" == "$USR" ] && [ "$grp == $GRP" ] && [ "$perms" == "$PERMS2" ];
    then
      echo -e "$perms $usr $grp $file" >> $logfile
    else
      echo -e "\nPermissions Mismatch:$perms $usr $grp $file" >> $logfile
      echo -e "chown -R $USR:$GRP $file" >> $logfile
      chown -R $USR:$GRP $file
      echo -e "chmod -R $PERMS2 $file\n" >> $logfile
      chmod -R $PERMS2 $file
    fi
  done
}

usr_dir_grp_perm1()
{
path=$1
USR=$2
GRP=$3
#PERMS=$4
DIR_LIST1=$(find $path -mindepth 0 -maxdepth 1 -print)
DIR_LIST2=$(find $path -mindepth 2 -maxdepth 2 -print | egrep -v "$exclude1")
echo -e "-------------------------------\n" >> $logfile
echo -e "User_Group_Permissions Check : $path" >> $logfile
echo -e "Excluded Directory: $exclude1"
echo -e "\nCheck 1:Permissions 3775 for the first two levels of folders" >> $logfile
for i in $DIR_LIST1
do
    file="$i"
    perms=$(stat -c "%a" "$i")
    usr=$(stat -c "%U" "$i")
    grp=$(stat -c "%G" "$i")
    if [ -e "$file" ] && [ "$usr" == "$USR" ] && [ "$grp == $GRP" ] && [ "$perms" == "$PERMS1" ];
    then
      echo -e "$perms $usr $grp $file" >> $logfile
    else
      echo -e "\nPermissions Mismatch :$perms $usr $grp $file" >> $logfile
      echo -e "chown $USR:$GRP $file" >> $logfile
      chown $USR:$GRP $file
      echo -e "chmod $PERMS1 $file\n">> $logfile
      chmod $PERMS1 $file
    fi
  done

  for j in $DIR_LIST2
  do
    file="$j"
    perms=$(stat -c "%a" "$j")
    usr=$(stat -c "%U" "$j")
    grp=$(stat -c "%G" "$j")
    echo -e "\nCheck 2: For all lower levels, the permissions should be 2775" >> $logfile
    if [ -e "$file" ] && [ "$usr" == "$USR" ] && [ "$grp == $GRP" ] && [ "$perms" == "$PERMS2" ];
    then
      echo -e "$perms $usr $grp $file" >> $logfile
    else
      echo -e "\nPermissions Mismatch:$perms $usr $grp $file" >> $logfile
      echo -e "chown -R $USR:$GRP $file" >> $logfile
      chown -R $USR:$GRP $file
      echo -e "chmod -R $PERMS2 $file\n" >> $logfile
      chmod -R $PERMS2 $file
    fi
  done
}

#Function Call
usr_dir_grp_perm $path1 $USR $GRP1
#usr_dir_grp_perm $path2 $USR $GRP2
#usr_dir_grp_perm1 $path3 $USR $GRP3
#usr_dir_grp_perm $path4 $USR $GRP4
#usr_dir_grp_perm $path5 $USR $GRP5
#usr_dir_grp_perm $path6 $USR $GRP6

#To Set 2775 on all tmp folders (on all volumes)
chmod 2775 /mapr/$(clustername)/im_dv*/tmp


#####################
end_time=$(date +%s)
echo Execution time : $(expr $end_time - $start_time) s.
