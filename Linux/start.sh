# 如果进程存在杀掉
ps -ef | grep xxx-0.0.1-SNAPSHOT.jar |grep -v grep| cut -c 9-15 | xargs kill -9
nohup java -Xms2048m -Xmx2048m -XX:MaxMetaspaceSize=128m -jar /root/xxx-0.0.1-SNAPSHOT.jar >/root/log/xxx.log 2>&1 &