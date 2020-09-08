#!/bin/bash

source /env.sh

if [ -z $GBASEDBTDIR ]; then
  echo "GBASEDBTDIR not exists"
  exit 1;
fi

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
  chown gbasedbt:gbasedbt $GBASEDBTDIR/logs $GBASEDBTDIR/storage
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

main() {
  set_gbasedbt_password
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
