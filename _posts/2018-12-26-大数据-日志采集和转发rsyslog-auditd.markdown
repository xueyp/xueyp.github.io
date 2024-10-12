---
layout: post
title:  "大数据-日志采集和转发rsyslog,auditd到elasticsearch"
categories: 大数据
tags: 日志 rsyslog auditd elasticsearch
author: xueyp
description: 日志采集和转发rsyslog,auditd到elasticsearch
---

# 简介

- syslog协议

![png]({{"/assets/images/my/20181226_1.png"| absolute_url }})

Facility是syslog的模块: rsyslog通过facility概念来定义日志消息的来源，以方便对日志进行分类。Facility:有0-23种设备可选:

![png]({{"/assets/images/my/20181226_2.png"| absolute_url }})

Severity:日志等级

![png]({{"/assets/images/my/20181226_3.png"| absolute_url }})

官方网站：https://www.rsyslog.com/

- rsyslog

rsyslog是高速的日志收集处理服务，它具有高性能、安全可靠和模块化设计的特点，能够接收来自各种来源的日志输入（例如：file，tcp，udp，uxsock等），并通过处理后将结果输出的不同的目的地（例如：mysql，mongodb，elasticsearch，kafka等），每秒处理日志量能够超过百万条。

rsyslog默认安装于常见linux发行版，比syslog-ng更为简洁，配置也更清晰。

rsyslog守护进程可以被配置成两种环境，一种是配置成日志收集服务器，rsyslog进程可以从网络中收集其它主机上的日志数据，这些主机会将日志配置为发送到另外的远程服务器。rsyslog的另外一个用法，就是可以配置为客户端，用来过滤和发送内部日志消息到本地文件夹（如/var/log）或一台可以路由到的远程rsyslog服务器上。

logrotate是一个日志文件管理工具。用来把旧文件轮转、压缩、删除，并且创建新的日志文件。我们可以根据日志文件的大小、天数等来转储，便于对日志文件管理，一般都是通过cron计划任务来完成的。

　　特性：1.多线程

　　　　　2.支持加密协议：ssl，tls，relp

　　　　　3.mysql、oracle、postgreSQL

　　　　　4.等等..

安装:

```
# yum install rsyslog
```

检查rsyslog版本

```
# rsyslogd -v
```

# 配置

编辑rsyslog配置文件，配置文件路径 /etc/rsyslog.conf

## 配置为服务器

- 修改日志服务器上的/etc/rsyslog.conf配置文件，启用udp和tcp模块

```
# vim /etc/rsyslog.conf
$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
$ModLoad imjournal # provides access to the systemd journal

 #####开启udp接收日志
$ModLoad imudp
$UDPServerRun 514
$template RemoteHost,"/data/syslog/%$YEAR%-%$MONTH%-%$DAY%/%FROMHOST-IP%.log"
*.*  ?RemoteHost
& ~
####开启tcp协议接受日志
$ModLoad imtcp
$InputTCPServerRun 514

$WorkDirectory /var/lib/rsyslog
$ActionFileDefaultTemplate rsyslog_TraditionalFileFormat

#######启用/etc/rsyslog.d/*.conf目录下所有以.conf结尾的配置文件
$IncludeConfig /etc/rsyslog.d/*.conf

$OmitLocalLogging on
$IMJournalStateFile imjournal.state
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
*.emerg                                                 :omusrmsg:*
uucp,news.crit                                          /var/log/spooler
local7.*                                                /var/log/boot.log
local0.*                                                /etc/keepalived/keepalived.log
```

- 重启rsyslog服务

```
# systemctl restart rsyslog
# systemctl status rsyslog
# netstat -anp|grep 514
tcp        0      0 0.0.0.0:514             0.0.0.0:*               LISTEN      1445/rsyslogd
tcp6       0      0 :::514                  :::*                    LISTEN      1445/rsyslogd
udp        0      0 0.0.0.0:514             0.0.0.0:*                           1445/rsyslogd
udp6       0      0 :::514                  :::*                                1445/rsyslogd
```

## 配置为客户端

