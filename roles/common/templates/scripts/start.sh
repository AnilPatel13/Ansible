#!/bin/bash
set -e
echo ""

# Start Zookeeper (Start it on every machine)
echo "starting zookeeper services"
{{FC_HOME}}/cfiles/crun zkServer.sh start
sleep 5
echo ""

# starting hadoop
echo "start hadoop"
{{hadoop_sbin_dir}}/start-dfs.sh 
sleep 5
echo ""

# Start Elasticsearch (Start it on every machine)
echo "starting elasticsearch services"
{{FC_HOME}}/cfiles/crun elasticsearch -d
sleep 5
echo ""

# Start HBase
echo "starting hbase services"
{{hbase_bin_dir}}/start-hbase.sh
sleep 5
echo ""

# Start Spark
echo "starting spark fcmaster1"
{{spark_bin_dir}}/start-all.sh
sleep 5
echo ""

# starting kafka

crun {{kafka_bin_dir}}/kafka-server-start.sh -daemon {{kafka_conf_dir}}/server.properties
sleep 5
echo ""

sleep 3
echo "Starting Memcached"

{{memcached_home_path}}/bin/memcached -m 4096 -d

sleep 3

echo "Starting cassandra"

crun {{cassandra_home_path}}/cassandra &

sleep 10

echo "Starting Datomic"

{{datomic_bin_dir}}/transactor -Xmx8g {{datomic_conf_dir}}/factordb-cassandra-transactor.properties &

# start arangodb
echo "starting arangodb"
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

crun jps
