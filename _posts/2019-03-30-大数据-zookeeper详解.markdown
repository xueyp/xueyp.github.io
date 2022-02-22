---
layout: post
title:  "大数据-ZooKeeper详解"
categories: 大数据
tags: 大数据
author: xueyp
description: 
---

# ZooKeeper 

ZooKeeper最初是hadoop生态圈的一个分布式协调框架，以便让开发人员将精力集中在处理业务逻辑上，后来也被其他分布式框架广泛使用。

Apache ZooKeeper是由集群（节点组）使用的一种服务，用于在自身之间协调，并通过稳健的同步技术维护共享数据。ZooKeeper本身是一个分布式应用程序，为写入分布式应用程序提供服务。

ZooKeeper提供的常见服务如下 :

- 命名服务 - 按名称标识集群中的节点。它类似于DNS，但仅对于节点
- 配置管理 - 加入节点的最近的和最新的系统配置信息
- 集群管理 - 实时地在集群和节点状态中加入/离开节点
- 选举算法 - 选举一个节点作为协调目的的Leader
- 锁定和同步服务 - 在修改数据的同时锁定数据。此机制可帮助你在连接其他分布式应用程序（如Apache HBase）时进行自动故障恢复
- 高度可靠的数据注册表 - 即使在一个或几个节点关闭时也可以获得数据

分布式应用程序提供了很多好处，但它们也抛出了一些复杂和难以解决的挑战。ZooKeeper框架提供了一个完整的机制来克服所有的挑战。竞争条件和死锁使用故障安全同步方法进行处理。另一个主要缺点是数据的不一致性，ZooKeeper使用原子性解析。

以下是使用ZooKeeper的好处：

- 简单的分布式协调过程
- 同步 - 服务器进程之间的相互排斥和协作。此过程有助于Apache HBase进行配置管理
- 有序的消息
- 序列化 - 根据特定规则对数据进行编码。确保应用程序运行一致。这种方法可以在MapReduce中用来协调队列以执行运行的线程
- 可靠性
- 原子性 - 数据转移完全成功或完全失败，但没有事务是部分的

## ZooKeeper架构

![png]({{"/assets/images/my/20190330_1.png"| absolute_url }})

- **Ensemble**:ZooKeeper服务器组。形成ensemble所需的最小节点数为3
- **Leader**:服务器节点，如果任何连接的节点失败，则执行自动恢复。Leader在服务启动时被选举
- **Follower**:跟随Leader指令的服务器节点

ZooKeeper文件系统的树结构见下图：

![png]({{"/assets/images/my/20190330_2.png"| absolute_url }})

ZooKeeper节点称为 Znode 。每个Znode由一个名称标识，并用路径(/)序列分隔。在图中，首先有一个由“/”分隔的Znode。在根目录下，你有两个逻辑命名空间 config 和 workers。config 命名空间用于集中式配置管理，workers 命名空间用于命名。在 config 命名空间下，每个Znode最多可存储1MB的数据。这与UNIX文件系统相类似，除了父Znode也可以存储数据。这种结构的主要目的是存储同步数据并描述Znode的元数据。此结构称为 ZooKeeper数据模型。

### Znode的类型

Znode被分为持久（persistent）节点，顺序（sequential）节点和临时（ephemeral）节点。

- **持久节点** : 即使在创建该特定Znode的客户端断开连接后，持久节点仍然存在。默认情况下，除非另有说明，否则所有Znode都是持久的。

- **临时节点** : 客户端活跃时，临时节点就是有效的。当客户端与ZooKeeper集合断开连接时，临时节点会自动删除。因此，只有临时节点不允许有子节点。如果临时节点被删除，则下一个合适的节点将填充其位置。临时节点在Leader选举中起着重要作用。

- **顺序节点** :顺序节点可以是持久的或临时的。当一个新的Znode被创建为一个顺序节点时，ZooKeeper通过将10位的序列号附加到原始名称来设置Znode的路径。例如，如果将具有路径 /myapp 的Znode创建为顺序节点，则ZooKeeper会将路径更改为 /myapp0000000001 ，并将下一个序列号设置为0000000002。如果两个顺序节点是同时创建的，那么ZooKeeper不会对每个Znode使用相同的数字。顺序节点在锁定和同步中起重要作用。

