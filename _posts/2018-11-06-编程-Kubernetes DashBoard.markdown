---
layout: post
title:  "编程-Kubernetes Dashboard"
categories: 编程
tags: kubernetes 微服务
author: xueyp
description: 
---

# 基本功能 

K8S Dashboard是官方的一个基于WEB的用户界面，专门用来管理K8S集群，并可展示集群的状态。K8S集群安装好后默认没有包含Dashboard，我们需要额外创建它。

## 官方kubernetes-dashboard.yaml

- 下载官方yaml

```
wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

该文件分为以下几部分：

- Dashboard Role

定义了Dashboard 的角色，其角色名称为kubernetes-dashboard-minimal，rules中清晰的列出了其拥有的多个权限。

- Dashboard Service Account

定义了Dashboard的用户，其类型为ServiceAccount，名称为kubernetes-dashboard。

- RoleBinding

定义了Dashboard的角色绑定，其名称为kubernetes-dashboard-minimal，roleRef中为被绑定的角色，也叫kubernetes-dashboard-minimal，subjects中为绑定的用户：kubernetes-dashboard。

- Dashboard Deployment

Dashboard的Deployment指定了其使用的ServiceAccount是kubernetes-dashboard。并且还将Secret kubernetes-dashboard-certs通过volumes挂在到pod内部的/certs路径。创建Secret 时会自动生成token。参数--auto-generate-certificates，其表示Dashboard会自动生成证书。

- Dashboard Service

- Dashboard Secret

## 创建certs

```
kubectl create secret generic kubernetes-dashboard-certs --from-file=$HOME/certs -n kube-system
```

## 导入镜像

若能够直接访问墙外网站，刚直接用下面命令可安装成功:

```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

墙内则需要先下载dashboard镜像，然后从本地导入：

下载地址：[k8s.gcr.io_kubernetes-dashboard-amd64_v1.10.0.tar](https://pan.baidu.com/s/13QhdA6itchptm6emzv_TAQ)

导入：

```
docker load < k8s.gcr.io_kubernetes-dashboard-amd64_v1.10.0.tar 

Loaded image: k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.0
```

查看镜像是否导入成功：

```
docker images

REPOSITORY                              TAG                 IMAGE ID            CREATED             SIZE
k8s.gcr.io/kube-proxy                   v1.12.2             15e9da1ca195        12 days ago         96.5MB
k8s.gcr.io/kube-apiserver               v1.12.2             51a9c329b7c5        12 days ago         194MB
k8s.gcr.io/kube-controller-manager      v1.12.2             15548c720a70        12 days ago         164MB
k8s.gcr.io/kube-scheduler               v1.12.2             d6d57c76136c        12 days ago         58.3MB
k8s.gcr.io/etcd                         3.2.24              3cab8e1b9802        6 weeks ago         220MB
k8s.gcr.io/coredns                      1.2.2               367cdc8433a4        2 months ago        39.2MB
k8s.gcr.io/kubernetes-dashboard-amd64   v1.10.0             0dab2435c100        2 months ago        122MB
quay.io/coreos/flannel                  v0.10.0-amd64       f0fad859c909        9 months ago        44.6MB
k8s.gcr.io/pause                        3.1                 da86e6ba6ca1        10 months ago       742kB
```

可以看到导入了v1.10.0的dashboard镜像。

## 创建Dashboard

导入镜像后，使用之前下载的yaml文件即可创建Dashboard：

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

secret/kubernetes-dashboard-certs created
serviceaccount/kubernetes-dashboard created
role.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
deployment.apps/kubernetes-dashboard created
service/kubernetes-dashboard created
```

也可以用安全级别低些的安装配置文件：

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/alternative/kubernetes-dashboard.yaml
```

## 访问Dashboard

- 使用kubectl proxy

最便捷的访问方式是通过kubectl proxy。在Master上执行kubecll proxy，然后使用如下地址访问Dashboard：
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

但默认限制必须在Master上访问，这显然不方便，我们需要的是从其他机器上通过Master的外网ip访问其Dashboard。在Master上，执行kubectl proxy --address=172.16.1.240 --disable-filter=true开启代理。

这样，我们就可以使用如下地址访问登录界面：

http://172.16.1.240:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

其中：

> address表示外界可以使用172.16.1.240来访问Dashboard，也可以使用0.0.0.0

> disable-filter=true表示禁用请求过滤功能，否则我们的请求会被拒绝，并提示 Forbidden (403) Unauthorized。

> 我们也可以指定端口，具体请查看kubectl proxy --help

## 配置Dashboard

Dashboard的配置是难点，尤其是涉及到安全权限相关，相当复杂。

进入Dashboard的登录界面后，认证方式有Kubeconfig和令牌两种方式（实际上还有账号密码的方式，默认不开启不显示）。在测试环境中，我们可以选择直接跳过配置进入使用界面，具体方法是更改RoleBinding修改为ClusterRoleBinding，并且替换roleRef中的kind和name，使用cluster-admin这个CusterRole（超级用户权限，其拥有访问kube-apiserver的所有权限）。如下：

```
vi kubernetes-dashboard.yaml 
从第76行开始的内容
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
```

修改后，重新创建kubernetes-dashboard.yaml，Dashboard就可以拥有访问整个K8S 集群API的权限。我们重新访问Dashboard，即可正常操作了。

删除重新新创建:

```
kubectl delete -f kubernetes-dashboard.yaml

kubectl create -f kubernetes-dashboard.yaml
```

# 其他

本地实验环境可以使用minikube等简易部署工具。


参考
============

[web-ui-dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

[dashboard on github ](https://github.com/kubernetes/dashboard)

[Accessing Dashboard](https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above）

[CrashLoopBackOff](https://github.com/kubernetes/dashboard/issues/1287#issuecomment-250681546)

[minikube 本地简易部署工具](https://shapeshed.com/getting-started-with-kubernetes/)

版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
