#!/bin/bash

set -e

{% set cnt = groups['master'] | length | int %}
{% if cnt == 1 %}
echo "starting zookeeper"
{{zookeeper_bin_dir}}/zkServer.sh start > /dev/null 2>&1
sleep 5
echo ""

echo "starting datanode"
{{hadoop_sbin_dir}}/hadoop-daemon.sh start datanode > /dev/null 2>&1
sleep 5
echo ""

echo "starting zookeeper"
{{zookeeper_bin_dir}}/zkServer.sh start > /dev/null 2>&1
sleep 5
echo ""

echo "starting elasticsearch"
{{elasticsearch_bin_dir}}/elasticsearch -d > /dev/null 2>&1
sleep 5
echo ""

echo "starting regionserver"
{{hbase_bin_dir}}/hbase-daemon.sh start regionserver > /dev/null 2>&1
sleep 5
echo ""

echo "starting spark"
{{spark_bin_dir}}/start-slave.sh spark://{{ groups['master'][0] }}:7077 > /dev/null 2>&1
sleep 5
echo ""

echo "starting kafka"
{{kafka_bin_dir}}/kafka-server-stop.sh {{kafka_conf_dir}}/server.properties >/dev/null 2>&1 &
sleep 5
echo ""
{% endif %}
