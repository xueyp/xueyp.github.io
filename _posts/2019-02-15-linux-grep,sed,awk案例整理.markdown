---
layout: post
title:  "linux-grep,sed,awk案例整理"
categories: linux
tags: linux
author: xueyp
description: linux-grep,sed,awk案例整理
---

在网络安全分析中，日志是我们在排查问题的一个重要依据。但是日志并不是写了就好了，当你想查看日志的时候，你会发现线上日志堆积的长度已经超越了逐行浏览的极限了。很有必要通过一些手段来高效快速地从日志中定位到要找的信息。linux中grep,sed,awk是用于查找、筛选和统计日志的基本工具。

# grep、sed、awk 概述

- grep：文本过滤器，如果仅仅是过滤文本，可使用grep，其效率要比其他的高很多。

Linux系统中grep命令是一种强大的文本搜索工具，它能使用正则表达式搜索文本，并把匹 配的行打印出来。grep全称是Global Regular Expression Print，表示全局正则表达式版本，它的使用权限是所有用户。

- egrep:支持扩展正则表达式

- sed：Stream EDitor，流编辑器，默认只处理模式空间，不处理原数据，如果你处理的数据是针对行进行处理的，可以使用

sed 是一种在线编辑器，它一次处理一行内容。处理时，把当前处理的行存储在临时缓冲区中，称为“模式空间”（pattern space），接着用sed命令处理缓冲区中的内容，处理完成后，把缓冲区的内容送往屏幕。接着处理下一行，这样不断重复，直到文件末尾。文件内容并没有改变，除非你使用重定向存储输出。Sed主要用来自动编辑一个或多个文件；简化对文件的反复操作；编写转换程序等。

awk：报告生成器，格式化以后显示。如果对处理的数据需要生成报告之类的信息，或者你处理的数据是按列进行处理的，最好使用awk

awk是一个强大的文本分析工具，相对于grep的查找，sed的编辑，awk在其对数据分析并生成报告时，显得尤为强大。简单来说awk就是把文件逐行的读入，以空格为默认分隔符将每行切片，切开的部分再进行各种分析处理。

awk有3个不同版本: awk、nawk和gawk，未作特别说明，一般指gawk，gawk是 AWK的 GNU版本

# 正则表达式基础

在最简单的情况下，一个正则表达式看上去就是一个普通的查找串。例如，正则表达式"testing"中没有包含任何元字符，，它可以匹配"testing"和"123testing"等字符串，但是不能匹配"Testing"。

要想真正的用好正则表达式，正确的理解元字符是最重要的事情。下表列出了所有的元字符和对它们的一个简短的描述。

