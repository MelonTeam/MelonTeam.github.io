---
layout: post
title: "iOS推送调试工具Easy APNs Provider的使用"
date: 2017-07-31 21:05:00 +0800
categories: ios
author: rucasli
tags: iOS 推送
---

* content
{:toc}



### 一·背景

>
<!--more-->
之前接到远程推送需要显示图片的需求，在调试的时候使用公司提供的WNS带的push调试工具发现对环境和设备都有要求，开发调试&测试都比较困难，比如需要找越狱的机子安装发布证书打包的安装包，在WNS
push测试的时候还需要配置appid和uin等信息。相对于WNS Push测试的限制，Easy APNs Provider是一个很好的调试工具。

### 二·准备工作

1·Easy APNs Provider可以在AppStore上面下载[下载戳这里~](https://itunes.apple.com/cn/app
/easy-apns-provider/id989622350?mt=1)。

2·修改工程的BundleID，同时登陆[Apple
Developer](http://developer.apple.com)导出推送证书(开发或正式证书都可以)，这里工程更换证书&绑定开发设备&导出证书等步骤就不再赘述。

3·将开发设备网络切换到GuestWiFi，因为开发网无法连接到苹果服务器进行身份验证。

### 三·开始调试

Easy APNs Provider调试主要有5个步骤：

![EAP的主界面](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/9e57e0cecbdecfdd1c4abe040d70ca05f37b87b3e29a9071471d1f6f27de331a)  

[ EAP的主界面 ]

##### 1·添加token：

![三种方式](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/2491228a5ce253f844f9f286e279a213d1e13f8b880def715c4a25ed055d9504)  

[ 三种方式 ]

  
添加token有三种方式，特别注意一下几点：  
1、不要token两端的尖括号  
2、空格删完之后再添加，那个框框只能放64个字符,多的会自动除  
3、一定要为每个token添加名字，

##### 2·选择证书文件：

在开发者网站导出的push证书有dubug和release两种，注意区分。

##### 3·连接至苹果推送服务器：

![选择验证服务器](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/af3eeb4fe937d32e70bd24a814993b685be64a99f0ae57cd2cacb64f4a850a31)  

[ 选择验证服务器 ]

debug类型的证书选择.sandbox.  
release类型证书选择.push.  
选择完类型，点击”连接至：”  

![log输出](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/9bbbfe94ad3f47965d9f6f3c0e6da1a3d6faa6170943a7c533c26d4413933b3b)  

[ log输出 ]

  
这样就可以继续构造自己要推送的消息体了。这里之前踩过一个坑，在开发网的环境下，一直提示失败，以为是证书的问题，最后发现是自己被墙了。

##### 4·推送负载：

![便利构造](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/cc5bd55d39f5452af94b5e5248b7d78bac273c95b481f8288d10c561fab37e59)  

[ 便利构造 ]

  

![原始负载](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/306059c0764b5af2ba9eb3f35b24f3ea481f86178fb414afe26202c966608847)  

[ 原始负载 ]

##### 5·发送推送：

最后就可以推送消息了。  

![状态](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/0a7e28202761d5d3f898a8042f8fa14b390336051792074d829cd2d4f0f50f4c)  

[ 状态 ]

  
效果：  

![效果](/image/ios_tui_song_diao_shi_gong_ju_easy_apns_provider_de_shi_yong/57f6f5ec06b4c2d17267d8a3a222fcbc63a1894fcb0a72366805800d77f319a3)  

[ 效果 ]

### 四·总结&延展

WNS推送调试的方式对测试和开发的限制都比较大，单单一个越狱机器就挺难找的了，所以Easy APNs
Provider简单方便。之前也使用过PushMeBaby等调试工具，感觉还是EAP好用，值得推荐。

在做这个需求的时候，使用了iOS10推送相关的新框架UserNotificationKit，苹果将本地推送和远程推送进行了整合与重构。这是推送相关的一个全新的框架，全新的使用方式，遂将Notification相关重温了一次又学习了UN框架的使用，这里推荐一个学习UN框架很好的文章：[UN学习传送门](https://onevcat.com/2016/08/notification/)。