- 编辑rsylog客户端的配置文件：

```
# grep -v "^$" /etc/rsyslog.conf | grep -v "^#"

$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
$ModLoad imjournal # provides access to the systemd journal
$WorkDirectory /var/lib/rsyslog
$ActionFileDefaultTemplate rsyslog_TraditionalFileFormat
$template myFormat,"%timestamp% %fromhost-ip% %msg%\n"   #######自定义模板的相关信息
$IncludeConfig /etc/rsyslog.d/*.conf
$OmitLocalLogging on
$IMJournalStateFile imjournal.state
*.*          @172.16.1.241:514                      ########该声明告诉rsyslog守护进程，将系统上各个设备的各种日志的所有消息路由到远程rsyslog服务器（172.16.1.241）的UDP端口514。@@是通过tcp传输，一个@是通过udp传输。
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
*.emerg                                                 :omusrmsg:*
uucp,news.crit                                          /var/log/spooler
local7.*                                                /var/log/boot.log
local0.*                                             /etc/keepalived/keepalived.log
```

- 重启客户端rsyslog服务

```
# systemctl restart rsyslog
# systemctl status rsyslog
● rsyslog.service - System Logging Service
   Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled; vendor preset: enabled)
   Active: active (running) since 四 2018-12-24 16:57:04 CST; 4s ago
 Main PID: 44765 (rsyslogd)
   CGroup: /system.slice/rsyslog.service
           └─44765 /usr/sbin/rsyslogd -n

12月 24 16:57:04 server98 systemd[1]: Starting System Logging Service...
12月 24 16:57:04 server98 systemd[1]: Started System Logging Service.
```

## 查看客户端和服务端的日志是否正常生成

- 查看服务端是否在/data/日期/ip.log正常生成。

```
# tail -f /data/2018-12-24/172.16.1.241.log
```

- 在客户端生成日志，,可用logger命令生成日志，例如logger  "test log"生成一条内容为test log的日志，然后用如下命令查看是否有此条日志：

```
# tail -f /var/log/messages
```

## rsyslog发送日志到logstash

rsyslog配置：

```
vim /etc/rsyslog.conf
找到 #*.* @@remote-host:514
修改 #*.* @@remote-host:514 -> *.* @@logstsh收集服务器IP:端口

重启服务
service rsyslog restart
```

logstash配置  :

```
input {
  syslog {
    port => "514"#用syslog会自动解析输入的信息成各个字段，配置方便
  }
}
# 若果需要过滤字段可以在中间进行
output {
    elasticsearch {
        hosts => ["172.16.1.241:9200"]#elasticsearch服务器地址
        index => "syslog-%{+YYYY.MM.dd}"
    }

}

```

# auditd

- Linux 用户空间审计系统

Linux 审计系统（audit）为追踪系统中与安全相关的信息提供了途径。基于预配置原则，audit将生成日志项从而记录尽可能多的在系统中发生的事件。这一信息对执行关键任务的环境尤其重要，它可以确定那些违反安全策略的人以及他们的行为。audit不会为系统提供额外的安全保护；相反，它只是用来发现系统中违反安全策略的行为。通过额外的措施例如 SELinux 可以进一步地防止这些违反行为。

Linux 内核有用日志记录事件的能力，包括记录系统调用和文件访问。管理员可以检查这些日志，确定是否存在安全漏洞（如多次失败的登录尝试，或者用户对系统文件不成功的访问）,即auditd。架构图如下：

![png]({{"/assets/images/my/20181226_5.jpg"| absolute_url }})

- audit审计系统的组成：

1. audit内核模块（kauditd）；

2. audit用户态守护进程（auditd）；

3. audit用户态实用工具（auditctl/audispd/aureport/ausearch/…）；

