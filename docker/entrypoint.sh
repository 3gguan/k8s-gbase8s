#!/bin/bash

#引入环境变量
import_env() {
  source /env.sh

  if [ -z $GBASEDBTDIR ]; then
    echo "GBASEDBTDIR not exists"
    exit 1;
  fi
}

#初始化数据库实例时创建dbspace
create_dbspaces() {
  for i in $DBSPACES;
  do
    touch $GBASEDBTDIR/storage/$i && chmod 660 $GBASEDBTDIR/storage/$i && chown gbasedbt:gbasedbt $GBASEDBTDIR/storage/$i
  done
}

#初始化dbspace
init_dbspaces() {
  for i in $DBSPACES;
  do
    if [ $i != "rootdbs" ]; then
    onspaces -c -d $i -p $GBASEDBTDIR/storage/$i -o 0 -s 65536
    fi
  done
}

#初始化时需要创建的dbspace
DBSPACES="rootdbs plogdbs llogdbs tmpdbs01 tmpdbs02 datadbs01 datadbs02 datadbs03 datadbs04 datadbs05 datadbs06 datadbs07 datadbs08"

#修改用户及用户组
change_permissions() {
  chown gbasedbt:gbasedbt $GBASEDBTDIR/logs $GBASEDBTDIR/storage $GBASEDBTDIR/etc/onconfig.ol_gbasedbt_1 $GBASEDBTDIR/etc/sqlhosts.ol_gbasedbt_1
}

#设置gbasedbt的密码，由GBASEDBT_PASSWORD指定，默认为gbasedbt
set_gbasedbt_password() {
  temp_password=${GBASEDBT_PASSWORD:-"gbasedbt"} 
  echo -e "$temp_password\n$temp_password" | passwd gbasedbt
}

#检查oninit是否还存在
check_health() {
  if [ `ps -ef | grep oninit | grep -v grep | wc -l` -gt 2 ]; then
    return 1
  else
    return 0
  fi
}

#准备配置文件，用于外部挂载配置文件到容器内。
#如果ONCONFIG_FILE_NAME SQLHOSTS_FILE_NAME指定了配置文件的位置，
#就拷贝指定的配置文件到$GBASEDBTDIR/etc/下，并修改env.sh中配置文件的路径和名称
#从onconfig文件中读取数据库实例名，修改env.sh中的对应变量
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

#main函数
main() {

  #设置gbasedbt密码
  set_gbasedbt_password

  #引入环境变量
  import_env

  #准备配置文件
  prepare_config_file
  
  #重新引入环境变量
  import_env

  #修改用户及用户组
  change_permissions

  #如果rootdbs已经存在，表示数据库实例已经初始化过，直接启动oninit
  #如果不存在，就需要初始化数据库实例
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

  #定期检查oninit是否存在，如果不存在，脚本退出，整个容器退出
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

#关闭oninit，并退出脚本的执行
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

#监控两个信号，如果收到SIGINT或SIGTERM，正常关闭oninit，并退出
trap "echo \"RECV SIGINT\"; close_all" SIGINT
trap "echo \"RECV SIGTERM\"; close_all" SIGTERM

main
