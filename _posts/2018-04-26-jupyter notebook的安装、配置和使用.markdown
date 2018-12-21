---
layout: post
title:  "jupyter notebook 安装、配置及使用"
categories: Python
tags: jupyter notebook python
author: xueyp
description: 
---

安装
============
1.安装python和notebook

    sudo pacman -S python jupyter

即可成功安装包括python和notebook的所有包。

配置
=======
更改工作空间

1.生成配置文件

    jupyter notebook --generate-config

2.打开配置文件

    vi ~/.jupyter/jupyter_notebook_config.py

找到

    # The directory to use for notebooks and kernels.
    # c.NotebookApp.notebook_dir = u''

修改为想要的目录，例如 ~/PythonProjects

    c.NotebookApp.notebook_dir = u'~/PythonProjects'

使用
======
1.直接在shell中执行`jupyter notebook`,notebook启动成功后后自动跳转到使用页面，或手动使用浏览器访问 [http://localhost:8888](http://localhost:8888).

2.常用快捷键

*执行当前cell，并自动跳到下一个cell：Shift Enter

*执行当前cell，执行后不自动调转到下一个cell：Ctrl-Enter

*使当前的cell进入编辑模式：Enter

*退出当前cell的编辑模式：Esc

*删除当前的cell：双D

*为当前的cell加入line number：单L

*将当前的cell转化为具有一级标题的maskdown：单1

*将当前的cell转化为具有二级标题的maskdown：单2

*将当前的cell转化为具有三级标题的maskdown：单3

*为一行或者多行添加/取消注释：Crtl /

*撤销对某个cell的删除：z

*浏览器的各个Tab之间切换：Crtl PgUp和Crtl PgDn

*快速跳转到首个cell：Crtl Home

*快速跳转到最后一个cell：Crtl End

导入现有代码以及作为shell使用
======

1.导入本地.py文件到cell

问题背景：有一个test.py文件，内容如下：

    import caffe
    SolverName = "/root/workspace"
    sovler = caffe.AdamSolver(SolverName)

方法步骤：

（1）在需要导入该段代码的cell中输入

    %load test.py #test.py是当前路径下的一个python文件

（2）运行该cell

利用快捷键“Shift+Enter”，可以看到结果

（3）可以看到，运行后，%load 
test.py被自动加入了注释符号#，test.py中的所有代码都被load到了当前的cell中

2.从网络load代码到jupyter

在cell中输入`%load http://.....`然后运行该cell，就会将load后面所对应地址的代码load到当前的cell中

3.运行python文件

利用jupyter的cell是可以运行python文件的，即在cell中运行如下代码：

    %run file.py

4.作为shell

具体方法为：在unitx command前面加入一个感叹号“！”

例子：

查看python版本：

    !python --version

运行python文件：

    !python myfile.py

代码补全
======

代码补全是通过 jupyter 扩展插件Nbextensions库来实现。

安装该库的命令如下：

```
    python -m pip install jupyter_contrib_nbextensions
```

然后执行：

```
    jupyter contrib nbextension install --user --skip-running-check
```

安装完成后，勾选 “Table of Contents” 以及 “Hinterland”。其中 Hinterland 是用来自动补全代码的，这个拓展的代码补全功能虽然没有 PyCharm中的那么全面，但比没有是要好多了。

版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
