---
layout: post
title:  "网络安全-metasploit连接数据库及和opevas配合使用"
categories: 网络安全
tags: metasploit postgresql opevas
author: xueyp
description: 网络安全-metasploit连接数据库及和opevas配合使用
---

metasploit连接数据库
============

1. kali中postgresql启动

```
    service postgresql start
```

　　确认postgresql安装正确，要想每次自动启动的话，运行:

```
    update-rc.d postgresql enable
```

2. 修改PostgresSQL数据库配置实现远程访问

```
    vi /etc/postgresql/10/main/postgresql.conf
    更改#listen_addresses = 'localhost'为listen_addresses = '*' 
    更改#password_encryption = on为password_encryption = md5
```

```
    vi /etc/postgresql/10/main/pg_hba.conf
    在文档末尾加上以下内容
    # to allow your client visiting postgresql server
    host all all 0.0.0.0/32 md5
```

　　然后重新启动postgresql服务

```
    service postgresql restart 
```

3. 进入postgresql配置

```
    sudo -u postgres psql
    alter user postgres with password 'password';
```

4. 输入\q 退出到系统shell

5. 修改linux系统的postgres用户的密码（密码与数据库用户postgres的密码相同）

```
    sudo passwd -d postgres
    passwd：密码过期信息已更改。
    sudo -u postgres passwd
    输入新的 UNIX 密码：
    重新输入新的 UNIX 密码：
    passwd：已成功更新密码
```


6. 管理PostgreSQL用户和数据库:创建msf数据库

　　本机使用简单就好了，不用考虑太多安全性，创建用户名msf,密码msf,数据库msf的msf数据库

```
    root@kali:~# su postgres
    postgres@kali:/root$ createuser msf -P
    Enter password for new role:
    Enter it again:
    postgres@kali:/root$ createdb --owner=msf msf
    postgres@kali:/root$ exit
    exit
```

7. 测试数据库连接状态

```
    root@kali:~# msfconsole
    ### ###
    msf > db_connect msf:msf@localhost/msf
    [*] Rebuilding the module cache in the background...
    msf > db_status
    [*] postgresql connected to msf4
    msf > db_rebuild_cache  #生成数据库缓存数据
    msf>search  ***    #可以使用数据库查询了
```

8. 配置自动连接

　　自动连接可以通过配置文件 /usr/share/metasploit-framework/config/database.yml 完成，内容可以通过复制database.yml.example并修改内容来完成设置。

```
    root@kali:/usr/share/metasploit-framework/config#cp database.yml.example database.yml
    root@kali:/usr/share/metasploit-framework/config#vi database.yml
    root@kali:/usr/share/metasploit-framework/config#cat database.yml

    development: &pgsql
      adapter: postgresql
      database: msf
      username: msf
      password: msf
      host: localhost
      port: 5432
      pool: 5
      timeout: 5
```

　　主要修改database、password、host三个值，然后重新执行msfconsole即可直接连接数据库。

OpenVAS配置外部访问
============

　　安装完成之后，OpenVAS默认设置的监听地址为127.0.0.1，为了使用方便，需要手动配置外部访问，Openvas修改以下四个配置文件中的监听ip，由127.0.0.1改为0.0.0.0（表示任意IP），保存之后，重新加载systemctl，重启openvas即可。
```
vi /lib/systemd/system/greenbone-security-assistant.service
```

![png]({{"/assets/images/my/20180801_12.png"| absolute_url }})

需要注意的是，新版的OpenVAS需要增加host 头主机地址（IP或域名）

　　在--mlisten=0.0.0.0 后增加“--allow-header-host=外部访问的地址IP或域名”，本次测试本机地址为：192.168.200.221，即外部访问的IP为192.168.200.221。

![png]({{"/assets/images/my/20180801_13.png"| absolute_url }})

否则会报错：The request contained an unknown or invalid Host header. If you are trying to access GSA via its hostname or a proxy, make sure GSA is set up to allow it.

```
vi /etc/default/greenbone-security-assistant
```
　　此文件是访问web 端接口(gsad):访问opebvas 服务层的web 接口，默认监听地址为127.0.0.1，端口为9392。需要修改两处：GSA_ADDRESS和MANAGER_ADDRESS

