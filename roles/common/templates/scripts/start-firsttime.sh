#!/bin/bash
set -e
echo ""

{% set cnt = groups['master'] | length | int %}
{% if cnt > 1 %}
# Start Zookeeper (Start it on every machine)
echo "starting zookeeper services"
{{FC_HOME}}/cfiles/crun zkServer.sh start
sleep 5
echo ""

# Starting journalnode
echo "starting journalnode"
crun hadoop-daemon.sh start journalnode 
sleep 5
echo ""

# formating namemnode of fcmaster1
echo "formating hadoop namenode of fcmaster1"
{{hadoop_bin_dir}}/hadoop namenode -format 
sleep 5
echo ""

# starting namemnode of fcmaster1
echo "starting hadoop namenode of fcmaster1"
{{hadoop_sbin_dir}}/hadoop-daemon.sh start namenode 
sleep 5
echo ""

# Boot Strap on Standby namenode node.
echo "Boot Strap on Standby namenode node"
ssh -T {{ groups['master'][1] }} << EOF 
{{hadoop_bin_dir}}/hdfs namenode -bootstrapStandby 
sleep 5
EOF
echo ""

echo "starting namenode node on fcmaster2"
ssh -T {{ groups['master'][1] }} << EOF 
{{hadoop_sbin_dir}}/hadoop-daemon.sh start namenode 
sleep 5
EOF
echo ""

# format the zookeeper
echo "formating zookeeper on fcmaster1"
{{hadoop_bin_dir}}/hdfs zkfc -formatZK 
sleep 5
echo ""

# starting zkfc
echo "starting zkfc in fcmaster1"
{{hadoop_sbin_dir}}/hadoop-daemon.sh start zkfc
sleep 5
echo ""

echo "starting zkfc in fcmaster2"
ssh -T {{ groups['master'][1] }} << EOF
{{hadoop_sbin_dir}}/hadoop-daemon.sh start zkfc
sleep 5
EOF
echo ""

# stopping hadoop
echo "stop hadoop"
{{hadoop_sbin_dir}}/stop-dfs.sh 
sleep 5
echo ""

# starting hadoop
echo "start hadoop"
{{hadoop_sbin_dir}}/start-dfs.sh 
sleep 10
echo ""

# creating spark hdfs directory
echo "creating hdfs directory"
{{hadoop_bin_dir}}/hdfs dfs -mkdir -p /spark/events
sleep 5
echo ""
sleep 10


# Start Elasticsearch (Start it on every machine)
echo "starting elasticsearch services"
{{FC_HOME}}/cfiles/crun "sleep 3&elasticsearch -d"
sleep 10
echo ""

# Start HBase
echo "starting hbase services"
{{hbase_bin_dir}}/start-hbase.sh
sleep 5
echo ""

# Start Spark
echo "starting spark fcmaster1"
{{spark_bin_dir}}/start-master.sh
sleep 5
echo ""

echo "starting spark fcmaster2"
ssh -T {{ groups['master'][1] }} << EOF
{{spark_bin_dir}}/start-master.sh
sleep 5
EOF
echo ""

echo "starting spark worker"
{{spark_bin_dir}}/start-slaves.sh
sleep 5
echo ""

echo "starting spark histroy server"
{{spark_bin_dir}}/start-history-server.sh
sleep 5
echo ""

# starting kafka
echo "starting kafka in master machine."
{% for host in groups['master'] %}
{% if host not in groups['slaves'] %}
ssh -T  {{ host }} << EOF
{{kafka_bin_dir}}/kafka-server-start.sh -daemon {{kafka_conf_dir}}/server.properties
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}

{% for host in groups['slaves'] %}
{% if host not in groups['master'] %}
ssh -T  {{ host }} << EOF
{{kafka_bin_dir}}/kafka-server-start.sh -daemon {{kafka_conf_dir}}/server.properties
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}
{% endif %}

{% if cnt == 1 %}
# formating namemnode
echo "formating hadoop namenode"
{{hadoop_bin_dir}}/hadoop namenode -format
sleep 5
echo ""

