---
layout: post
title: "Android动态权限"
date: 2017-08-31 21:50:00 +0800
categories: android
author: zijianlu
tags: Android 动态权限
---

* content
{:toc}

| 导语 随机聊需求中出现几个涉及权限的bug，所以对动态权限机制做了一个简单的整理。

## 概述

Android应用程序通过请求权限来访问设备数据，例如联系人，短信，SD卡，相机，蓝牙等。应用所需的权限需要在manifest文件中声明，在安装的时候由用户授予。
<!--more-->
app安装后就获得了这些权限。运行时不再需要询问用户。

从Android 6.0(Api level
23)开始，引入了动态权限的机制，对权限进行了分类，根据权限的级别，危险权限不再是安装后自动授予，而是需要运行时由用户授予。
这种机制更好的保护了用户的隐私安全，但也给开发人员带来了额外的适配工作，旧版本正常运行的app到6.0以上机器可能会发生crash。

动态权限机制生效需要满足两个条件：

  * **manifest 文件中的 targetSdkVersion >= 23**
  * **运行的手机系统版本 >= 6.0**

## 权限分类

（1）正常权限:

对用户隐私影响比较小的权限。**这些权限在应用安装时授予，运行时不再询问用户**。例如: 网络访问、WIFI状态、音量设置等。

（2）危险权限:

涉及用户敏感数据的权限。例如:
读取通讯录、读写存储器数据、获取用户位置等。如果需要使用这些危险权限，首先必须在配置文件中声明，同时在运行时检查是否拥有权限，如果没有需要请求用户授予。

### 权限组

Android系统对所有权限进行了分组，称为权限组 。属于同一组的危险权限将自动合并授予，用户授予应用某个危险权限，则应用将获得该权限组下的所有权限。

下表为危险权限及其分组：

![](/image/android_dong_tai_quan_xian/853af11e9156fb73cbbbccf4b5f6215a8f0736ee9593c1a3ece346a28fbaa6d8)

## 动态申请权限

### 1\. 检查权限

`public int checkSelfPermission(String permission);`

检查当前app是否拥有某权限。

  * 有权限: PackageManager.PERMISSION_GRANTED
  * 无权限: PackageManager.PERMISSION_DENIED

当应用需要用到某危险权限时，在执行权限相关代码前，需要使用该方法判断是否已经拥有该权限。有权限继续执行需要权限的代码；无权限则向用户请求授予权限。

### 2\. 申请权限

`void requestPermissions (Activity activity, String[] permissions, int
requestCode)；`

当检测到应用没有指定的权限时，调用本方法向用户请求权限。调用此方法将弹出权限请求对话框询问用户 “允许” 或 “拒绝” 指定的权限。

  * 权限参数传入的可以是数组，调用该方法一次请求多个权限；
  * 传入的权限数组参数以单个具体权限为单位，但弹框询问用户授权时，属于同一权限组的权限将自动合并询问授权一次；
  * 请求的权限必须事先在 AndroidManifest.xml 中有声明，否则调用此方法请求时，将不弹框，而是直接返回“拒绝”的结果；
  * 第一次请求权限时，用户点击了“拒绝”，第二次再请求该权限时，对话框将出现“不再询问”复选框，如果用户勾选了“不再询问”并点击了“拒绝”，则之后再请求此权限组时将不弹框，而是直接返回“拒绝”的结果。

### 3\. 处理权限请求的响应

调用requestPermissions请求权限后，在下面的回调中获取用户的选择结果。

`public void onRequestPermissionsResult(int requestCode, String[] permissions,
int[] grantResults)；`

  * requestCode请求权限时传入的请求码，用于区别是哪一次请求的
  * permissions 所请求的所有权限的数组
  * grantResults 权限授予结果，和 permissions 数组参数中的权限对应， 值有两种:
    1. 授予: PackageManager.PERMISSION_GRANTED
    2. 拒绝: PackageManager.PERMISSION_DENIED

### 4\. 提示用户授予权限的理由

`boolean shouldShowRequestPermissionRationale (Activity activity, String
permission)`

判断是否有必要向用户解释为什么要这项权限。如果应用第一次请求过此权限，但是被用户拒绝了，则之后调用该方法将返回
true，此时就有必要向用户详细说明需要此权限的原因。

  * 如果应用第一次请求此权限时被用户拒绝，第二次再请求此权限时，用户勾选了权限请求对话框的“不再询问”，则此方法返回 false。
  * 如果设备规范禁止应用拥有该权限，此方法也返回 false。

## 版本兼容

由于以上几个方法都是在 Api level 23中才引入，如果需要运行在低版本中，需要做版本兼容。 support 包中有对应的兼容方法：

`ContextCompat.checkSelfPermission()`  
`ActivityCompat.requestPermissions()`  
`ActivityCompat.shouldShowRequestPermissionRationale()`

## 例子

这几个方法的使用比较简单，例子略，现在手Q android版的 targetSdkVersion="9"  
暂时还不涉及适配的工作。

