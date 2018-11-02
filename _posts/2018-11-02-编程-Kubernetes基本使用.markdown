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

- RC创建

```
vi mysql-rc.yaml

apiVersion: v1
kind: ReplicationController         
metadata:
  name: mysql                             
spec:
  replicas: 1                                 
  selector:
    app: mysql                               
  template:                                  
    metadata:
      labels:
        app: mysql                          
    spec:
      containers:                            
      - name: mysql                       
        image: 172.16.1.240:5000/mysql:5.7.20   
        ports:
        - containerPort: 3306          
        env:                                    
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
```

yaml定义文件中的kind属性，用来表示此资源对象的类型，比如这里的值为ReplicationController，表示这是一个RC。

spec一节中是RC的相关属性定义，比如spec.selector是RC的Pod标签（label）选择器，即监控和管理拥有这些标签的Pod实例，确保当前集群上始终有且仅有replicas个Pod实例在运行，这里我们设置replicas=1表示只运行一个MySQL Pod实例。

当集群中运行的Pod实例数量小于replicas时，RC会根据spec.template一节中定义的Pod模板来生成一个新的Pod实例。

spec.template.metadata.labels指定了该Pod的标签，需要特别注意的是：这里的labels必须匹配之前的spec.selector，否则此RC每次创建了一个无法匹配Label的Pod，就会不停的尝试创建新的Pod。

- 发布到Kubernetes集群

在Master节点中该文件目录下执行以下命令：

```
kubectl create -f mysql-rc.yaml
replicationcontroller/mysql created
```

执行以下命令查看结果:

```
kubectl get rc

NAME    DESIRED   CURRENT   READY   AGE
mysql   1         1         0       30s
```


```
kubectl get pods

NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-7476558597-7pv4j   0/1     Pending   0          29m
myapp-pod                              0/1     Unknown   0          44h
mysql-fbzft                            0/1     Pending   0          35s
nginx-deployment-5c689d88bb-2h6vl      1/1     Unknown   1          44h
nginx-deployment-5c689d88bb-hzpnj      1/1     Unknown   1          44h
nginx-deployment-5c689d88bb-lzd7n      0/1     Pending   0          43h
nginx-deployment-5c689d88bb-zs8mq      0/1     Pending   0          43h
```

- Service创建

上一步已经完成了pod和ReplicationController的创建，这里将创建一个对外的服务。

```
vi mysql-svc.yaml

apiVersion: v1
kind: Service                   
metadata:
  name: mysql                 
spec:
  type: NodePort             
  ports:
  - port: 3306                  
    nodePort: 30001        
  selector:
    app: mysql                 
```

其中，metadata.name是服务名称，port属性则定义了服务的虚拟端口，spec.selector确定了哪些Pod副本（实例）对应到本服务。

注意type=NodePort和nodePort=30001的两个属性，表明此服务开启了NodePort方式的外网访问模式，且访问端口为30001。

之后我们同样执行以下命令，创建服务：

```
kubectl create -f mysql-svc.yaml 

service/mysql created
```

完成之后，使用以下命令查看结果：

```
kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          47h
mysql        NodePort    10.108.62.241   <none>        3306:30001/TCP   67s
```

此时就可以通过外网来访问的数据库了，当然端口号是30001。

更高级的使用方法见[官方使用教程](https://kubernetes.io/docs/tutorials/)。

参考
============

[官方使用教程](https://kubernetes.io/docs/tutorials/)


版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)