### Sessions（会话）

会话对于ZooKeeper的操作非常重要。会话中的请求按FIFO顺序执行。一旦客户端连接到服务器，将建立会话并向客户端分配会话ID 。

客户端以特定的时间间隔发送心跳以保持会话有效。如果ZooKeeper集合在超过服务器开启时指定的期间（会话超时）都没有从客户端接收到心跳，则它会判定客户端死机。

会话超时通常以毫秒为单位。当会话由于任何原因结束时，在该会话期间创建的临时节点也会被删除。

### Watches（监视）

监视是一种简单的机制，使客户端收到关于ZooKeeper集合中的更改的通知。客户端可以在读取特定Znode时设置Watches。Watches会向注册的客户端发送任何Znode（客户端注册表）更改的通知。

Znode更改是与Znode相关的数据的修改或Znode的子项中的更改。只触发一次watches。如果客户端想要再次通知，则必须通过另一个读取操作来完成。当连接会话过期时，客户端将与服务器断开连接，相关的watches也将被删除。

## ZooKeeper工作流

![png]({{"/assets/images/my/20190330_3.png"| absolute_url }})

- 写入（write）:写入过程由Leader节点处理。Leader将写入请求转发到所有Znode，并等待Znode的回复。如果一半的Znode回复，则写入过程完成
- 读取（read）:读取由特定连接的Znode在内部执行，因此不需要与集群进行交互
- 复制数据库（replicated database）:它用于在ZooKeeper中存储数据。每个Znode都有自己的数据库，每个Znode在一致性的帮助下每次都有相同的数据
- Leader:Leader是负责处理写入请求的Znode
- Follower:Follower从客户端接收写入请求，并将它们转发到Leader Znode
- 请求处理器（request processor）:只存在于Leader节点。它管理来自Follower节点的写入请求
- 原子广播（atomic broadcasts）:负责广播从Leader节点到Follower节点的变化

# Leader选举

- 一个 ZooKeeper 集群同一时刻只会有一个 Leader，其他都是 Follower 或 ObServer
- ZooKeeper 集群的所有机器通过一个 Leader 选举过程来选定一台被称为『Leader』 的机器，Leader服务器为客户端提供读和写服务
- Follower 和 ObServer 都能提供读服务，不能提供写服务。两者唯一的区别在于， ObServer机器不参与 Leader 选举过程，也不参与写操作的『过半写成功』策略，因 此 ObServer 可以在不影响写性能的情况下提升集群的读性能

## ZAB特性

ZAB(ZooKeeper Atomic Broadcast)是为ZooKeeper设计的一种支持崩溃恢复的原子广播协议。

ZAB的协议核心是在整个ZooKeeper集群中只有一个节点即Leader将客户端的写操作转化为事物(或提议proposal)。Leader节点再数据写完之后，将向所有的Follower节点发送数据广播请求(或数据复制)，等待所有的Follower节点反馈。在ZAB协议中，只要超过半数Follower节点反馈OK，Leader节点就会向所有的Follower服务器发送commit消息。即将Leader节点上的数据同步到Follower节点之上。

- 一致性保证
    - 可靠提交(Reliable delivery) -如果一个事务 A 被一个Server提交(committed)了，那么它最终一定会被所有的Server提交
    - 全局有序(Total order) - 假设有A、B两个事务，有一台Server先执行A再执行B，那么可以保证所有Server上A始终都被在B之前执行
    - 因果有序(Causal order) - 如果发送者在事务A提交之后再发送B,那么B必将在A之前执行

- 只要大多数（法定数量）节点启动，系统就行正常运行
- 当节点下线后重启，它必须保证能恢复到当前正在执行的事务

## ZAB的具体实现

- ZooKeeper由Client、Server两部分构成
- Client可以在任何一个Server节点上进行读操作
- Client可以在任何一个Server节点上发起写请求，非Leader节点会把此次写请求转发到Leader节点上。由Leader节点执行
- ZooKeeper使用改编的两阶段提交协议来保证Server节点的事务一致性

## ZXID