```
# ps aux | grep --color "audit"
root       613  0.0  0.0      0     0 ?        S     2016   0:17 [kauditd] #用中括号括起来的进程都是内核进程/线程
root      2471  0.0  0.0  93156   896 ?        S<sl  2016   1:03 auditd
#上一行中的「S<sl」的含义解读：S表示进程正在睡眠，<表示具有较高的优先级，s表示多进程l表示多线程
#
# which auditctl
/sbin/auditctl
#
# ls -lt /sbin/au*
-rwxr-x--- /sbin/audispd  #转发事件通知给其他应用程序，而不是写入到审计日志文件中。
-rwxr-x--- /sbin/auditctl #即时控制审计守护进程的行为的工具，比如如添加规则等等。
-rwxr-x--- /sbin/auditd
-rwxr-xr-x /sbin/aureport #查看和生成审计报告的工具
-rwxr-xr-x /sbin/ausearch #查找审计事件的工具。
-rwxr-x--- /sbin/autrace  #用于跟踪进程的工具
-rwxr-x--- /sbin/augenrules #用于生成和更新审计规则的工具(一个bash脚本)
```

Linux的audit审计系统提供了一种记录系统安全信息的方法，为系统管理员在用户违反系统安全规则时提供及时的警告信息。内核其他线程通过内核审计API写入套接字缓冲区队列audit_skb_queue中，内核线程kauditd通过netlink机制(NETLINK_AUDIT)将审计消息定向发送给用户态的审计后台auditd的主线程，auditd主线程再通过事件队列将审计消息传给审计后台的写log文件线程，写入log文件。另一方面，审计后台还通过一个与套接字绑定的管道将审计消息发送给audispd应用程序，可把事件传送给其他应用程序做进一步处理。

