id="1"
HOSTNAME=$(hostname)
server1="node1"
server2="node2"
server3="node3"
yum localinstall -y jdk-8u144-linux-x64.rpm
echo "export JAVA_HOME=/usr/java/jdk1.8.0_144/" >> /etc/profile
source /etc/profile
groupadd kafka
adduser -g kafka kafka
#wget http://apache.forsale.plus/kafka/1.1.0/kafka_2.12-1.1.0.tgz
#tar -xzf kafka_2.12-1.1.0.tgz
wget https://archive.apache.org/dist/kafka/0.8.2.2/kafka_2.10-0.8.2.2.tgz
tar -xzf kafka_2.10-0.8.2.2.tgz

mkdir -p /data/kafka/zookeeper/data; mkdir -p /data/kafka/kafka/kafka-logs
chown -R kafka:kafka /data/kafka/
cp -rf kafka_2.10-0.8.2.2 /opt/kafka; chown -R kafka:kafka /opt/kafka

cat > "/opt/kafka/config/zookeeper.properties" <<END
dataDir=/data/kafka/zookeeper/data
clientPort=2181
maxClientCnxns=0

server.1=$server1:2888:3888
server.2=$server2:2888:3888
server.3=$server3:2888:3888

initLimit=5
syncLimit=2
END
echo $id > /data/kafka/zookeeper/data/myid

cat > "/opt/kafka/config/server.properties" <<END
############################# Server Basics #############################
broker.id=$id
############################# Socket Server Settings #############################
port=9092
host.name=$HOSTNAME
advertised.host.name=$HOSTNAME
#advertised.port=9092
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
############################# Log Basics #############################
log.dirs=/data/kafka/kafka/kafka-logs
num.partitions=1
num.recovery.threads.per.data.dir=1
############################# Log Flush Policy #############################
#log.flush.interval.messages=10000
#log.flush.interval.ms=1000
############################# Log Retention Policy #############################
log.retention.hours=168
#log.retention.bytes=1073741824
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
############################# Zookeeper #############################
zookeeper.connect=node1:2181,node2:2181,node3:2181
zookeeper.connection.timeout.ms=6000
#group.initial.rebalance.delay.ms=0
END

cat > "/lib/systemd/system/kafka.service" <<END
[Unit]
Description=Kafka
Before=
After=network.target
 
[Service]
User=kafka
CHDIR= {{ data_dir }}
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
Restart=on-abort
 
[Install]
WantedBy=multi-user.target
END

cat > "/lib/systemd/system/zookeeper.service" <<END
[Unit]
Description=Zookeeper
Before=
After=network.target
 
[Service]
User=kafka
CHDIR= {{ data_dir }}
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
Restart=on-abort
 
[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
sed -i -e 's/-Xmx1G -Xms1G/-Xmx4G -Xms4G/g' /opt/kafka/bin/kafka-server-start.sh
sed -i -e 's/-Xmx512M -Xms512M/-Xmx1G -Xms1G/g' /opt/kafka/bin/zookeeper-server-start.sh