![png]({{"/assets/images/my/20180801_14.png"| absolute_url }})

![png]({{"/assets/images/my/20180801_15.png"| absolute_url }})

　　同样修改　/lib/systemd/system/openvas-manager.service　和 /etc/default/openvas-manager文件中的127.0.0.1为0.0.0.0，

重新加载systemctl：
```
#openvas-stop
#systemctl daemon-reload
```
重新启动openvas：
```
#openvas-stop
#openvas-start
```
安装完整性检测
```
# openvas-check-setup
```
修改密码
```
openvasmd --user=admin --new-password=admin
```
升级插件和漏洞库

- 方法一：
```
# openvas-feed-update //初始化安装，可以不用更新
```
- 方法二：
```
# greenbone-nvt-sync

# greenbone-scapdata-sync  

# greenbone-certdata-sync
```
建议使用方法一进行升级。


metasploit连接OpenVAS
============

　　OpenVAS Manager主要负责与客户端Greebone程序通信，完成扫描任务、检测报告的提交等工作，默认端口是9390，使用metasploit调用openVAS的时候也是连接9390这个端口，通过命令交互驱动manager进行操作。。

1. 加载openVAS模块

　　进入msfconsole控制台，输入以下命令：
```
msf >load openvas
```

![png]({{"/assets/images/my/20180801_1.png"| absolute_url }})

2. 连接OpenVAS
```
msf > openvas_connect user password host port <ssl-confirm>
```
当连接到外部的openVAS时，最后一个参数必须为“ok”，代表你信任该连接。

![png]({{"/assets/images/my/20180801_2.png"| absolute_url }})

##msfconsole调用openVAS扫描漏洞

在msf中openVAS操作都基于ID进行。

1. 创建扫描目标
```
msf > openvas_target_create <name> <hosts> <comment>
```

![png]({{"/assets/images/my/20180801_3.png"| absolute_url }})

2. 创建扫描任务

　　创建扫描任务，需要关联扫描目标和选择扫描策略，默认有8种扫描策略，输入以下命令可以查看扫描策略：
```
msf > openvas_config_list
```

![png]({{"/assets/images/my/20180801_4.png"| absolute_url }})

　　选择一个扫描策略然后通过以下命令进行扫描任务的创建：
```
msf > openvas_task_create <name> <comment> <config_id> <target_id>
```

![png]({{"/assets/images/my/20180801_5.png"| absolute_url }})

3. 启动扫描并且查看进度

　　使用以下命令启动扫描任务：
```
msf > openvas_task_start <id>
```

![png]({{"/assets/images/my/20180801_6.png"| absolute_url }})

　　可以使用以下命令查看扫描进度：
```
msf > openvas_task_list
```

![png]({{"/assets/images/my/20180801_7.png"| absolute_url }})

　　status是扫描状态，当为done的时候表示扫描完毕，progress表示扫描的进度，status状态为new和done的时候progress均为-1。

4. 查看报告

使用以下命令可以查看报告列表：
```
msf > openvas_report_list
```

![png]({{"/assets/images/my/20180801_8.png"| absolute_url }})

5. 下载报告

　　下载报告的时候需要知道openVAS支持哪些文件格式的下载，通过以下命令查看可以下载的文件格式：
```
msf > openvas_format_list
```

![png]({{"/assets/images/my/20180801_9.png"| absolute_url }})

　　使用以下可以选择对应的文件格式进行报告的下载：
```
msf > openvas_report_download <report_id> <format_id> <path> <report_name>
```

![png]({{"/assets/images/my/20180801_10.png"| absolute_url }})


6. 导入报告

　　将报告导入metasploit的数据库中，首先要保证数据库是启动的，通过以下命令查看当前数据库的连接情况：
```
msf > db_status
```
　　如果没有数据库链接，需要进行数据库连接

　　在确保有数据库链接的情况下，进行报告导入，使用以下命令：
```
msf > openvas_report_import <report_id> <format_id>
```
　　只允许XML或者NBE格式的报告导入。

　　导入报告后，可以通过以下命令进行漏洞查看：
```
msf > vulns
```

![png]({{"/assets/images/my/20180801_11.png"| absolute_url }})



版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
