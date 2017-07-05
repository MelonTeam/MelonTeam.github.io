---
layout: post
title: "不该缺少的error体系"
date: 2017-05-27 15:25:00
categories: ios
author: kylewu
tags: nserror
---

* content
{:toc}

| 导语
几乎所有app在开发过程中都会遇到错误，一些错误是在控制之外，例如磁盘空间不足或网络连接失败。而一些错误是可以预料得到的，例如视频正在处理中无法播放、传入的参数非法等。而这些错误的信息如果友好的告诉业务方或者用户呢？

## 前言

<!--more-->
几乎所有app在开发过程中都会遇到错误，一些错误是在控制之外，例如磁盘空间不足或网络连接失败。而一些错误是可以预料得到的，例如视频正在处理中无法播放、传入的参数非法等。而这些错误的信息如果友好的告诉业务方或者用户呢？

在ios开发中最常见的方式之一是使用`nserror`，比如使用很广的`afnetworking`，它就会常常返回一些错误信息告诉用户。而在手q或者兴趣部落的项目中都没有一套整齐的`error`体系，所以我们得需要进一步了解`nserror`是什么东西才能制定出我们想要的东西。

## nserror包括什么

在整个error体系中主要包括三块内容，如下：

  * error domain
  * error code
  * the user info dictionary

### domain

error domain是指区域，它是由一个字符串组成的。比如os
x系统`carbon`框架的`domain`为`（nsosstatuserrordomain）`，`posix`框架为`（nsposixerrordomain）`，除此之外不同的`framework`也定义了自己的domain，比如对于`web
kit framework`，定义了`webkiterrordomain`。

而我们也应该在自己的项目中定义属于自己error区域，官方推荐的命名规则如下：  
com.company.xxx.errordomain

### code

而`code`就是我们俗称的错误码了，比如访问文件资源时返回的`nsfilenosuchfileerror（4）`等的错误码。  
oc开发时使用到的系统库对应的各个`error code`可以到相应的地方查，他们所在的位置都有一个相应规范：

  * foundation/foundationerrors.h - generic foundation error codes
  * coredata/coredataerrors.h - core data error codes
  * foundation/nsurlerror.h - url error codes

那么在自己的项目中也应该按照这样的规范来定义：xxxerrors.h

### user info dictionary

user info可以包含很多自定义信息，系统给定义好了一些键名：

键名作用 | 键名定义 | 获取值方法  
---|---|---  
通用键 | nsunderlyingerrorkey |  
详细描述键 | nslocalizeddescriptionkey | \- (nsstring *)localizeddescription;  
失败原因键 | nslocalizedfailurereasonerrorkey | \- (nsstring
*)localizedfailurereason;  
恢复建议键 | nslocalizedrecoverysuggestionerrorkey | \- (nsstring
*)localizedrecoverysuggestion;  
恢复选项键 | nslocalizedrecoveryoptionserrorkey | \- (nsarray
*)localizedrecoveryoptions;  
其他键 | nsrecoveryattemptererrorkey |  
其他键 | nshelpanchorerrorkey |  
其他键 | nsstringencodingerrorkey |  
其他键 | nsurlerrorkey |  
其他键 | nsfilepatherrorkey |  
  
基础用法：

    
    
    nsdictionary *userinfo ＝ [nsdictionary dictionarywithobjectsandkeys:@"这是错误详细的描述信息", nslocalizeddescriptionkey, error, nsunderlyingerrorkey, nil]];
    

nserror主要的初始化方法：

    
    
    - (id)initwithdomain:(nsstring *)domain code:(nsinteger)code userinfo:(nsdictionary *)dict;
    + (id)errorwithdomain:(nsstring *)domain code:(nsinteger)code userinfo:(nsdictionary *)dict;
    

## 总结

在了解到nserror的强大之后，我们的项目也应该有一套error体系，为了能在开发期就能定位问题，那么在项目中就需要做到以下几点：

  1. 建立属于项目的错误码表 `xxxerrors.h`
  2. 定义属于项目的错误区域 `com.company.xxx.errordomain`
  3. 在一些数据接口或者更底层的一些接口都应该提供`nserror`的结果返回参数，以便业务层能更快定位问题

