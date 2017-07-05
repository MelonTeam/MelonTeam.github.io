---
layout: post
title: "fresco 4.x和5.x内存分析"
date: 2017-06-30 20:36:00
categories: android
author: siriushe
tags: fresco
---

* content
{:toc}



两年前部落项目接入fresco的时候，那时候主流机型还是4.x。fresco在4.x的机器的内存性能很好，bitmap存在ashmem（匿名共享内存）层里面的，对应用的内存缓存的压力不大。

## 4.x系统的fresco
<!--more-->

![](/image/fresco_4_x_he_5_x_nei_cun_fen_xi/a4d7236838155ee5bbca33914aa21364c5b4e8a743c3452c791bde4c914b750b)

安卓系统的ashmem层这里不做过多介绍，我们来看下缓存到ashmem最后一个java函数。通过注释发现，只有purgeable
bitmap才能生效，我们来看下purgeable bitmap究竟是什么。

![](/image/fresco_4_x_he_5_x_nei_cun_fen_xi/6f0d5100aaef5bc5de643e60e6c07598eb2d92d567a4345306213cd203fbbf1f)

inpurgeable这个属性标识这个bitmap是否是可清除的，设置为true之后，该系统会自动把bitmap存储在ashmem中，
当系统存储不足的时候会被回收，等到需要的时候，会在主线程重新进行解码，然而这种解码是会造成主线程卡顿的。

为了解决这种卡顿，fresco调用androidbitmap_lockpixels这个native方法锁住这块内存，锁住这块内存之后gc便不会对该内存生效，因此就不会有在主线程重编码的卡顿问题了。fresco需要自己进行这块内存的管理。fresco里面只使用了pin方法，unpin操作通过bitmap的recycle的操作来完成，如果bitmap最后没有释放，那么会造成内存泄漏，影响系统的运行状况。所幸的是，fresco的引用计数方式已经很完善，并且当simpledraweeview
ondetachwindow的时候也会做释放操作，在这种情况下内存交给fresco还是挺令人放心的。

## 5.x以上系统的fresco

然而purgeable
bitmap引起主线程卡顿的这一缺陷最终使得谷歌在5.0以上的系统废弃了它，所以fresco在5.0以上系统再也没法使用ashmem层了，bitmap的内存压力重新回到了java
heap中。随着主流操作系统逐渐趋向于5.0，6.0，fresco导致的oom问题也趋于严重。

经过对fresco内存缓存系统的分析，我们可以看到countingmemorycache这个内存缓存类里面实际上是包含两块内存区域的。

![](/image/fresco_4_x_he_5_x_nei_cun_fen_xi/5bde7de985f03b908ac501b757df049df78f76063dd1e464475cea64782351df)

mexclusiveentries和mcacheentries都是基础lru策略进行存储管理，mexclusiveentries这块存储是用来缓存没有被使用等待回收的bitmap内存的，也就是说，如果一个bitmap的引用计数为0，他会进入到mexclusiveentries中，被mexclusiveentries
lru淘汰的bitmap才会被真正的释放。

![](/image/fresco_4_x_he_5_x_nei_cun_fen_xi/9c423d4793f93ede2186fb9196972426279cbe746f9b214c0b91dcb9316c70fb)

然而，坑爹的是，默认配置中对这块缓存的大小和数量限制简直可以说是没有，之前代码内限制都是integer.max_value，在defaultbitmapmemorycacheparamssupplier这个类里面对这块内存的配置项进行限制，对5.0以上fresco的内存优化效果巨大，目前我这里的限制是（150，17m），mcacheentries还是保持原配置，这里需要结合具体业务进行设置。