| 元字符 | 描述 |
| . | 匹配任何单个字符。例如正则表达式r.t匹配这些字符串：rat、rut、r t，但是不匹配root |
| $ | 匹配行结束符。例如正则表达式weasel$ 能够匹配字符串"He's a weasel"的末尾，但是不能匹配字符串"They are a bunch of weasels." |
| ^ | 匹配一行的开始。例如正则表达式^When in能够匹配字符串"When in the course of human events"的开始，但是不能匹配"What and When in the" |
| * | 匹配0或多个正好在它之前的那个字符。例如正则表达式.*意味着能够匹配任意数量的任何字符 |
| \ | 这是引用府，用来将这里列出的这些元字符当作普通的字符来进行匹配。例如正则表达式\$被用来匹配美元符号，而不是行尾，类似的，正则表达式\.用来匹配点字符，而不是任何字符的通配符 |
| [ ] [c1-c2] [^c1-c2] | 匹配括号中的任何一个字符。例如正则表达式r[aou]t匹配rat、rot和rut，但是不匹配ret。可以在括号中使用连字符-来指定字符的区间，例如正则表达式[0-9]可以匹配任何数字字符；还可以制定多个区间，例如正则表达式[A-Za-z]可以匹配任何大小写字母。另一个重要的用法是“排除”，要想匹配除了指定区间之外的字符——也就是所谓的补集——在左边的括号和第一个字符之间使用^字符，例如正则表达式[^269A-Z] 将匹配除了2、6、9和所有大写字母之外的任何字符 |
| \< \> | 匹配词（word）的开始（\<）和结束（\>）。例如正则表达式\<the能够匹配字符串"for the wise"中的"the"，但是不能匹配字符串"otherwise"中的"the"。注意：这个元字符不是所有的软件都支持的 |
| + | 匹配1或多个正好在它之前的那个字符。注意：这个元字符不是所有的软件都支持的 |
| ? | 匹配0或1个正好在它之前的那个字符。注意：这个元字符不是所有的软件都支持的 |
| **|** | 将两个匹配条件进行逻辑“或”（Or）运算。例如正则表达式(him|her) 匹配"it belongs to him"和"it belongs to her"，但是不能匹配"it belongs to them."。注意：这个元字符不是所有的软件都支持的 |
| \{i\} \{i,j\} | 匹配指定数目的字符，这些字符是在它之前的表达式定义的。例如正则表达式A[0-9]\{3\} 能够匹配字符"A"后面跟着正好3个数字字符的串，例如A123、A348等，但是不匹配A1234。而正则表达式[0-9]\{4,6\} 匹配连续的任意4个、5个或者6个数字字符。注意：这个元字符不是所有的软件都支持的 |

# 案例

## grep

**常用选项**
- -i ：忽略大小写
- -v ：取反 分为：过滤出，过滤掉

**使用案例**

```
    grep ‘root’ /etc/passwd //筛选文件中包含root的行
    grep -v ‘ root’ /etc/passwd //筛选文件中不包含root的行
    grep ‘r..d’ /etc/passwd //筛选r和d之间两个任意字符的行
    grep ‘[^s]bin’ /etc/passwd //筛选bin前面不是以s开头行
    grep ‘^$’ /etc/passwd //筛选出空格白行
    grep ‘t[es]’ /etc/passswd //筛选包含te或者ts的行
    grep ‘0{1,}’ /etc/passwd //筛选查找数字0出现的次数1次或1次以上
    grep -e ‘root’ -e ’sshd’ /etc/passwd //查找root和sshd的行 注：-e参数查找多个模式
    grep ‘[^a-z]ae’ /etc/passwd //筛选ae前面不是以小写字母的行
    grep ‘^[a-z]ae’ /etc/passwd //筛选ae前面以小写字母开头的行
    注：当使用连续的字符时，小写字母[a-z],大写字母[A-Z]，数字[0-9]
    grep ‘0’ /etc/passwd //匹配所有的内容（包括空白行）
    注：00匹配至少包含一个0的行（第一个0必须出现，第二个0可出现0次或多次）
```

## egrep

**使用案例**

```
    egrep 0+ /etc/passwd //匹配至少包含一个0的行
    egrep ‘(root|ntp)’ /etc/passwd //匹配包含root 或者ntp的行
    egrep ‘ro?t’ /etc/passwd //匹配rt或者rot的行
    egrep -v ‘^$|^#’ /etc/passwd //过滤文件中空白行与#开头的行。没有空白行与#号开头的行，所以没有如何输出
```

## sed

sed是文本处理工具，读取文本内容，根据指定的条件进行处理，如删除，替换，添加等

可在无交互的情况下实现相当复杂的文本处理操作被广泛应用于shell脚本，已完成自动化处理任务，sed依赖于正则表达式

**命令语法**
- sed -e ‘编辑指令’ 文件1 文件2 文件 3....... 注：-e ，在’编辑命令’中可有’;’来分割执行命令
- sed -n -e ‘编辑命令’ 文件1 文件2... -n 只显示过滤出内容
- sed -i -e ‘编辑命令’ 文件1 文件2.... -i：流编辑器。读一行处理一行

