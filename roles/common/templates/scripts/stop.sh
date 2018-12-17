#!/bin/bash
set -e
echo ""

{% set cnt = groups['master'] | length | int %}
{% if cnt > 1 %}
# Spark histroy server
echo "stopping spark history server"
{{spark_bin_dir}}/stop-history-server.sh
sleep 5
echo ""

# Stopping Spark master
echo "stopping spark fcmaster1"
{{spark_bin_dir}}/stop-master.sh
sleep 5
echo ""

echo "stopping spark fcmaster2"
ssh -T {{ groups['master'][1] }} << EOF
{{spark_bin_dir}}/stop-master.sh
EOF
sleep 5
echo ""

echo "stopping spark worker"
{{spark_bin_dir}}/stop-slaves.sh
sleep 5
echo ""

# Stop HBase
echo "stopping hbase services"
{{hbase_bin_dir}}/stop-hbase.sh
sleep 5
echo ""

# Stop Elasticsearch
echo "Stopping Elasticsearch-6.1.1"
{% for host in groups['master'] %}
{% if host not in groups['slaves'] %}
ssh -T {{ host }} << EOF
pkill -f elasticsearch
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}

echo "Stopping Elasticsearch-6.1.1"
{% for host in groups['slaves'] %}
{% if host not in groups['master'] %}
ssh -T {{ host }} << EOF
pkill -f elasticsearch
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}

# Stop kafka
echo "stopping kafka"
{% for host in groups['master'] %}
{% if host not in groups['slaves'] %}
ssh -T {{ host }} << EOF
{{kafka_bin_dir}}/kafka-server-stop.sh -daemon {{kafka_conf_dir}}/server.properties
EOF
sleep 5
echo ""
{% endif %}
{% endfor %}

{% for host in groups['slaves'] %}
{% if host not in groups['master'] %}
ssh -T {{ host }} << EOF
/{{kafka_bin_dir}}/kafka-server-stop.sh -daemon {{kafka_conf_dir}}/server.properties
EOF
sleep 5
echo ""
{% endif %}
{% endfor %}

# Stop Zookeeper
echo "stopping zookeeper"
crun zkServer.sh stop
sleep 5
echo ""

# Stop Hadoop
echo "stopping hadoop"
{{hadoop_sbin_dir}}/stop-dfs.sh
sleep 5
echo ""

# stopping zkfc
echo "stopping zkfc in fcmaster1"
{{hadoop_sbin_dir}}/hadoop-daemon.sh stop zkfc 
sleep 5
echo ""

echo "stopping zkfc in fcmaster2"
ssh -T {{ groups['master'][1] }} << EOF
{{hadoop_sbin_dir}}/hadoop-daemon.sh stop zkfc
EOF
sleep 5
echo ""

{% endif %}

{% if cnt == 1 %}
# Spark histroy server
echo "stopping spark history server"
{{spark_bin_dir}}/stop-history-server.sh
sleep 5
echo ""
 
# Stopping Spark server
echo "stoppping spark server"
{{spark_bin_dir}}/stop-all.sh
sleep 5
echo ""
 
# Stopping HBase
echo "stopping hbase"
{{hbase_bin_dir}}/stop-hbase.sh
sleep 5
echo ""

# Stop Elasticsearch
echo "Stopping Elasticsearch-6.1.1"
{% for host in groups['master'] %}
{% if host not in groups['slaves'] %}
ssh -T {{ host }} << EOF
pkill -f elasticsearch
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}

echo "Stopping Elasticsearch-6.1.1"
{% for host in groups['slaves'] %}
{% if host not in groups['master'] %}
ssh -T {{ host }} << EOF
pkill -f elasticsearch
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}

# Stop kafka
echo "stopping kafka"
{% for host in groups['master'] %}
{% if host not in groups['slaves'] %}
ssh -T {{ host }} << EOF
{{kafka_bin_dir}}/kafka-server-stop.sh -daemon {{kafka_conf_dir}}/server.properties
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}

{% for host in groups['slaves'] %}
{% if host not in groups['master'] %}
ssh -T {{ host }} << EOF
{{kafka_bin_dir}}/kafka-server-stop.sh -daemon {{kafka_conf_dir}}/server.properties
sleep 5
EOF
echo ""
{% endif %}
{% endfor %}

# Stop Zookeeper
echo "stopping zookeeper"
crun zkServer.sh stop
sleep 5
echo ""

# Stop Hadoop
echo "stopping hadoop"
{{hadoop_sbin_dir}}/stop-dfs.sh
sleep 5
echo ""
{% endif %}

# stop arangodb

{% for host in groups['common'] %}
ssh -T {{ host }} << EOF
sudo pkill -f arangodb
sleep 5
EOF
echo ""
{% endfor %}

# Check all status of all the services
crun jps