# starting hadoop
echo "starting hadoop services"
{{hadoop_sbin_dir}}/start-dfs.sh
sleep 5
echo ""

# creating spark hdfs directory
echo "creating hdfs directory"
{{hadoop_bin_dir}}/hdfs dfs -mkdir -p /spark/events
sleep 5
echo ""

# Start Zookeeper (Start it on every machine)
echo "starting zookeeper services"
{{FC_HOME}}/cfiles/crun zkServer.sh start
sleep 5
echo ""

sleep 10
# Start Elasticsearch (Start it on every machine)
echo "starting elasticsearch services"
{{FC_HOME}}/cfiles/crun elasticsearch -d; sleep 5
sleep 5
echo ""

# Start HBase
echo "starting hbase services"
{{hbase_bin_dir}}/start-hbase.sh
sleep 5
echo ""

# Start Spark
echo "starting spark services"
{{spark_bin_dir}}/start-all.sh
sleep 5
echo ""
 
# Start Spark histroy server
echo "starting spark histroy server"
{{spark_bin_dir}}/start-history-server.sh
sleep 5
echo ""

# start kafka
echo "starting kafka"
{% for host in groups['master'] %}
{% if host not in groups['slaves'] %}
ssh -T {{ host }} << EOF
{{kafka_bin_dir}}/kafka-server-start.sh -daemon {{kafka_conf_dir}}/server.properties
EOF
sleep 5
echo ""
{% endif %}
{% endfor %}

{% for host in groups['slaves'] %}
{% if host not in groups['master'] %}
ssh -T {{ host }} << EOF
{{kafka_bin_dir}}/kafka-server-start.sh -daemon {{kafka_conf_dir}}/server.properties
EOF
sleep 5
echo ""
{% endif %}
{% endfor %}
{% endif %}

sleep 2
mkdir {{home_directory}}/apps/
mkdir {{home_directory}}/streamsets_data
sudo docker login lab.formcept.com:7070 -u admin -p formcept100$
sudo docker run -d --net host --name nginx -v {{nginx_home_path}}/nginx.conf:/etc/nginx/nginx.conf -v {{home_directory}}/apps/:/apps/ --restart always nginx:alpine
sudo docker run -d --name ss -p 18630:18630 --restart always -v {{home_directory}}/streamsets_data/:/mnt/ lab.formcept.com:7070/fc-ss dc
sleep 3

echo "Starting cassandra"

crun {{cassandra_bin_dir}}/cassandra

sleep 30

echo "Starting Memcached"

{{memcached_home_path}}/bin/memcached -m 4096 -d

sleep 5

echo "Creating Topics"

{{kafka_bin_dir}}/kafka-topics.sh --create --zookeeper {% for node in groups['common'] %}{{ node }}:2181{% if not loop.last %},{% endif %}{% endfor %} --replication-factor 1 --partitions 1 --topic mecbot.activity
{{kafka_bin_dir}}/kafka-topics.sh --create --zookeeper {% for node in groups['common'] %}{{ node }}:2181{% if not loop.last %},{% endif %}{% endfor %} --replication-factor 1 --partitions 1 --topic mecbot.pulse
{{kafka_bin_dir}}/kafka-topics.sh --create --zookeeper {% for node in groups['common'] %}{{ node }}:2181{% if not loop.last %},{% endif %}{% endfor %} --replication-factor 1 --partitions 1 --topic mecbot.factordb-2.0.0
{{kafka_bin_dir}}/kafka-topics.sh --create --zookeeper {% for node in groups['common'] %}{{ node }}:2181{% if not loop.last %},{% endif %}{% endfor %} --replication-factor 1 --partitions 1 --topic mecbot.seeder-2.0.0

sleep 5

echo "Copying files into Hadoop"

{{hadoop_bin_dir}}/hadoop fs -put {{FC_BINARIES}}/hdfs_schemas/mecbot /
{{hadoop_bin_dir}}/hadoop fs -put {{FC_BINARIES}}/hdfs_schemas/apps /

sleep 5

echo "Starting Datomic"

