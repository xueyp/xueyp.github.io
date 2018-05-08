---
layout: post
title:  "hadoop spark集群安装配置(二)"
categories: 大数据
tags: 大数据　hadoop spark ssh
author: xueyp
description: hadoop及spark集群的安装配置
---

1.环境变量(/etc/profile)
============

    export EDITOR=vim

    export JAVA_HOME=/usr/local/jdk

    export JRE_HOME=/usr/local/jdk/jre

    export SCALA_HOME=/usr/local/scala

    export HADOOP_HOME=/usr/local/hadoop

    export HADOOP_MAPRED_HOME=$HADOOP_HOME

    export HADOOP_COMMON_HOME=$HADOOP_HOME

    export HADOOP_HDFS_HOME=$HADOOP_HOME

    export YARN_HOME=$HADOOP_HOME

    export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

    export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop

    export HBASE_HOME=/usr/local/hbase

    export HIVE_HOME=/usr/local/hive

    export ZOOKEEPER_HOME=/usr/local/zookeeper

    export SPARK_HOME=/usr/local/spark

    export PYSPARK_PYTHON=/home/x/anaconda3/bin/python

    export CLASSPATH="./:$JAVA_HOME/lib:$JRE_HOME/lib"
    
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SCALA_HOME/bin:$SPARK_HOME/bin:/usr/local/sbt/bin:/usr/local/cassandra/bin:/usr/local/kafka/bin:/usr/local/mongodb/bin:/usr/local/es/bin:$HBASE_HOME/bin:$HIVE_HOME/bin:$ZOOKEEPER_HOME/bin


2.下载hadoop及spark等软件包,解压到/usr/local，并根据上面的环境变量创建软链接
============

例如：

    sudo tar -zxf ~/hadoop-2.7.3.tar.gz -C /usr/local   # 解压到/usr/local中

    cd /usr/local/

    sudo ln -s  ./hadoop-2.7.3/ ./hadoop         # 将文件夹名改为hadoop

    sudo chown -R x:x ./hadoop           # 修改文件权限,其中x为使用hadoop的用户及组

对于spark等其他程序，同样的解压步骤。


3.配置各软件,配置列表如下：
============

1)hadoop(/usr/local/hadoop/etc/hadoop)

core-site.xml

    <configuration>
        <property>
            <name>fs.defaultFS</name>
            <value>hdfs://v1:9000</value>
        </property>
    <property>
            <name>hadoop.tmp.dir</name>
            <value>/home/x/hadoop/tmp</value>
        </property>
    </configuration>

mapred-site.xml
    
    <configuration>
        <property>
            <name>mapreduce.framework.name</name>
            <value>yarn</value>
        </property>
    <property>
            <name>mapreduce.admin.user.env</name>
            <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    <property>
    <name>yarn.app.mapreduce.am.env</name>
     <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    </configuration>

hdfs-site.xml

    <configuration>
     <property>
            <name>dfs.replication</name>
            <value>2</value>
     </property>
    <property>
            <name>dfs.permissions.enabled</name>
            <value>false</value>
    </property>
    <property>
            <name>dfs.blocksize</name>
            <value>134217728</value>
    </property>
    </configuration>

yarn-site.xml

    <configuration>

    <!-- Site specific YARN configuration properties -->
       <!-- 设置 resourcemanager 在哪个节点-->
        <property>
            <name>yarn.resourcemanager.hostname</name>
            <value>v1</value>
        </property>

    <property>
            <name>yarn.scheduler.maximum-allocation-mb</name>
            <value>24576</value>
        </property>
    <property>
            <name>yarn.nodemanager.resource.memory-mb</name>
            <value>24576</value>
        </property>
    <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
        </property>
    <property>
            <name>yarn.nodemanager.env-whitelist</name>
     <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ</value>
        </property><property>
            <name>yarn.nodemanager.vmem-check-enable</name>
            <value>true</value>
        </property>
       <property>
            <name>yarn.nodemanager.vmem-pmem-ratio</name>
            <value>45</value>
        </property>
    <property>
            <name>yarn.nodemanager.resource.cpu-vcores</name>
            <value>40</value>
        </property>
        <!-- 每个节点的能用的vcores的个数，最好设置为你机器的核数  -->

    </configuration>

workers

    v1
    v2
    v3

2)spark(/usr/local/spark/conf)

slaves

    v2
    v3


4.分发和启动：
============

1).分发配置好的软件包到v2,v3:

    scp -r apache-hhadoop-2.7.3-bin v3:/home/x/

在v2,v3上复制到/usr/local，并与v1相同地设置链接和权限

2).启动集群的alias

添加在~/.bashrc文件中：

    alias es="sh /usr/local/es/bin/elasticsearch && /usr/local/logstash/bin/logstash -f /usr/local/logstash/config/logstash.conf& && /usr/local/kibana/bin/kibana&"

    alias starth="start-dfs.sh&&start-yarn.sh"

    alias stoph="stop-yarn.sh&&stop-dfs.sh"

    alias starts="/usr/local/spark/sbin/start-all.sh"

    alias stops="/usr/local/spark/sbin/stop-all.sh"

    alias starthbase="/usr/local/hbase/bin/start-hbase.sh&&/usr/local/hbase/bin/hbase shell"

    alias stophbase="/usr/local/hbase/bin/stop-hbase.sh"

    alias starthiveserver="$HIVE_HOME/bin/hiveserver2 &"

    alias starthive="$HIVE_HOME/bin/beeline -u jdbc:hive2://v1:10000"

    alias sparksh="spark-shell --master yarn --num-executors 8 --driver-memory 6g --executor-memory 4g --executor-cores 4"

    export PYSPARK_DRIVER_PYTHON=jupyter

    export PYSPARK_DRIVER_PYTHON_OPTS="notebook"

    alias pysparksh="pyspark --master yarn --num-executors 8 --driver-memory 6g --executor-memory 4g --executor-cores 4"

    # added by Anaconda3 installer

    export PATH="/home/x/anaconda3/bin:$PATH"

其中供pyspark使用的python环境为安装在~/anaconda3下的anaconda

3).初始化和启动集群

    hdfs namenode -format#仅格式化一次

    starth #启动hadoop集群

    starts #启动spark集群

web访问页面：

  [yarn](http://v1:8088/cluster)

  [sparkmaster](http://v1:8080/)

  [hadoop](http://v1:9870)

hdfs文件操作：

    hdfs dfs -mkdir /user

    hdfs dfs -mkdir input

    hdfs dfs -put etc/hadoop/*.xml input

    hdfs dfs -get output output

    cat output/*


版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
