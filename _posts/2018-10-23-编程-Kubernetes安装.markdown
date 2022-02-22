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

2. 禁用SELINUX和swap：

```
setenforce 0
// 查看
cat /etc/selinux/config
SELINUX=disabled
```

swapoff -a  ，关闭swap,否则init环境会出错

要永久关闭swap，可以注释掉/etc/fstab文件中的swap挂载

```
#
# /etc/fstab
# Created by anaconda on Thu Feb  1 23:47:23 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/centos-root /                       xfs     defaults        0 0
UUID=de5ef523-bdbb-42c3-9095-f43bd8a2a85c /boot                   xfs     defaults        0 0
#/dev/mapper/centos-swap swap                    swap    defaults        0 0

```

3. 安装docker

卸载旧docker

```
yum -y remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine \
                  docker-ce \
                  docker-ce-selinux  
                                 
rm -rf /var/lib/docker /etc/systemd/system/docker.service.d
```

安装依赖

```
yum install -y yum-utils device-mapper-persistent-data lvm2 
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
```

能直接访问官方源的话:https://download.docker.com/linux/centos/docker-ce.repo

安装k8s支持版本的docker-ce，,查看源中都有哪些版本：

```
yum list docker-ce --showduplicates
```

安装17.03.1版：

```
yum install -y --setopt=obsoletes=0 \
        docker-ce-17.03.1.ce-1.el7.centos \
        docker-ce-selinux-17.03.1.ce-1.el7.centos
```

docker启动参数配置

```
vi /etc/docker/daemon.json 

{
"registry-mirrors": ["https://kzflpq4b.mirror.aliyuncs.com"]
}

```

启动并设置开机自启。

```
systemctl enable docker && systemctl start docker && systemctl status docker -l
```

添加当前用户到docker组

```
usermod -aG docker $(whoami)
```

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

**注意:**此种安装方式比较复杂，不推荐使用，推荐使用科学上网全局代理的方式从官方下载，省事省心。具体方法为 export all_proxy=<代理地址>：

具体代理地址的格式如下：

	- user:pass@10.0.0.10:8080
	
	- socks4://10.0.0.51:1080
	
	- socks5://192.168.1.1:1080

	例如我有一个1080端口的无需账号密码的socks5代理服务器：
```
 export all_proxy=socks5://172.16.1.252:1080
 export no_proxy="localhost,127.0.0.1,::1,172.16.0.0/16,10.0.0.0/8"
```

其中，no_proxy需要加入不通过代理访问的地址，包括本机地址、局域网地址，和用于Pod Network的地址段。当然了如果没有科学上网代理的话，就只有用如下方式了。

kubernetes 服务启动依赖很多镜像，但是这些镜像要是在国内没有翻墙的话，是下载不下来的。,如果没有科学上网代理的话，就只有下面的两种方式了。

- 初始化时指定镜像地址

即跳过一步，在kubeadm init通過--image-repository設置從其他倉庫拉去鏡像。例如

```
kubeadm init --image-repository="mirrorgooglecontainers"
```

- 下载并tag

这里我们可以去 Docker Hub 下载指定版本的镜像替代，下载完成后，通过 docker tag ... 命令修改成指定名称的镜像即可。也可以用如下脚本下载。

