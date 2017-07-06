---
layout: post
title: "重磅整理---Android进程保活组件"
date: 2017-05-05 21:36:00
categories: android
author: henrikwu
tags: 进程保活 Android
---

* content
{:toc}

| 导语 Android进程保活的文章很多，但是基本没有一个完整的工程化的东西。所以在这里整理主流的保活方案，将其工程化到github上供大家直接使用。

github地址： <https://github.com/stephen8341/KeepProcLive>

这里面集成的方案包括：
<!--more-->

1\.  Service指定为START_STICKY 被系统回收的进程会被系统重新拉起

2\.  Service设置为前台进程 将后台进程设置为前台进程，提高进程优先级

![](/image/zhong_bang_zheng_li__android_jin_cheng_bao_huo_zu_jian/17035b806bd0b12889624d692c4215756b8b697de87ea9af0deb916c80db5290)

3\.  1像素Activity方案 关屏后加载1个像素的Activity到Window，提高锁屏 后的进程优先级

4\.  静态广播自启 利用监听开机启动广播、网络变化广播、应用安装删 除等广播，接收到广播后实现自启

5\.  JobSchedule (5.0以上)和AlarmManager 利用Android的API某些机制去实现自启

6\.   账号同步拉活 利用Android自身的账号同步机制周期拉活

7\.   守护进程 :
这块为了解决5.0以上系统强杀的时候会连同同group中的所有进程也一起干掉，采用了两个独立的Java守护进程同时在c层用文件锁监听进程死亡的机制，具体参考：<http://blog.csdn.net/marswin89/article/details/50916631>