**命令格式**
-  编辑命令格式：[地址1],[地址2]操作[参数]
- “地址”，可数字，正则表达式，$ 如果没有地址代表时所有行
- “操作” 可以是 p,d,s,r,w,i等...
- “参数” 一般有g ，代表只要符合i傲剑全部进行处理（g全部）

**常用选项**
- p ：输出指定的行
- d ：删除指定的行
- s/c ：子串替换，格式 ：”行范围 s/旧字符串/新字符串/g”
- r ：读取指定条件
- w：保存为文件
- i ：插入，在当前行前面插入一行或多行

**使用案例**

```
    输出指定的行：
    sed -n ‘p’ /etc/passwd //将所有内容输出
    sed -n ‘7p’ /etc/passwd //将第7行内容输出
    sed -n ‘$p’ /etc/passwd //将最后一行输出
    sed -n ‘1,7{n;p}’ /etc/passwd //将1~7行的奇数输出
    sed -n ‘1,7{p;n}’ /etc/passwd //将1~7行的偶数输出
    sed -n ‘1,+4p’ /etc/passwd //从第1行，连续4行进行输出
    sed -n ‘/root/p’ /etc/passwd //将匹配包含root的进行输出
    sed -n ‘10,/nom/p’ /etc/passwd //将从第10行至第一个包含nom的行进行输出
    sed -nr ‘/ro{1,}t/p’ /etc/passwd //匹配不少一次前导字符0 ，-r参数支持扩展正则表达式 rot root
    sed -n ‘/root|ntp/p’ /etc/passwd //输出包含root或者ntp的行 注：如果遇到特殊符号，扩展正则需要转义符 “\”
    sed -n ‘/root/=’ /etc/passwd //将包含root所在的行行号输出， ‘=’用来输出行号
    sed -e ‘5q’ /etc/passwd //输出前5行信息后退出 ，q 退出
    sed -e ‘5p;7p;qp’ /etc/passwd //输出5行，7行， 9行信息插入符合条件的行
    sed ‘/root/i admin:x:490:490::/:/sbin/nologin ’ /etc/passwd //在包含root行的前面一行插入admin:x:490:490::/:/sbin/nologin ’
    sed ‘root/a admin:x:490:490::/:/sbin/nologin ’ /etc/passwd //在包含root行的下一行插入admin:x:490:490::/:/sbin/nologin ’
    注：sed ‘/root/i’ 前面一行插入 sed ‘/root/a’ 后面一行插入
    sed ‘saADMIN’ /etc/passwd //在第3行之后插入ADMIN
    删除符合要求的行：
    sed ‘1d’ /etc/passwd //删除第一行
    sed ‘$d’ /etc/passwd //删除最后一行
    sed ‘/^$/d’ /etc/passwd //删除所有空行
    sed ‘2,4d’ /etc/passwd //删除第2到4行
    sed ‘/root/d’ /etc/passwd //删除包含root的行
    sed ‘/root/!d’ /etc/passwd //删除不包含root的行，这里的”!”表示取反操作
    sed ‘/^root/d’ /etc/passwd //删除以root开头的行
    sed ‘/nologin$/d’ /etc/passwd //删除以nologin结尾的行替换符合条件的文本
    sed ‘s/root//g’ /etc/passwd //将文件中所有的root都替换成空 g替换全部 s：全部内容
    sed -n ‘s/root/admin/2p’ /etc/passwd //把每行的第2个root替换成admin
    sed ‘/root/s/root/ROOT/g ’ /etc/passwd //将第1~3行中的所有root都替换为ROOT
    sed ‘1,3s/bin/BIN/g’ /etc/passwd //将第1~3行中的所有bin都替换为BIN
    sed ‘s/$/ABC/’ /etc/passwd //在每行行尾插入字符串ABC
    sed ‘s/^/#/’ /etc/passwd //在每行行首插入#号
    sed ‘/root/s /^/#/’ /etc/passwd //将包含root的行的行首插入#号
    sed ‘1c ABC ’ /etc/passwd //将第一行替换为ABC
    sed ‘y/root/ROOT/’ /etc/passwd //将root对应替换为ROOT y：对应替换
    sed ‘/1,10y/root/ROOT’ /etc/passwd //将第1~10行中的root 对应ROOT
    迁移符合条件的文本：
    sed ‘15,16 w out.txt’ test,txt //另存为
    sed ‘5r /etc/reslov.conf ’ test.txt //将/etc/relov.conf 内容读取到当前文件第5行后面
    sed ‘1,5(H:d);$G’ test.txt //将第1~5行内容迁移至末尾 注：H 复制到缓冲区 G 追加到指定行后
    sed ‘/^IP/ s/^/#/’ test.txt //在以IP开头的行的行首插入#
    sed ‘1,5H;15,16G’ test.txt
    执行多次命令
    sed -ne ‘s/root/admin/’ -ne ‘s/bash/sh/p’ /etc/passwd //将root和bash动作替换
    sed -ne ‘s/root/admin/;s/bash/sh/p’ /etc/passwd //将root和bash动作提黄
    直接修改文件内容：-i 直接修改源文件内容，保存修改的文件
    sed -i ‘s/^/#/’ /etc/passwd //在每行开头插入#号 ，直接修改源文件
    DII
```

