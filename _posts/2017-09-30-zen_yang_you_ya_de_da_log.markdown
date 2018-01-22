---
layout: post
title: "怎样优雅的打log"
date: 2017-09-30 20:46:00 +0800
categories: ios
author: peterlmeng
tags: log 日志
---

* content
{:toc}



一、背景

随着app业务场景越来越多，场景越来越复杂，log在我们开发定位问题显得越来越重要了。而大部分同学可能对log打印比较茫然，感觉打log无从下手。打多了影响性能，打少了又定位不到问题，显得有些尴尬。
<!--more-->

二、手Q中log

在手Q中，log一般分为

  * QLog_Event，记录MSF、大数据通道等基本框架的关键Log输出，以及各个业务关键路径和异常逻辑等，在发布版本中输出log
  * QLog_InfoP，在发布版本可能需要定位问题的一些关键路径信息，在发布版本默认不输出，通过染色号码可以输出该log
  * QLog_Info，记录各个业务逻辑更详细的信息，在发布版本中不能输出
  * QLog_Debug，用于一些临时性定位问题等，在发布前进行删除清理

我们常用的log，一般有event级别log和infoP级别的log。event用于打印关键信息，这种级别的log需要慎重使用，因为所有用户都会输出这种log。

三、推荐打log的地方

  * 初始化

![](/image/zen_yang_you_ya_de_da_log/f8f4102b032fe15cc75df9924dea83262072597b2c32af85e7ee00499abe0961)

初始化场景是一个很普遍的场景。简单的初始化场景其实没有必要打log。但是像上面这种很多场景的初始化逻辑，建议重要分支用infoP级别log。

  * 网络

网络场景是一个很常见的场景。我们大部分log都在定位网络波动与网络异常。所以在网络判断，网络回包，网络异常等情况，都建议打infoP级别log。

  * 异常（异常return或else）

![](/image/zen_yang_you_ya_de_da_log/abf36e8366fea78b8bebeb2870f7090832f39d3341af98843dbc023e95619c04)

![](/image/zen_yang_you_ya_de_da_log/f7399f55b8e1b4b166e5feed6c8751793d383814795b2e8663fe57a9d96450a0)

在我们的很多逻辑判断中，有很多异常情况，当一些异常的逻辑（异常的返回，或者异常的else）出现的时候，可能会出现bug。推荐在一些严重的异常分支前，打上event
log。

  * 通知，代理

通知和代理一般分为两种情况，一种是系统的通知和代理。这种通知和代理一般出错的可能性不太大，所以不推荐打log。而另一种就是使用别人的通知和代理。这种情况下推荐在重要地方打上infoP
log。

  * IO操作

IO操作是一个比较常见的操作。但是IO操作有一个特点，就是出了问题，一般不太好复现，也不太好定位。所以这种IO操作异常，一般推荐打event log。

四、推荐工具

  * TextAnalysisTool（https://textanalysistool.github.io/）

![](/image/zen_yang_you_ya_de_da_log/81ff04e2182552d5d9b9b6af446e373d1bd46d57fe51865001f5cc86f1d68d2d)

1.支持大文件，文件打开速度快。

2.支持文本高亮，支持多关键字不同高亮颜色。

3.支持文本过滤，支持过滤文本导入（可团队维护同一份）。