**安装配置过程详见：[redhat auditing guide](https://access.redhat.com/documentation/zh-CN/Red_Hat_Enterprise_Linux/7/html/Security_Guide/chap-system_auditing.html)**

- audit 和 syslog 日志系统的关系

audit 主要用来记录安全信息，用于对系统安全事件的追溯；而 syslog 日志系统用来记录系统中的各种信息，如硬件警报和软件日志等。但是 syslog 属于应用层，没办法记录太多信息。audit 来记录内核信息，包括文件的读写，权限的改变等。

- auditd转发到logstash

Beats 是安装在服务器上的数据中转代理。Beats 可以将数据直接传输到 Elasticsearch 或传输到 Logstash 。Beats 有多种类型，可以根据实际应用需要选择合适的类型。

常用的类型有：

        - Packetbeat：网络数据包分析器，提供有关您的应用程序服务器之间交换的事务的信息。

        - Filebeat：从您的服务器发送日志文件。

        - Metricbeat：是一个服务器监视代理程序，它定期从服务器上运行的操作系统和服务收集指标。

        - Winlogbeat：提供Windows事件日志。

![png]({{"/assets/images/my/20181226_6.png"| absolute_url }})

其中，[filebeat](https://www.elastic.co/products/beats/filebeat)通过提供一种轻量级的方式来转发和集中日志和文件，示例配置如下：

```
filebeat:
  prospectors:
  - encoding: plain
    fields:
      collector_node_id: c00010.lan
      type: auditd
    ignore_older: 0
    paths:
    - /var/log/audit/audit.log
    scan_frequency: 10s
    tail_files: true
    type: log
output:
  logstash:
    hosts:
    - graylog001.lan:5044
    - graylog002.lan:5044
    - graylog003.lan:5044
    loadbalance: true
    #
    # to enhance security of this sensitive data, enable client certificates
    # and certificate verification
    # ssl.certificate_authorities: ["/etc/ca.crt"]
    # ssl.certificate: "/etc/client.crt"
    # ssl.key: "/etc/client.key"
    # ssl.verification_mode: trueFilebeat 6.x
```

另外,还可以用专用于转发auditd日志信息的[auditbeat](https://www.elastic.co/cn/products/beats/auditbeat) ，收集Linux 审计框架的数据，监控文件完整性,Auditbeat 实时采集这些事件，然后发送到 Elastic Stack 其他部分做进一步分析。

- 转发auditd日志的示例配置：

1. 创建一条监听 /etc/passwd 的规则
```
auditctl -w /etc/passwd -p wra -k passwd
auditctl -l #列出创建的规则
```

2. 规则创建成功，现在我们执行：cat /etc/passwd ，在/var/log/audit/audit.log可以看到访问passwd文件的事件

```
type=SYSCALL msg=audit(1522927552.749:917): arch=c000003e syscall=2 success=yes exit=3 a0=7ffe2ce05793 a1=0 a2=1fffffffffff0000 a3=7ffe2ce043a0 items=1 ppid=2906 pid=4668 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts4 ses=1 comm="cat" exe="/bin/cat" key="passwd"
type=CWD msg=audit(1522927552.749:917):  cwd="/root"
type=PATH msg=audit(1522927552.749:917): item=0 name="/etc/passwd" inode=3147443 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 nametype=NORMAL
type=UNKNOWN[1327] msg=audit(1522927552.749:917): proctitle=636174002F6574632F706173737764
```

3. 编辑 /etc/auditbeat/auditbeat.yml

```
auditbeat.modules:
- module: auditd
  audit_rules: |
    -a exit,always -F arch=b64 -S clock_settime -k changetime
    -w /etc/passwd -p wra -k passwd
setup.template.enabled: false
output.elasticsearch:
  hosts: ["https://172.16.1.241:443"]
  index: "LOGSENE-APP-TOKEN-GOES-HERE"
```

4. 停用auditd,使用auditbeat

```
service auditd stop
service auditbeat restart
```

5. logstash或elasticsearch将收到JSON格式的事件

```
{
  "@timestamp": "2018-12-24T12:36:07.710Z",
  "user": {
    "sgid": "0",
    "fsuid": "0",
    "gid": "0",
    "name_map": {
      "egid": "root",
      "sgid": "root",
      "suid": "root",
      "uid": "root",
      "auid": "radu",
      "fsgid": "root",
      "fsuid": "root",
      "gid": "root",
      "euid": "root"
    },
    "fsgid": "0",
    "uid": "0",
    "egid": "0",
    "auid": "1000",
    "suid": "0",
    "euid": "0"
  },
  "process": {
    "ppid": "2906",
    "title": "cat /etc/passwd",
    "name": "cat",
    "exe": "/bin/cat",
    "cwd": "/root",
    "pid": "5373"
  },
  "file": {
    "device": "00:00",
    "inode": "3147443",
    "mode": "0644",
    "owner": "root",
    "path": "/etc/passwd",
    "uid": "0",
    "gid": "0",
    "group": "root"
  },
  "beat": {
    "version": "6.2.3",
    "name": "radu-laptop",
    "hostname": "radu-laptop"
  },
  "tags": [
    "passwd"
  ],
  "auditd": {
    "summary": {
      "actor": {
        "primary": "radu",
        "secondary": "root"
      },
      "object": {
        "primary": "/etc/passwd",
        "type": "file"
      },
      "how": "/bin/cat"
    },
    "paths": [
      {
        "dev": "08:01",
        "nametype": "NORMAL",
        "rdev": "00:00",
        "inode": "3147443",
        "item": "0",
        "mode": "0100644",
        "name": "/etc/passwd",
        "ogid": "0",
        "ouid": "0"
      }
    ],
    "sequence": 3029,
    "result": "success",
    "session": "1",
    "data": {
      "a0": "7ffea3df0793",
      "tty": "pts4",
      "a3": "7ffea3dee890",
      "syscall": "open",
      "a1": "0",
      "exit": "3",
      "arch": "x86_64",
      "a2": "1fffffffffff0000"
    }
  },
  "event": {
    "category": "audit-rule",
    "type": "syscall",
    "action": "opened-file",
    "module": "auditd"
  }
}
```

参考
============

[rsyslog configuration](https://www.rsyslog.com/doc/v8-stable/configuration/index.html)

[How to configure remote logging with rsyslog ](https://access.redhat.com/solutions/54363)

[A Brief Introduction to auditd](https://security.blogoverflow.com/2013/01/a-brief-introduction-to-auditd/)

[Linux Auditd Best Practice Configuration ](https://gist.github.com/Neo23x0/9fe88c0c5979e017a389b90fd19ddfee)

[filebeat.reference.yml](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-reference-yml.html)


版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
