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
  sw=`cat check.conf`
  if [ "$sw" == "1" ]; then
    if [ `ps -ef | grep oninit | grep -v grep | wc -l` -gt 2 ]; then
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
      sed -i "0,/GBASEDBTSERVER=*.*/s/GBASEDBTSERVER=*.*/GBASEDBTSERVER=${temp##*[[:space:]]}/" /env.sh
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

#测试链接主节点，$1:主节点服务地址
test_connect() {
  echo $1
  for ((i=0; i<20; i++))
  do
    echo "try to connect to primary"
	echo "curl -s --connect-timeout 3 $1:$SERVICE_PORT/hac/connect"
	curl -s --connect-timeout 3 $1:$SERVICE_PORT/hac/connect
    ret=$?
    echo $ret 
    if [ "$ret" = "0" ]; then
      return 0 
    fi
    sleep 5
  done
  return 1
}

# 从json串中获取值。$1:json串 $2:key
get_json_value() {
  python -c "import json,sys; obj = json.loads(sys.argv[1]); print obj[sys.argv[2]].encode('utf-8')" "$1" "$2"
}

# 根据对端ip生存一条hostfile. $1:对端ip
generate_hostfile_line() {
  hn=`python -c "
import sys,socket
try: 
	hn = socket.gethostbyaddr(sys.argv[1])[0]
except Exception, e:
	hn = sys.argv[1]
print hn
" "$1"`
  echo "$hn gbasedbt"
}

rss_primary_init() {
  #使成为主节点
  echo "i am primary"
}

rss_secondary_init() {
  echo "i am secondary"

  SERVICE_PORT=8000

  #关闭辅节点服务
  onmode -ky

  #尝试链接主节点，每隔5s重连，最多重连次数20次
  if [ -n "$PRIMARY_SERVER_NAME" ]; then
    #根据PRIMARY_SERVER_NAME变量值查找sqlhost中对应的service name
	SERVICE_ADDR=`sed -n "/^[[:space:]]*$PRIMARY_SERVER_NAME[[:space:]]*/p" $GBASEDBTDIR/etc/$sqlhosts_file | awk '{print $3}'`
	test_connect $SERVICE_ADDR
	if [ "$?" != "0" ]; then
      exit 0
	fi
  else
	echo "PRIMARY_SERVER_NAME not exists"
    exit 0
  fi

  #添加互信
  SERVER_NAME=`sed -n "/^[[:space:]]*DBSERVERNAME[[:space:]]*/p" $GBASEDBTDIR/etc/$ONCONFIG | awk '{print $2}'`
  echo "---------============"
  echo $SERVER_NAME
  if [ -n "$SERVER_NAME" ]; then
	echo "curl -s -v --connect-timeout 3 $SERVICE_ADDR:$SERVICE_PORT/hac/addTrustHost -X POST -d '{"serverName": "'$SERVER_NAME'"}' --header "Content-Type: application/json""
    temp=`curl -s -v --connect-timeout 3 $SERVICE_ADDR:$SERVICE_PORT/hac/addTrustHost -X POST -d '{"serverName": "'$SERVER_NAME'"}' --header "Content-Type: application/json"`
	if [[ $temp == \{*} ]]; then
	  ret_code=`get_json_value "$temp" "code"`
	  if [ $ret_code != 0 ]; then
	    get_json_value "$temp" "message"
		exit 0
	  else
	    SECONDARY_IP=`get_json_value "$temp" "data"`
        hostfile_line=`generate_hostfile_line "$SECONDARY_IP"`
		echo $hostfile_line > $GBASEDBTDIR/etc/hostfile
      fi
	else
	  echo "add trust host failed"
	  exit 0
	fi
  else
    echo "SERVER_NAME not exists"
    exit 0
  fi

  #通知主节点添加本机为辅节点

  #从主节点下载备份文件并恢复
  echo "222"
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
  prepare_config_file

  #修改服务名
  if [ -n "$AUTO_SERVER_NAME" -a "$AUTO_SERVER_NAME" == "1" ]; then
    import_env
    modify_server_name
  fi
  
  #重新引入环境变量
  import_env

  #修改用户及用户组
  change_permissions

  #启动配置服务
  nohup python /server/manage.py runserver 0.0.0.0:8000 &

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

#  if [ "$SERVER_TYPE" = "primary" ]; then
    #主节点初始化
#	rss_primary_init
#  elif [ "$SERVER_TYPE" = "secondary" ]; then
    #辅节点初始化
#    rss_secondary_init
#  fi

  #定期检查oninit是否存在，如果不存在，脚本退出，整个容器退出
  while true
  do
    sleep 10 & wait $!
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
