---
layout: post
title:  "Linux-Manjaro安装于lvm"
categories: linux
tags: linux 
author: xueyp
description: Manjaro不能安装于lvm的问题
---

# 介绍 

## Manjaro

以前长期使用gentoo作为开发环境，后来新入笔记本电脑，发现Manjaro已经排名发行版第一，加上不想在笔记本上经常编译，就尝试了一下，一直使用至今，***Manjaro确实是桌面环境使用最适用的发行版***

Manjaro具有如下优点：

- 简单、用户友好的图形化安装程序
- 自动检测计算机的硬件（例如显卡）
- 为系统自动安装必要的软件（例如图形驱动程序）
- 它自己的专用软件仓库，以确保提供完全测试过的稳定的软件包
- 支持轻松安装和使用多个内核。
- 预安装桌面环境
- 独家开发的pamac软件管理器，轻松安装软件和更新您的系统
- 预安装编解码器播放多媒体文件

总的来说，对非服务器环境，保持系统稳定和应用软件相对新的前提下，Manjaro比较适用，也不需要折腾驱动等玩意，运行流畅。

## lvm

LVM利用Linux内核的device-mapper来实现存储系统的虚拟化（系统分区独立于底层硬件）。 通过LVM，你可以实现存储空间的抽象化并在上面建立虚拟分区（virtual partitions），可以更简便地扩大和缩小分区，可以增删分区时无需担心某个硬盘上没有足够的连续空间。

LVM是用来方便管理的，不会提供额外的安全保证。

LVM的基本组成块（building blocks）如下：

- 物理卷Physical volume (PV)：可以在上面建立卷组的媒介，可以是硬盘分区，也可以是硬盘本身或者回环文件（loopback file）。物理卷包括一个特殊的header，其余部分被切割为一块块物理区域（physical extents）。
- 卷组Volume group (VG)：将一组物理卷收集为一个管理单元。
- 逻辑卷Logical volume (LV)：虚拟分区，由物理区域（physical extents）组成。
- 物理区域Physical extent (PE)：硬盘可供指派给逻辑卷的最小单位（通常为4MB）。

具体操作也是一目了然：[https://www.jianshu.com/p/dca0b8b42f2a](https://www.jianshu.com/p/dca0b8b42f2a)

# Manjaro安装于lvm

之所以有这个问题，是因为Manjaro目标用户为桌面环境，通常用不到lvm，但是由于需要在一个服务器中部署,用于爬虫,elk等的实验，需要考虑到后续爬取数据过多时的存储问题，虽然可以使用centos等服务器发行版，但考虑到我们的是实验环境，虽然安装于服务器，但实际是通过远程访问作为桌面环境来使用的。对稳定性要求不高，希望使用较新的软件包，故选用了Manjaro。

但是安装时配置lvm后，到安装grub总是卡死无法成功。后来结合安装程序和手动安装grub的方式成功安装。

具体步骤如下：

- 启动安装镜像

首先使用[光盘或写入u盘的镜像](https://Manjaro.org/download/architect/)启动系统

## 分区和配置lvm

- 硬盘分为两个区

    - efi /dev/sda1 
    - lvm /dev/sda2 

- 建立物理卷：在 /dev/sda2建立物理卷

```
pvcreate /dev/sda2
```

- 建立卷组：新建名为linux的卷组并将sda2加入到卷组中

```
vgcreate linux /dev/sda2
```

- 建立逻辑卷：在linux卷组中建立root和home逻辑卷

```
lvcreate -L 100G linux -n root
lvcreate -l +100%FREE linux -n home  # 用linux卷组中所有剩余空间建立home逻辑卷
```

- 建立文件系统

```
mkfs.vfat /dev/sda1                 #格式化esp
mkfs.ext4 /dev/mapper/Linux-root    #格式化root
mkfs.ext4 /dev/mapper/Linux-home    #格式化home
```

没有创建swap分区，使用swapfile

## 挂载lvm分区

```
mkdir /mnt/hostlvm
mount --bind /run/lvm /mnt/hostlvm
```

## 按正常流程安装系统

安装系统，root分区选择/dev/linux/root,home分区选择/dev/linux/home，efi分区选择/dev/sda1。

到安装grub时，跳过，进行后续系统基础配置，包括生成fstab,设置root密码，增加新用户等。

## 安装grub

先把主机的lvm映射到chroot环境的/run/lvm

```
Manjaro-chroot /mnt
ln -s /hostlvm /run/lvm
```

efi启动的需要先挂载

```
mount /dev/sda1 /boot/efi
```

再安装grub

```
pacman -S grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Manjaro
update-grub
```

然后重启即可正常使用。

版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.        github.io/)