{{cassandra_bin_dir}}/cqlsh -f {{datomic_bin_dir}}/cql/cassandra-keyspace.cql -u cassandra -p cassandra {{ groups['master'][0] }}

{{cassandra_bin_dir}}/cqlsh -f {{datomic_bin_dir}}/cql/cassandra-table.cql -u cassandra -p cassandra {{ groups['master'][0] }}

{{datomic_bin_dir}}/transactor -Xmx8g {{datomic_conf_dir}}/factordb-cassandra-transactor.properties > /dev/null 2>&1 &


# start arangodb agency
echo "starting arangodb agency"
{% for host in groups['common'] %}
{% if not loop.last %}
ssh -T {{ host }} << EOF
{{arangodb_bin_dir}}/arangod -c none --javascript.startup-directory {{arangodb_home_path}}/js/ --javascript.app-path {{arangodb_home_path}}/js/ --server.endpoint tcp://0.0.0.0:8531 --agency.my-address tcp://{{ host }}:8531 --server.authentication false --agency.activate true --agency.size 3 --agency.supervision true --database.directory {{arangodb_agency_dir}} --log.output file://{{arangodb_logs_dir}}/agency.logs -daemon --pid-file {{arangodb_agency_dir}}/agency.pid
EOF
sleep 5
echo ""
{% endif %}

{% if loop.last %}
ssh -T {{ host }} << EOF
{{arangodb_bin_dir}}/arangod -c none --javascript.startup-directory {{arangodb_home_path}}/js/ --javascript.app-path {{arangodb_home_path}}/js/ --server.endpoint tcp://0.0.0.0:8531 --agency.my-address tcp://{{ host }}:8531 --server.authentication false --agency.activate true --agency.size 3 {% for node in groups['common'] %}--agency.endpoint tcp://{{ node }}:8531 {% endfor %} --agency.supervision true --database.directory {{arangodb_agency_dir}} --log.output file://{{arangodb_logs_dir}}/agency.logs -daemon --pid-file {{arangodb_agency_dir}}/agency.pid
EOF
sleep 5
echo ""
{% endif %}
{% endfor %}

# start arangodb dbserver
echo "starting arangodb dbserver"
{% for host in groups['common'] %}
ssh -T {{ host }} << EOF
{{arangodb_bin_dir}}/arangod -c none --javascript.startup-directory {{arangodb_home_path}}/js/ --javascript.app-path {{arangodb_home_path}}/js/ --server.authentication=false --server.endpoint tcp://0.0.0.0:8530 --cluster.my-address tcp://{{ host }}:8530 --cluster.my-role PRIMARY {% for node in groups['common'] %}--cluster.agency-endpoint tcp://{{ node }}:8531 {% endfor %}--database.directory {{arangodb_dbserver_dir}} --log.output file://{{arangodb_logs_dir}}/dbserver.logs -daemon --pid-file {{arangodb_dbserver_dir}}/dbserver.pid
EOF
sleep 5
echo ""
{% endfor %}

# start arangodb coordinator
echo "starting arangodb coordinator"
{% for host in groups['common'] %}
ssh -T {{ host }} << EOF
{{arangodb_bin_dir}}/arangod -c none --javascript.startup-directory {{arangodb_home_path}}/js/ --javascript.app-path {{arangodb_home_path}}/js/ --server.authentication=false --server.endpoint tcp://0.0.0.0:8529 --cluster.my-address tcp://{{ host }}:8529 --cluster.my-role COORDINATOR {% for node in groups['common'] %}--cluster.agency-endpoint tcp://{{ node }}:8531 {% endfor %}--database.directory {{arangodb_coordinator_dir}} --log.output file://{{arangodb_logs_dir}}/coordinator.logs -daemon --pid-file {{arangodb_coordinator_dir}}/coordinator.pid
EOF
sleep 5
echo ""
{% endfor %}

#echo "starting docker containers"
#kdir ~/apps
#sudo docker run -d --net host --name nginx -v {{nginx_home_path}}/nginx.conf:/etc/nginx/nginx.conf -v {{home_directory}}/apps/:/apps/ --restart always nginx:alpine

# Check all status of all the services
crun jps
