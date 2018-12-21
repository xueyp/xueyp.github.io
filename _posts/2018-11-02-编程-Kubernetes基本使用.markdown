---
layout: post
title:  "编程-Kubernetes基本使用"
categories: 编程
tags: kubernetes 微服务
author: xueyp
description: 
---

# 基本功能 

Kubernetes主要由以下几个核心组件组成：

- etcd保存了整个集群的状态
- apiserver提供了资源操作的唯一入口，并提供认证、授权、访问控制、API注册和发现等机制
- controller manager负责维护集群的状态，比如故障检测、自动扩展、滚动更新等
- scheduler负责资源的调度，按照预定的调度策略将Pod调度到相应的机器上
- kubelet负责维护容器的生命周期，同时也负责Volume（CVI）和网络（CNI）的管理
- Container runtime负责镜像管理以及Pod和容器的真正运行（CRI）
- kube-proxy负责为Service提供cluster内部的服务发现和负载均衡

除了核心组件，还有一些推荐的Add-ons：

- kube-dns负责为整个集群提供DNS服务
- Ingress Controller为服务提供外网入口
- Heapster提供资源监控
- Dashboard提供GUI
- Federation提供跨可用区的集群

下面通过一个简单的例子说明k8s的使用过程，使用非常简单，通过yaml写好配置文件，然后导入集群并执行即可。

1. 部署应用

- Pod创建

```
vi pod-redis.yaml

apiVersion: v1
kind: Pod
metadata:
  name:  pod-redis
  labels:
     name: pod-redis
spec:
      containers:
      - name: pod-redis
        image: docker.io/redis
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 6379
~

```

yaml定义文件中的kind属性，用来表示此资源对象的类型，比如这里是一个Pod。

spec一节中是RC的相关属性定义,需要注意的重要选项：

	- imagePullPolicy: IfNotPresent #三个选择Always、Never、IfNotPresent，每次启动时检查和更新（registery）images的策略 。

	- containerPort: 6379	#容器开发对外的端口 

- 发布到Kubernetes集群

在Master节点中该文件目录下执行以下命令：

```
$ kubectl create -f pod-redis.yaml
pod/pod-redis created
```

执行以下命令查看结果:

```
$ kubectl get pods

NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-7476558597-7pv4j   0/1     Pending   0          29m
pod-redis    						   1/1     Running   0          5m26s
```

- Service创建

上一步已经完成了pod的创建，这里将创建一个对外的服务。

```
vi svc.yaml

apiVersion: v1
kind: Service                   
metadata:
  name: redis-service                 
spec:
  type: NodePort             
  ports:
  - port: 6379                  
    nodePort: 30000        
  selector:
    app: pod-redis                 
```

其中，metadata.name是服务名称，port属性则定义了服务的虚拟端口，spec.selector确定了哪些Pod副本（实例）对应到本服务。

注意type=NodePort和nodePort=30000的两个属性，表明此服务开启了NodePort方式的外网访问模式，且访问端口为30001。

之后我们同样执行以下命令，创建服务：

```
$ kubectl create -f svc.yaml
service/redis-service created
```

完成之后，使用以下命令查看结果：

```
$ kubectl get svc
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
kubernetes      ClusterIP   10.96.0.1     <none>        443/TCP          144m
redis-service   NodePort    10.98.73.68   <none>        6379:30000/TCP   40s
```

此时就可以通过外网来访问的数据库了，当然端口号是30000。

- RC创建

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-ingress-rc
  labels:
    app: nginx-ingress
spec:
  replicas: 1
  selector:
    app: nginx-ingress
  template:
    metadata:
      labels:
        app: nginx-ingress
    spec:
      serviceAccountName: nginx-ingress
      containers:
      - image: nginx/nginx-ingress:edge
        imagePullPolicy: Always
        name: nginx-ingress
        ports:
        - containerPort: 80
          hostPort: 80
        - containerPort: 443
          hostPort: 443
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        # Uncomment the lines below to enable extensive logging and/or customization of
        # NGINX configuration with configmaps
        args:
         #- -v=3
         #- -nginx-configmaps=$(POD_NAMESPACE)/nginx-config
          - -default-server-tls-secret=$(POD_NAMESPACE)/default-server-secret

```

查看rc:

```
$ kubectl get rc
NAME               DESIRED   CURRENT   READY   AGE
nginx-ingress-rc   1         0         0       10s

```
更高级的使用方法见[官方使用教程](https://kubernetes.io/docs/tutorials/)。

总结
===========

k8s作为一个编排容器的工具，管理了应用的全生命周期：从创建应用，应用的部署，应用提供服务，扩容缩容应用，应用更新，都非常的方便，而且可以做到故障自愈，例如一个服务器挂了，可以自动将这个服务器上的服务调度到另外一个主机上进行运行，无需进行人工干涉。
 
k8s可以更快的更新新版本，打包应用，更新的时候可以做到不用中断服务，服务器故障不用停机，从开发环境到测试环境到生产环境的迁移极其方便，一个配置文件搞定，一次生成image，到处运行。符合当下DevOps的理念。
 
k8s集群调度的最小单元就是一个pod，一个pod可以是一个容器，也可以是多个容器。一个pod只能运行在一个主机上，而一个主机上可以有多个pod。**为什么要使用pod，而不直接使用容器呢？**使用pod，相当与一个逻辑主机，这和创建一个vm，在vm上运行几个进程是一样的，pod在紧密连接的几个容器之间共享资源，例如ip地址，共享存储等信息。如果直接调度容器的话，那么几个容器可能运行在不同的主机上，资源开销相对大，也更复杂。

参考
============

[官方使用教程](https://kubernetes.io/docs/tutorials/)

[nginx k8s example](http://containertutorials.com/get_started_kubernetes/k8s_example.html)

版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