![png]({{"/assets/images/my/20190330_4.png"| absolute_url }})

ZooKeeper会为每一个事务生成一个唯一且递增长度为64位的ZXID,ZXID由两部分组成：低32位表示计数器(counter)和高32位的纪元号(epoch)。epoch为当前Leader在成为Leader的时候生成的，且保证会比前一个Leader的epoch大。实际上当新的Leader选举成功后，会拿到当前集群中最大的一个ZXID，并去除这个ZXID的epoch,并将此epoch进行加1操作，作为自己的epoch。

每一个Follower节点都会有一个先进先出（FIFO)的队列用来存放收到的事务请求，保证执行事务的顺序。

总的来说，ZooKeeper的可靠提交由ZAB的事务一致性协议保证,全局有序由TCP协议保证,因果有序由Follower的历史队列(history queue)保证。

## ZAB工作模式
### 广播(broadcast)模式

![png]({{"/assets/images/my/20190330_5.png"| absolute_url }})

![png]({{"/assets/images/my/20190330_6.png"| absolute_url }})

1. Leader从客户端收到一个写请求
2. Leader服务器将客户端的request请求转化为事物proposql提案，并为这个propos生成一个全局唯一的ZXID
3. Leader服务器与每个Follower之间都有一个队列，Leader将消息发送到该队列 
4. Follower节点将收到的事务请求加入到历史队列(history queue)中,并发送ack给ack给Leader
5. 当Leader收到大多数Follower（超过法定数量）的ack消息，Leader会发送commit请求
6. 当Follower收到commit请求时，会判断该事务的ZXID是不是比历史队列中的任何事务的ZXID都小，如果是则提交，如果不是则等待比它更小的事务的commit

### 恢复模式

恢复模式大致可以分为四个阶段：选举，发现，同步，广播

1. 当Leader崩溃后，集群进入选举阶段，开始选举出潜在的新Leader(一般为集群中拥有最大ZXID的节点)，这样做的好处就是可以避免了Leader服务器检查proposal的提交和丢弃工作。
2. 进入发现阶段，Follower与潜在的新Leader进行沟通，如果发现超过法定人数的Follower同意，则潜在的新Leader将epoch加1，进入新的纪元。新的Leader产生
3. 集群间进行数据同步，保证集群中各个节点的事务一致
4. 集群恢复到广播模式，开始接受客户端的写请求

> 当 Leader在commit之后但在发出commit消息之前宕机，即只有老Leader自己commit了，而其它Follower都没有收到commit消息 新的Leader也必须保证这个proposal被提交.(新的Leader会重新发送该proprosal的commit消息)

> 当 Leader产生某个proprosal之后但在发出消息之前宕机，即只有老Leader自己有这个proproal，当老的Leader重启后(此时左右Follower),新的Leader必须保证老的Leader必须丢弃这个proprosal.(新的Leader会通知上线后的老Leader截断其epoch对应的最后一个commit的位置)

在ZooKeeper集群中新的Leader选举成功之后，Leader会将自身的提交的最大proposal的事物ZXID发送给其他的Follower节点。Follower节点会根据Leader的消息进行回退或者是数据同步操作。最终目的要保证集群中所有节点的数据副本保持一致。

>数据同步完之后，ZooKeeper集群如何保证新选举的Leader分配的ZXID是全局唯一呢？

>ZXID是一个长度64位的数字，其中低32位是按照数字递增，即每次客户端发起一个proposal,低32位的数字简单加1。高32位是Leader周期的epoch编号，每当选举出一个新的Leader时，新的Leader就从本地事物日志中取出ZXID,然后解析出高32位的epoch编号，进行加1，再将低32位的全部设置为0。这样就保证了每次新选举的Leader后，保证了ZXID的唯一性而且是保证递增的。 

![png]({{"/assets/images/my/20190330_7.png"| absolute_url }})

参考
============

[ZooKeeper教程](https://www.w3cschool.cn/ZooKeeper/ZooKeeper_overview.html)

[Architecture of ZAB](https://distributedalgorithm.wordpress.com/2015/06/20/architecture-of-zab-ZooKeeper-atomic-broadcast-protocol/)

版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https://xueyp.github.io/)

