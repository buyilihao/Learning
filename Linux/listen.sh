#/bin/bash
#日志记录时间
echo `date +"%Y-%m-%d %H:%M:%S"`  >> /root/log/xxx.log
check() {
	RESULT=$(curl http://localhost:8080/checkpreload.htm)
	if [ “$RESULT” != "success" ] ; then
		#重启
		echo "restart process....." >> /root/log/xxx.log
		/root/start.sh
	else
		#写入日志
		echo "runing....."$RESULT  >> /root/log/xxx.log
	fi
}
check

# 第二步
crontab -e

#内容 每分钟执行一次
* * * * * /bin/sh  /root/listen.sh

tail -f ./log/xxx.log
