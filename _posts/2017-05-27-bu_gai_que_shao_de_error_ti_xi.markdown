---
layout: post
title: "不该缺少的Error体系"
date: 2017-05-27 15:25:00 +0800
categories: ios
author: kylewu
tags: NSError
---

* content
{:toc}

| 导语
几乎所有APP在开发过程中都会遇到错误，一些错误是在控制之外，例如磁盘空间不足或网络连接失败。而一些错误是可以预料得到的，例如视频正在处理中无法播放、传入的参数非法等。而这些错误的信息如果友好的告诉业务方或者用户呢？

## 前言

<!--more-->
几乎所有APP在开发过程中都会遇到错误，一些错误是在控制之外，例如磁盘空间不足或网络连接失败。而一些错误是可以预料得到的，例如视频正在处理中无法播放、传入的参数非法等。而这些错误的信息如果友好的告诉业务方或者用户呢？

在iOS开发中最常见的方式之一是使用`NSError`，比如使用很广的`AFNetworking`，它就会常常返回一些错误信息告诉用户。而在手Q或者兴趣部落的项目中都没有一套整齐的`Error`体系，所以我们得需要进一步了解`NSerror`是什么东西才能制定出我们想要的东西。

## NSError包括什么

在整个Error体系中主要包括三块内容，如下：

  * Error Domain
  * Error Code
  * The User Info Dictionary

### Domain

Error Domain是指区域，它是由一个字符串组成的。比如OS
X系统`Carbon`框架的`domain`为`（NSOSStatusErrorDomain）`，`POSIX`框架为`（NSPOSIXErrorDomain）`，除此之外不同的`framework`也定义了自己的domain，比如对于`Web
Kit framework`，定义了`WebKitErrorDomain`。

而我们也应该在自己的项目中定义属于自己Error区域，官方推荐的命名规则如下：  
com.company.XXX.ErrorDomain

### Code

而`code`就是我们俗称的错误码了，比如访问文件资源时返回的`NSFileNoSuchFileError（4）`等的错误码。  
oc开发时使用到的系统库对应的各个`error code`可以到相应的地方查，他们所在的位置都有一个相应规范：

  * Foundation/FoundationErrors.h - Generic Foundation error codes
  * CoreData/CoreDataErrors.h - Core Data error codes
  * Foundation/NSURLError.h - URL error codes

那么在自己的项目中也应该按照这样的规范来定义：XXXErrors.h

### User Info Dictionary

User info可以包含很多自定义信息，系统给定义好了一些键名：

键名作用 | 键名定义 | 获取值方法  
---|---|---  
通用键 | NSUnderlyingErrorKey |  
详细描述键 | NSLocalizedDescriptionKey | \- (NSString *)localizedDescription;  
失败原因键 | NSLocalizedFailureReasonErrorKey | \- (NSString
*)localizedFailureReason;  
恢复建议键 | NSLocalizedRecoverySuggestionErrorKey | \- (NSString
*)localizedRecoverySuggestion;  
恢复选项键 | NSLocalizedRecoveryOptionsErrorKey | \- (NSArray
*)localizedRecoveryOptions;  
其他键 | NSRecoveryAttempterErrorKey |  
其他键 | NSHelpAnchorErrorKey |  
其他键 | NSStringEncodingErrorKey |  
其他键 | NSURLErrorKey |  
其他键 | NSFilePathErrorKey |  
  
基础用法：

    
    
    NSDictionary *userInfo ＝ [NSDictionary dictionaryWithObjectsAndKeys:@"这是错误详细的描述信息", NSLocalizedDescriptionKey, error, NSUnderlyingErrorKey, nil]];
    

NSError主要的初始化方法：

    
    
    - (id)initWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict;
    + (id)errorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict;
    

## 总结

在了解到NSError的强大之后，我们的项目也应该有一套Error体系，为了能在开发期就能定位问题，那么在项目中就需要做到以下几点：

  1. 建立属于项目的错误码表 `XXXErrors.h`
  2. 定义属于项目的错误区域 `com.company.XXX.ErrorDomain`
  3. 在一些数据接口或者更底层的一些接口都应该提供`NSError`的结果返回参数，以便业务层能更快定位问题

