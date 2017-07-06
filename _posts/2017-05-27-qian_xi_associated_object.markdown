---
layout: post
title: "浅析Associated Object"
date: 2017-05-27 10:10:00
categories: ios
author: neilliang
tags: Associat...
---

* content
{:toc}



Category是Objective
C为程序员提供的一个强大的动态机制，它们允许程序员为已有的对象添加新的方法，即便是在没有该对象的源代码的情况下。通过它可以很方便的为已有的类来添加函数。但是Category不允许为已有的类添加新的属性或者成员变量。

<!--more-->
通过运行时的数据结构我们可以看到，objc_class结构体中维护着objc_ivar_list的指针，这个指针指向的是类中定义的实例变量的列表。  
![](/image/qian_xi_associated_object/0a675e25ebe30d1726eeda81891321a0a75c4b9fcbf9b97548bca101646dbc9b)

再看看`objc_category`的结构体中，只有类别名，类名，实例方法，类方法和遵循的协议表，由此可以看出category类中是不能够添加成员变量的。  
![](/image/qian_xi_associated_object/daa53763fbef4e9bebc7e6551e9b65239e4466a91fdcc159e3edb67931055123)

可以发现，苹果的category设计明显是不允许在category中添加新的成员变量。但是在项目中，这明显不能满足我们的需求，不过值得庆幸的是，我们可以通过Associated
Objects来弥补这一不足。

## Associated Objects 介绍

与 Associated Objects 相关的函数主要有三个，我们可以在 runtime.h 文件中找到它们的声明：

![](/image/qian_xi_associated_object/f4a65711bcc394116f1870e352e16f93dc9727545db1e7df8cd49e50ed181a12)

    
    
    1. void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)
    2. id objc_getAssociatedObject(id object, const void *key)
    3. void objc_removeAssociatedObjects(id object)
    

`Object`：传入关联对象的所属对象，也就是增加成员的实例对象，一般来说传入self。  
`key`：一个唯一标记。在官方文档中推荐使用static
char，当然更推荐是指针。为了便捷，一般使用selector，这样在后面getter中，我们就可以利用_cmd来方便的取出selector。  
`value`：传入关联对象。  
`policy`：objc_AssociationPolicy是一个ObjC枚举类型，也代表关联策略。

## Associated Objects 源码浅析

那究竟关联对象是如何存储的呢？透过源码，我们看到关联对象是通过一个叫做`AssociationsManager`的对象来进行管理的。  
![](/image/qian_xi_associated_object/4a665f77259c67de69f3d02883fef577dc4343e5e4bc1d246f0f6fff7b0b6445)

在AssociationsManager中，有一个`spinlock_t`锁和一个`AssociationsHashMap`的哈希表。

![](/image/qian_xi_associated_object/c855ee4f73bc0ef3c797fa95868c1f4b05567d1e0e98419ee3adf775d74921ae)

然后再看`objc_setAssociatedObject`的源码，我们可以看懂啊`AssociationsHashMap`中的键为`disguised_ptr_t`，在得到这个指针的时候，源码中执行了`DISGUISE`方法，通过这个方法能够获得指向self地址的指针，即为指向对象地址的指针。然后其对应的value，便是一个存放关联对象的子哈希表。