参考： [gcr.io mirror](https://github.com/anjia0532/gcr.io_mirror)


查看需要哪些镜像

```
kubeadm config images list --kubernetes-version=v1.12.2 

k8s.gcr.io/kube-apiserver:v1.12.2 
k8s.gcr.io/kube-controller-manager:v1.12.2 
k8s.gcr.io/kube-scheduler:v1.12.2 
k8s.gcr.io/kube-proxy:v1.12.2 
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.2.24
k8s.gcr.io/coredns:1.2.2
```

由于gcr.io被墙，从anjia0532镜像地址下载并重新打回k8s.gcr.io的镜像tag

```
#!/bin/bash
docker pull anjia0532/google-containers.kube-controller-manager:v1.12.2 
docker pull anjia0532/google-containers.kube-apiserver:v1.12.2 
docker pull anjia0532/google-containers.kube-scheduler:v1.12.2 
docker pull anjia0532/google-containers.kube-proxy:v1.12.2 
docker pull anjia0532/google-containers.pause:3.1
docker pull anjia0532/google-containers.etcd:3.2.24
docker pull anjia0532/google-containers.coredns:1.2.2
docker pull anjia0532/google-containers.coredns:1.1.3

docker tag anjia0532/google-containers.kube-controller-manager:v1.12.2  k8s.gcr.io/kube-controller-manager:v1.12.2 
docker tag anjia0532/google-containers.kube-apiserver:v1.12.2  k8s.gcr.io/kube-apiserver:v1.12.2 
docker tag anjia0532/google-containers.kube-scheduler:v1.12.2  k8s.gcr.io/kube-scheduler:v1.12.2 
docker tag anjia0532/google-containers.kube-proxy:v1.12.2  k8s.gcr.io/kube-proxy:v1.12.2 
docker tag anjia0532/google-containers.pause:3.1 k8s.gcr.io/pause:3.1
docker tag anjia0532/google-containers.etcd:3.2.24 k8s.gcr.io/etcd:3.2.24
docker tag anjia0532/google-containers.coredns:1.2.2 k8s.gcr.io/coredns:1.2.2
docker tag anjia0532/google-containers.coredns:1.1.3 k8s.gcr.io/coredns:1.1.3

docker rmi anjia0532/google-containers.kube-controller-manager:v1.12.2 
docker rmi anjia0532/google-containers.kube-apiserver:v1.12.2 
docker rmi anjia0532/google-containers.kube-scheduler:v1.12.2 
docker rmi anjia0532/google-containers.kube-proxy:v1.12.2 
docker rmi anjia0532/google-containers.pause:3.1
docker rmi anjia0532/google-containers.etcd:3.2.24
docker rmi anjia0532/google-containers.coredns:1.2.2
docker rmi anjia0532/google-containers.coredns:1.1.3
clear && docker images
```

更简洁的脚本,作用同上：

```
#!/bin/bash 
images=(kube-proxy:v1.12.2 kube-scheduler:v1.12.2 kube-controller-manager:v1.12.2 kube-apiserver:v1.12.2 etcd:3.2.24 pause:3.1 coredns:1.2.2) 
for imageName in ${images[@]} ; do 
    docker pull anjia0532/google-containers.$imageName 
    docker tag anjia0532/google-containers.$imageName k8s.gcr.io/$imageName
    docker rmi anjia0532/google-containers.$imageName 
done
```

7. 安装配置kubeadm和相关工具

```
yum install -y kubelet kubeadm kubectl kubernetes-cni ebtables ethtool cri-tools socat
```

使用下列命令查看docker当前使用的cgroup

```
docker info | grep -i cgroup
Cgroup Driver: cgroupfs
```

修改配置文件:

```
 sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```

或者打开文件修改:

```
vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
增加EXTRA_ARGS一行修改cgroup-driver=cgroupfs
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=cgroupfs"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_KUBEADM_ARGS \$KUBELET_EXTRA_ARGS
```

启动并设置开机自启
```
systemctl enable kubelet.service && systemctl start kubelet.service
```

8. 执行如下命令初始化安装

配置完主机后，我们可以启动 Master 节点了。在执行初始化 init 时，kubernetes 并没有选择默认的 Pod Network，它支持很多种，这里我们选择 Flannel 作为 Pod Network，按照文档说明，执行 init 时，需要带上参数 --pod-network-cidr，即指定网络区间，同时我们也可以通过 --kubernetes-version 指定选择 kubernetes 的版本号，因为我们镜像以及 rpm 包都是指定 1.12.2  的版本，所以最终执行命令如下：

```
kubeadm init --image-repository="mirrorgooglecontainers" --apiserver-advertise-address=172.16.1.240 --pod-network-cidr=10.244.0.0/16

[init] using Kubernetes version: v1.12.2
[preflight] running pre-flight checks
[preflight/images] Pulling images required for setting up a Kubernetes cluster
[preflight/images] This might take a minute or two, depending on the speed of your internet connection
[preflight/images] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[preflight] Activating the kubelet service
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [v1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.16.1.240]
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] Generated etcd/ca certificate and key.
[certificates] Generated etcd/server certificate and key.
[certificates] etcd/server serving cert is signed for DNS names [v1 localhost] and IPs [127.0.0.1 ::1]
[certificates] Generated etcd/peer certificate and key.
[certificates] etcd/peer serving cert is signed for DNS names [v1 localhost] and IPs [172.16.1.240 127.0.0.1 ::1]
[certificates] Generated etcd/healthcheck-client certificate and key.
[certificates] Generated apiserver-etcd-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/kubernetes/pki"
[certificates] Generated sa key and public key.
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[controlplane] wrote Static Pod manifest for component kube-apiserver to "/etc/kubernetes/manifests/kube-apiserver.yaml"
[controlplane] wrote Static Pod manifest for component kube-controller-manager to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
[controlplane] wrote Static Pod manifest for component kube-scheduler to "/etc/kubernetes/manifests/kube-scheduler.yaml"
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[init] waiting for the kubelet to boot up the control plane as Static Pods from directory "/etc/kubernetes/manifests" 
[init] this might take a minute or longer if the control plane images have to be pulled
[apiclient] All control plane components are healthy after 23.003580 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.12" in namespace kube-system with the configuration for the kubelets in the cluster
[markmaster] Marking the node v1 as master by adding the label "node-role.kubernetes.io/master=''"
[markmaster] Marking the node v1 as master by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "v1" as an annotation
[bootstraptoken] using token: ikbsff.lfvobbh0dh7tz5fs
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 172.16.1.240:6443 --token ikbsff.lfvobbh0dh7tz5fs --discovery-token-ca-cert-hash sha256:4333032ba4fcec4c5597bb79172994fa4a133bf3d5a62d17fc2c57636c55bfa2

```

如果一切顺利的话，就会出现第8步的执行结果输出。此时我们需要好好保存一下 kubeadm join 172.16.1.240:6443 --token camkbo.hb74yl2iwfltryfs --discovery-token-ca-cert-hash，这是后边其他 Node 节点加入集群的通关文牒。

- 根据提示在非root用户中使用如下命令：

```
 mkdir -p $HOME/.kube
 sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
 sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

- 普通运行帐号创建完成后，部署flannel虚拟网络

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

**注意，此虚拟网络配置文件根据版本不同可能不同，需要查看下官方文档确定适用的版本 **

- 使用命令 kubectl get node 查看集群节点信息.

```
kubectl get node
NAME   STATUS     ROLES    AGE     VERSION
v1     Ready   master   4m51s   v1.12.2
```

- 使用命令 kubectl get pod --all-namespaces 查看当前节点所有的 pod。

```
kubectl get pod --all-namespaces

NAMESPACE     NAME                          READY   STATUS    RESTARTS   AGE
kube-system   coredns-576cbf47c7-ct27h      1/1     Running   0          3m26s
kube-system   coredns-576cbf47c7-z56nk      1/1     Running   0          3m26s
kube-system   etcd-v1                       1/1     Running   0          2m56s
kube-system   kube-apiserver-v1             1/1     Running   0          2m29s
kube-system   kube-controller-manager-v1    1/1     Running   0          2m43s
kube-system   kube-flannel-ds-amd64-b94cn   1/1     Running   0          86s
kube-system   kube-proxy-hjdp7              1/1     Running   0          3m26s
kube-system   kube-scheduler-v1             1/1     Running   0          2m50s
```

确保所有kube- 的pods状态都正常。至此主节点就部署完成了。

9. 初始化失败时怎么办

如果初始化时卡在某一步不能继续下去的时候，可以通过 journalctl -xeu kubelet 查看初始化日志，找到错误原因。 

如果一直解决不了，可以重置后重新开始初始化。

```
kubeadm reset
ip link delete flannel.1
ip link delete cni0
rm -rf /var/lib/etcd/*
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

12. 部署其他节点

Node 节点在完成第7步后，不需要初始化集群，机器初始化就简单了，如果使用的是虚拟机，那么只需要将配置好的主机环境复制一份就好了。如果使用实体机的话，那就需要重新安装配置一遍。不要忘记修改 Node 节点的 hostname 。

将 Node 加入 cluster 集群中，使用 kubeadm join ... 命令。在 Node 节点上执行（上边执行 init 时日志打印的命令）,即把当前Node加入到集群中。

```
$ kubeadm join 172.16.1.240:6443 --token camkbo.hb74yl2iwfltryfs --discovery-token-ca-cert-hash
```

- 移除NODE节点

>#先将节点设置为维护模式(node2.ztpt.com是节点名称)

```
kubectl drain v2 --delete-local-data --force --ignore-daemonsets
```

>然后删除节点

```
kubectl delete node v2
```

- 如果忘记了kubeadm join怎么办？

>    kubeadm join使用的token默认有效期24小时，过期后可使用kubeadm token creat创建。

>    如果忘记了可使用kubeadm token list查看，如果过期了还是得重新创建。

>    如果连--discovery-token-ca-cert-hash的值也忘记了，就需要用命令

```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2&gt;/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```

查看,然后用新的token和ca-hash加入集群。

国内翻墙安装困难级数大增，可以考虑使用minikube
============

[国内阿里云源minikube](https://yq.aliyun.com/articles/221687)

[minikube体验](https://www.cnblogs.com/cocowool/p/minikube_setup_and_first_sample.html)

参考
============

[官方安装文档](https://kubernetes.io/docs/setup/independent/install-kubeadm/)

[how-to-install-a-kubernetes-cluster-on-centos-7](https://www.techrepublic.com/article/how-to-install-a-kubernetes-cluster-on-centos-7/)

[Github Release](https://github.com/kubernetes/release)

[docker安装指南](https://docs.docker.com/install/linux/docker-ce/centos)

[docker启动参数](https://docs.docker.com/engine/reference/commandline/dockerd/)

版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)

