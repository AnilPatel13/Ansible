#!/bin/bash

set -e

echo "stopping datanode"
{{hadoop_sbin_dir}}/hadoop-daemon.sh stop datanode > /dev/null 2>&1
sleep 5
echo ""

echo "stopping zookeeper"
{{zookeeper_bin_dir}}/zkServer.sh stop > /dev/null 2>&1
sleep 5
echo ""

echo "stopping elasticsearch"
pkill -f elasticsearch > /dev/null 2>&1
sleep 5
echo ""

echo "stopping regionserver"
{{hbase_bin_dir}}/hbase-daemon.sh stop regionserver > /dev/null 2>&1
sleep 5
echo ""

echo "stopping spark"
{{spark_bin_dir}}/stop-slave.sh spark://{{ groups['master'][0] }}:7077 > /dev/null 2>&1
sleep 5
echo ""

echo "stopping kafka"
{{kafka_bin_dir}}/kafka-server-stop.sh {{kafka_conf_dir}}/server.properties >/dev/null 2>&1 &
sleep 5
echo ""
