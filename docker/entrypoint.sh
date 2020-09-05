#!/bin/bash

source /opt/gbase8s/env.sh

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

chown gbasedbt:gbasedbt $GBASEDBTDIR/etc/onconfig.ol_generaldata1210 $GBASEDBTDIR/etc/sqlhosts.ol_generaldata1210 $GBASEDBTDIR/logs $GBASEDBTDIR/storage

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

close_all()
{
  onmode -ky
  onclean -ky
  for i in `ps -ef|grep tail|grep -v grep|awk '{print $2}'`
  do
    kill $i
  done
  exit 0
}
trap "echo \"RECV SIGINT\"; close_all" SIGINT
trap "echo \"RECV SIGTERM\"; close_all" SIGTERM

while true
do
  tail -f /dev/null & wait
done
