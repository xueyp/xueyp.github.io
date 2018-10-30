---
layout: post
title:  "编程-kubernetes安装"
categories: 编程
tags: kubernetes 微服务
author: xueyp
description: 
---

# kubeadm 安装步骤

1. 首先禁用防护墙

```
systemctl disable firewalld
systemctl stop firewalld
```

2. 禁用SELINUX：

```
setenforce 0
// 查看
cat /etc/selinux/config
SELINUX=disabled
```

3. swapoff -a  ，关闭swap,否则init环境会出错

4. 修改网络开启桥接网络支持，

注意，只有RHEL/CentOS 7系统需要做这一步。

创建/etc/sysctl.d/k8s.conf文件，添加如下内容：

```
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
```

5. 设置k8s yum源

若不能访问google,请使用阿里云源 .

```
vi /etc/yum.repos.d/kubernetes.repo
```

官方源

```
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
```

阿里云源

```
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
```

6. 下载好所需的镜像，并修改tag

kubernetes 服务启动依赖很多镜像，但是这些镜像要是在国内没有翻墙的话，是下载不下来的。这里我们可以去 Docker Hub 下载指定版本的镜像替代，下载完成后，通过 docker tag ... 命令修改成指定名称的镜像即可。也可以用如下脚本下载。

```
#!/bin/bash
images=(kube-proxy-amd64:v1.12.0 kube-scheduler-amd64:v1.12.0 kube-controller-manager-amd64:v1.12.0 kube-apiserver-amd64:v1.12.0
etcd-amd64:3.2.18 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3 )
for imageName in ${images[@]} ; do
  docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
  docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName k8s.gcr.io/$imageName
  docker rmi registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
done

images2=(k8s-dns-sidecar-amd64:1.14.9 k8s-dns-kube-dns-amd64:1.14.9
k8s-dns-dnsmasq-nanny-amd64:1.14.9 )
for imageName in ${images2[@]} ; do
  docker pull registry.cn-beijing.aliyuncs.com/k8s_images/$imageName
  docker tag registry.cn-beijing.aliyuncs.com/k8s_images/$imageName k8s.gcr.io/$imageName
  docker rmi registry.cn-beijing.aliyuncs.com/k8s_images/$imageName
done
docker tag da86e6ba6ca1 k8s.gcr.io/pause:3.1
```

7. 安装kubeadm和相关工具

```
yum install -y docker kubelet kubeadm kubectl kubernetes-cni ebtables ethtool
```

启动docker并设置自启。

```
systemctl enable docker && systemctl start docker

systemctl enable kubelet && systemctl start kubelet
```
 

8. 执行如下命令初始化安装

配置完主机后，我们可以启动 Master 节点了。在执行初始化 init 时，kubernetes 并没有选择默认的 Pod Network，它支持很多种，这里我们选择 Flannel 作为 Pod Network，按照文档说明，执行 init 时，需要带上参数 --pod-network-cidr，即指定网络区间，同时我们也可以通过 --kubernetes-version 指定选择 kubernetes 的版本号，因为我们镜像以及 rpm 包都是指定 1.12.0 的版本，所以最终执行命令如下：

```
kubeadm init --kubernetes-version=1.12.0 --token-ttl 0 --pod-network-cidr=10.244.0.0/16

[init] Using Kubernetes version: v1.12.0
[init] Using Authorization mode: RBAC
[preflight] Running pre-flight checks
[preflight] Starting the kubelet service
[certificates] Generated CA certificate and key.
[certificates] Generated API server certificate and key.
[certificates] API Server serving cert is signed for DNS names 
...
...
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular user):

  sudo cp /etc/kubernetes/admin.conf $HOME/
  sudo chown $(id -u):$(id -g) $HOME/admin.conf
  export KUBECONFIG=$HOME/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join --token 3aaf19.8e758a48f2050bd1 10.244.65.125:6443
```

如果一切顺利的话，就会出现第8步的执行结果输出。此时我们需要好好保存一下 kubeadm join --token 3aaf19.8e758a48f2050bd1 10.244.65.125:6443，这是后边其他 Node 节点加入集群的通关文牒。

使用命令 kubectl get node 查看集群节点信息.

使用命令 kubectl get pod --all-namespaces 查看当前节点所有的 pod。

9. 初始化失败时怎么办

如果初始化时卡在某一步不能继续下去的时候，可以通过 journalctl -xeu kubelet 查看初始化日志，找到错误原因。 

如果一直解决不了，可以重置后重新开始初始化。

```
kukbeadm reset
```

10. 查看相关日志

```
tail -n 1000 /var/log/messages
```

11. 删除相关镜像

```
docker rm $(docker ps -a -q) //删除所有已经停止的容器
docker rmi --force $(docker images | grep doss-api | awk '{print $3}') //强制删除镜像名称中包含“doss-api”的镜像
docker rmi $(docker images -q)//删除所有镜像
```

12. 安装 Flannel 网络组件

kubernetes 提供了很多种网络组件选择，有 Calia、Canal、Flannel、Kube-router、Romana、Weave Net 可以使用，具体使用可以参考 [官方文档 (3/4) Installing a pod network ](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)来操作.

13. 部署其他节点

Node 节点机器初始化就简单了，如果使用的是虚拟机，那么只需要将配置好的主机环境复制一份就好了。如果使用实体机的话，那就需要重新安装配置一遍。不要忘记修改 Node 节点的 hostname 。

将 Node 加入 cluster 集群中，使用 kubeadm join ... 命令。在 Node 节点上执行（上边执行 init 时日志打印的命令）,即把当前Node加入到集群中。

```
$ kubeadm join --token 3aaf19.8e758a48f2050bd1 10.244.65.125:6443
```

参考
============
[官方文档](https://kubernetes.io/docs/setup/independent/install-kubeadm/)

[Github Release](https://github.com/kubernetes/release)

版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
