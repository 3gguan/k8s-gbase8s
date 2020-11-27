#!/bin/bash

#引入环境变量
import_env() {
  source /env.sh

  if [ -z $GBASEDBTDIR ]; then
    echo "GBASEDBTDIR not exists"
    exit 1;
  fi
}

#设置gbasedbt的密码，由GBASEDBT_PASSWORD指定，默认为gbasedbt
set_gbasedbt_password() {
  temp_password=${GBASEDBT_PASSWORD:-"gbasedbt"} 
  echo -e "$temp_password\n$temp_password" | passwd gbasedbt
}

#检查oninit是否还存在
check_health() {
  sw=`cat check.conf`
  if [ "$sw" == "1" ]; then
    if [ `ps -ef | grep oncmsm | grep -v grep | wc -l` -eq 1 ]; then
      return 1
    else
      return 0
    fi
  else
    return 1
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
      temp=`sed -n "/^[[:space:]]*DBSERVERNAME[[:space:]]*/p" $GBASEDBTDIR/etc/$onconfig_file` 
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

modify_server_name() {
	temp_name_host=`hostname`
	temp_name=${temp_name_host//-/_}
	sed -i "0,/GBASEDBTSERVER=*.*/s/GBASEDBTSERVER=*.*/GBASEDBTSERVER=$temp_name/" /env.sh
	sed -i "0,/^[[:space:]]*DBSERVERNAME*.*/s/^[[:space:]]*DBSERVERNAME*.*/DBSERVERNAME $temp_name/" $GBASEDBTDIR/etc/$ONCONFIG
	sed -i "0,/^[[:space:]]*DBSERVERALIASES*.*/s/^[[:space:]]*DBSERVERALIASES*.*/DBSERVERALIASES dr_$temp_name/" $GBASEDBTDIR/etc/$ONCONFIG
	echo "$temp_name onsoctcp $temp_name_host 9088" > $GBASEDBTSQLHOSTS
	echo "dr_$temp_name drsoctcp $temp_name_host 19088" >> $GBASEDBTSQLHOSTS
	#sed -i "/\${DBSERVERNAME}/s/\${DBSERVERNAME}/$temp_name/g" $GBASEDBTSQLHOSTS
}

#main函数
main() {

  #设置gbasedbt密码
  set_gbasedbt_password

  #引入环境变量
  import_env

  #准备配置文件
#  prepare_config_file

  #修改服务名
  #if [ -n "$AUTO_SERVER_NAME" -a "$AUTO_SERVER_NAME" == "1" ]; then
  #  modify_server_name
  #fi

  if [ -n "$START_MANUAL" -a "$START_MANUAL" == "1" ]; then
    echo "0" > check.conf
    echo "start cm manual" 
  else
    echo "start cm auto"
    su gbasedbt -c "oncmsm -c $GBASEDBTDIR/etc/cfg.cm"
  fi
  

  #定期检查oninit是否存在，如果不存在，脚本退出，整个容器退出
  while true
  do
    sleep 10 & wait $!
    check_health
    if [ $? == 0 ]; then
      echo "cm exit"
      exit 0
    fi
  done
}

#关闭oninit，并退出脚本的执行
close_all()
{
  tmp=`sed -n "/^[[:space:]]*NAME[[:space:]]*/p" $GBASEDBTDIR/etc/cfg.cm`
  su gbasedbt -c "oncmsm -k ${tmp##*[[:space:]]}"
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
