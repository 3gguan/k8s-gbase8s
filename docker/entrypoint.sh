#!/bin/bash

#引入环境变量
import_env() {
  source /env.sh

  if [ -z $GBASEDBTDIR ]; then
    echo "GBASEDBTDIR not exists"
    exit 1;
  fi
}

create_dbspace_file() {
  touch $GBASEDBTDIR/storage/$1 
  chmod 660 $GBASEDBTDIR/storage/$1
  chown gbasedbt:gbasedbt $GBASEDBTDIR/storage/$1
}

to_kb() {
  case $1 in
  [0-9]*M)
    echo $(( ${1%M}*1024 ))
  ;;
  [0-9]*G)
    echo $(( ${1%G}*1024*1024 ))
  ;;
  [0-9]*)
    echo $1
  ;;
  [0-9]*K)
    echo $1
  ;;
  *)
    echo "error"
  esac
}

get_free_space() {
  path=$(echo $1 | sed -e 's/\//\\\//g')
  free=`onstat -d | sed -n "/**$path[[:space:]]*/p" | awk '{print $6}'`
  echo $(( $free*2 ))
}

modify_temp_dbspace() {
  n=`onstat -D | awk '{if($8~"T") print $10}'`

  for i in $n
  do
    if [ -n "$e" ]; then
      e=$e:$i
    else
      e=$i
    fi
  done
  onmode -wf DBSPACETEMP=$e
}

#初始化dbspaces
init_dbspaces() {
  #初始化plog space
  TEMP_SIZE=`to_kb 128M`
  if [ -n "$INIT_PLOG_SIZE" ]; then
    TEMP_SIZE=`to_kb $INIT_PLOG_SIZE` 
  fi
  if [ $TEMP_SIZE = "error" ]; then
    echo "INIT_PLOG_SIZE error" 
    return 1
  fi
  create_dbspace_file init_plog
  onspaces -c -P init_plog -p $GBASEDBTDIR/storage/init_plog -o 0 -s $TEMP_SIZE

  #初始化llog space
  TEMP_SIZE=`to_kb 128M`
  if [ -n "$INIT_LLOG_SIZE" ]; then
    TEMP_SIZE=`to_kb $INIT_LLOG_SIZE`
  fi
  if [ $TEMP_SIZE = "error" ]; then
    echo "INIT_LLOG_SIZE error"
    return 1
  fi
  create_dbspace_file init_llog
  onspaces -c -d init_llog -p $GBASEDBTDIR/storage/init_llog -o 0 -s $TEMP_SIZE
  free=`get_free_space $GBASEDBTDIR/storage/init_llog`
  onparams -a -d init_llog -s $free
  
  #初始化temp space
  TEMP_SIZE=`to_kb 64M`
  TEMP_COUNT=2
  if [ -n "$INIT_TEMP_SIZE" ]; then
    TEMP_SIZE=`to_kb $INIT_TEMP_SIZE`
  fi
  if [ $TEMP_SIZE = "error" ]; then
    echo "INIT_TEMP_SIZE error"
    return 1
  fi
  if [ -n "$INIT_TEMP_COUNT" ]; then
    TEMP_COUNT=$INIT_TEMP_COUNT
  fi
  for((i=0;i<$TEMP_COUNT;i++));
  do
    create_dbspace_file init_temp$i
    onspaces -c -d init_temp$i -t -p $GBASEDBTDIR/storage/init_temp$i -o 0 -s $TEMP_SIZE
  done

  #初始化data space
  TEMP_SIZE=`to_kb 256M`
  if [ -n "$INIT_DATA_SIZE" ]; then
    TEMP_SIZE=`to_kb $INIT_DATA_SIZE`
  fi
  if [ $TEMP_SIZE = "error" ]; then
    echo "INIT_DATA_SIZE error"
    return 1
  fi
  create_dbspace_file init_data
  onspaces -c -d init_data -p $GBASEDBTDIR/storage/init_data -o 0 -s $TEMP_SIZE

  #初始化blob space
  TEMP_SIZE=`to_kb 64M`
  TEMP_PAGE_SIZE=1
  if [ -n "$INIT_BLOB_SIZE" ]; then
    TEMP_SIZE=`to_kb $INIT_BLOB_SIZE`
  fi
  if [ $TEMP_SIZE = "error" ]; then
    echo "INIT_BLOB_SIZE error"
    return 1
  fi
  if [ -n "$INIT_BLOB_PAGE_SIZE" ]; then
    TEMP_PAGE_SIZE=$INIT_BLOB_PAGE_SIZE
  fi
  create_dbspace_file init_blob
  onspaces -c -b init_blob -g $TEMP_PAGE_SIZE -p $GBASEDBTDIR/storage/init_blob -o 0 -s $TEMP_SIZE

  #初始化sblob space
  TEMP_SIZE=`to_kb 64M`
  if [ -n "$INIT_SBLOB_SIZE" ]; then
    TEMP_SIZE=`to_kb $INIT_SBLOB_SIZE`
  fi
  if [ $TEMP_SIZE = "error" ]; then
    echo "INIT_SBLOB_SIZE error"
    return 1
  fi
  create_dbspace_file init_sblob
  onspaces -c -S init_sblob -p $GBASEDBTDIR/storage/init_sblob -o 0 -s $TEMP_SIZE
}

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

  #如果rootdbs已经存在，表示数据库实例已经初始化过，直接启动oninit
  #如果不存在，就需要初始化数据库实例
  if [ -f $GBASEDBTDIR/storage/rootdbs ]; then
    oninit -vwy
  else
    create_dbspace_file rootdbs && oninit -iwvy && init_dbspaces
    #create_dbspaces && oninit -iwvy && init_dbspaces && onmode -ky && onclean -ky && oninit -vwy
  fi
  
  if [ $? != 0 ]; then
    exit 0
  fi

  #修改DBSPACETEMP环境变量
  modify_temp_dbspace

  #启动配置服务
  nohup python /server/manage.py runserver 0.0.0.0:8000 &

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
