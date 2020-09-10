#!/bin/bash

import_env() {
  source /env.sh

  if [ -z $GBASEDBTDIR ]; then
    echo "GBASEDBTDIR not exists"
    exit 1;
  fi
}

create_dbspaces() {
  for i in $DBSPACES;
  do
    touch $GBASEDBTDIR/storage/$i && chmod 660 $GBASEDBTDIR/storage/$i && chown gbasedbt:gbasedbt $GBASEDBTDIR/storage/$i
  done
}

init_dbspaces() {
  for i in $DBSPACES;
  do
    if [ $i != "rootdbs" ]; then
    onspaces -c -d $i -p $GBASEDBTDIR/storage/$i -o 0 -s 65536
    fi
  done
}

DBSPACES="rootdbs plogdbs llogdbs tmpdbs01 tmpdbs02 datadbs01 datadbs02 datadbs03 datadbs04 datadbs05 datadbs06 datadbs07 datadbs08"

change_permissions() {
  chown gbasedbt:gbasedbt $GBASEDBTDIR/logs $GBASEDBTDIR/storage $GBASEDBTDIR/etc/onconfig.ol_gbasedbt1210_1 $GBASEDBTDIR/etc/sqlhosts.ol_gbasedbt1210_1
}

set_gbasedbt_password() {
  temp_password=${GBASEDBT_PASSWORD:-"gbasedbt"} 
  echo -e "$temp_password\n$temp_password" | passwd gbasedbt
}

check_health() {
  if [ `ps -ef | grep oninit | grep -v grep | wc -l` -gt 2 ]; then
    return 1
  else
    return 0
  fi
}

prepare_config_file() {
  if [ -n "$ONCONFIG_FILE_NAME" ]; then
    if [ -f $ONCONFIG_FILE_NAME ]; then
      onconfig_file=${ONCONFIG_FILE_NAME##*/}
      \cp $ONCONFIG_FILE_NAME $GBASEDBTDIR/etc/$onconfig_file
      chown gbasedbt:gbasedbt $GBASEDBTDIR/etc/$onconfig_file
      sed -i "0,/ONCONFIG=*.*/s/ONCONFIG=*.*/ONCONFIG=$onconfig_file/" /env.sh
      temp=`sed -n "/^\s*DBSERVERNAME/p" $GBASEDBTDIR/etc/$onconfig_file` 
      sed -i "0,/GBASEDBTSERVER=*.*/s/GBASEDBTSERVER=*.*/GBASEDBTSERVER=${temp##* }/" /env.sh
    else
      echo "onconfig file not exists"
    fi
  fi
  if [ -n "$SQLHOSTS_FILE_NAME" ]; then
    if [ -f $SQLHOSTS_FILE_NAME ]; then
      sqlhosts_file=${SQLHOSTS_FILE_NAME##*/}
      \cp $SQLHOSTS_FILE_NAME $GBASEDBTDIR/etc/$sqlhosts_file
      chown gbasedbt:gbasedbt $GBASEDBTDIR/etc/$sqlhosts_file
      sed -i "0,/GBASEDBTSQLHOSTS=*.*/s/GBASEDBTSQLHOSTS=*.*/GBASEDBTSQLHOSTS=\$GBASEDBTDIR\/etc\/$sqlhosts_file/" /env.sh
    else
      echo "sqlhosts file not exists"
    fi
  fi
}

main() {
  set_gbasedbt_password
  import_env
  prepare_config_file
  import_env
  change_permissions

  if [ -f $GBASEDBTDIR/storage/rootdbs ]; then
    oninit -vwy
  else
    create_dbspaces
    oninit -iwvy
    init_dbspaces
    onmode -ky
    onclean -ky
    oninit -vwy
  fi

  while true
  do
    sleep 10 & wait
    check_health
    if [ $? == 0 ]; then
      echo "oninit exit"
      exit 0
    fi
  done
}

close_all()
{
  onmode -ky
  onclean -ky
  for i in `ps -ef|grep sleep|grep -v grep|awk '{print $2}'`
  do
    kill $i
  done
  exit 0
}

trap "echo \"RECV SIGINT\"; close_all" SIGINT
trap "echo \"RECV SIGTERM\"; close_all" SIGTERM

main