## awk

awk也是一个功能强大的编辑工具，与sed一样，可在无交互的情况下实现相当复杂的文本操作

**命令格式**

awk 选项 '模式或条件 {编辑指令}’ 文件1 文件2
```
 awk -f 脚本文件 文件1 文件2
```

**工作原理**

逐行读取文本，默认以空格为分隔符进行分隔，将分隔所得的各个字段保存到内建变量中，并按模式或者条件执行编辑命令

**内置变量**
- FS:指定每行文本的字段分隔符，缺省为空格或制表位。 注：默认分隔符为空格
- NF：当前处理的行的字段个数
- NR：当前处理的行的行号（序数）
- $0:当前处理的行的整行内容
- $n：当前处理行的第n个字段（第n列）

**使用案例**

```
    awk -F: '{print $0,NF}' /etc/passwd //输出以冒号为分隔的/etc/passwd文件中记录的字段段数
    df -hT |awk '{print $1,$6}' //用awk截取命令df -hT输出的结果，不带任何条件，进行格式化，打印第1列和第6列数据
    awk '{print $0}' /etc/passwd //输出所有内容
    cat /etc/passwd grep "" /etc/passwd sed -n 'p' /etc/passwd
    打印文本内容：
    awk 'NR==1,NR==3{print}' bfile //输出第1至第3行内容
    awk 'NR==1||NR==3{print}' bfile //输出第1行、第3行内容
    awk '/^root/{print}' /etc/passwd //输出以root开头的行
    awk '/nologin$/{print}' /etc/passwd //输出以nologin结尾的行
    awk '(NR>=1)&&(NR<=3){print}' /etc/passwd //输出第1行到第3行内容
    awk "(NR%2)==1{print}' /etc/passwd //输出所有奇数行的内容
    awk '(NR%2)==0{print}' /etc/passwd //输出所有偶数行的内容
    awk -F: '!($3<900)' /etc/passwd //输出第3个字段不小于900的行,“！”号表示取反
    在使用awk的过程中，可以使用关系运算符作为“条件”，用于比较数字与字符串，运算符大于（>)、小于(<)、小于等于(<=)、等于（==）、不等于（!=)
    也可使用逻辑操作符&&，表示“与”，||表示“或”，！表示“非”
    还可以进行简单的数学运算加（+）、减（—）、乘（*）、除（/）、取余（%）、乘方（^)。
    只有当条件为真，才执行指定的动作。

    awk -F: '{if($3>200)print $0}' /etc/passwd //输出第3个字段大于200的行
    awk -F: '{max=($3>$4)?$3:$4;print max}' /etc/passwd
    //如果第3个字段的值大于第4个字段的值，则把问号前表达式的值赋给max，否则就将冒号后那个表达式的值赋给max
    awk -F: '{max=($3>200)?$3:$1;print max}' /etc/passwd // //如果第3个字段的值大于200，则把第3个字段的值赋给max，否则就将第1个字段的值赋给max
    在使用awk过程中还可以使用条件表达式，条件表达式的运算涉及两个符号，冒号和问号，其实质就是if...else语句的捷径，有着if...else相同的结果

    接字段输出文本
    awk -F: '{print NR,$0}' /etc/passwd //输出处理数据的行号，每处理完一条记录，NR值加1
    awk -F":" '$3<5{print $1 $3}'/etc/passwd //输出第3列小于5的第1列与第3列数据
    awk -F ":" '($1～"root")&&(NF==7){print $1,$3}'/etc/passwd //输出包含7个字段，并且第1个字段中包含root的行第1与第2字段内容
    awk -F":" 'NR==3,NR==7{print $1,$7}' /etc/passwd //输出第3行到第7行中以冒号为分隔符的第1列与第7列的数据

    输出数据时插入文本标签：
    awk -F: '/^root/{print "Hi," $1}' /etc/passwd //输出以冒号为分隔符，以root开头的行第一列，且在前面插入“Hi,”
    awk '{print $1"--"$3}' 6.txt //输出第一列和第二列并加入普通字符 引号引用普通字符
    awk -F":" '$7～"/bash"{print $1}' /etc/passwd //输出冒号分隔且第7个字段中包含/bash的行的第1个字段
    awk -F':''{print $1":"$2":"$3":"$4}' /etc/passwd //保留原来的格式，输出以冒号为分隔，/etc/passwd文件的前4个字段
    awk -F":" '{print $1,$3}' /etc/passwd //输出以冒号为分隔符的第1列和第3列
    awk 'BEGIN{FS=":"} {print $1,$3}' /etc/passwd //输出以冒号为分隔符的第1列和第3列
    awk 'BEGIN{X=0};/\/bin\/bash$/{x++};END{printx}' /etc/passwd //统计以/bin/bash为结尾的行数

    awk执行顺序:首先执行BEGIN{}中的操作，然后从指定的文件中逐行读取数据，自动更新NF、NR、$0、$1等内建变量的值，去s执行'模式或条件{编辑指令}’；最后执行END{}操作

    处理命令输出的结果：
    date |awk '{print "Month:"$2"\nYear:"$6}' //输出日期的第2列且在前面插入Month:,换行输出第6列并在前面插入Year
    sort工具
    分为：字符排序 ，数字排序
    语法格式：
    sort [选项] 参数
    常用选项
    -f ：忽略大小写
    -b ：忽略每行前面的空格
    -M ：按照月份进行排序
    -n ：按照数字进行排序
    -r ：反向排序
    -u ：等同于uniq,表示相同的数据仅显示一行
    -t ：指定分隔符
    -o ：<输出文件> ： 将排序后的结果转存指定文件 如：sort -t”;” /etc/passwd -o user.txt
    -k ：指定排序区域
```

## uniq

用于报告或者忽略文件中的重要行,一般于sort 命令结合使用

**语法**
```
uniq [选项] 参数
```

**常用选项**
- -c ：进行计数
- -d ：仅显示重复行
- -u ：仅显示出现一次的行

参考
============

[grep, awk and sed. – three VERY useful command-line utilities](https://www.google.com.hk/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=2ahUKEwimgK7017zgAhWpHTQIHdGrANYQFjABegQICRAC&url=https%3A%2F%2Fwww-users.york.ac.uk%2F~mijp1%2Fteaching%2F2nd_year_Comp_Lab%2Fguides%2Fgrep_awk_sed.pdf&usg=AOvVaw0np7_TlTZOLKf4aQk99DfX)

[A brief introduction to grep, awk & sed](http://blog.cee.moe/a-brief-introduction-to-grep-awk-and-sed.html)


版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)

