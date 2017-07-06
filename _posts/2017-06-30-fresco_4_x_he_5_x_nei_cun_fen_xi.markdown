---
layout: post
title: "Fresco 4.X和5.X内存分析"
date: 2017-06-30 20:36:00
categories: android
author: siriushe
tags: fresco
---

* content
{:toc}



两年前部落项目接入Fresco的时候，那时候主流机型还是4.X。Fresco在4.X的机器的内存性能很好，Bitmap存在Ashmem（匿名共享内存）层里面的，对应用的内存缓存的压力不大。

## 4.X系统的Fresco
<!--more-->

![](/image/Fresco_4_X_he_5_X_nei_cun_fen_xi/a4d7236838155ee5bbca33914aa21364c5b4e8a743c3452c791bde4c914b750b)

安卓系统的Ashmem层这里不做过多介绍，我们来看下缓存到Ashmem最后一个JAVA函数。通过注释发现，只有purgeable
bitmap才能生效，我们来看下purgeable bitmap究竟是什么。

![](/image/Fresco_4_X_he_5_X_nei_cun_fen_xi/6f0d5100aaef5bc5de643e60e6c07598eb2d92d567a4345306213cd203fbbf1f)

inPurgeable这个属性标识这个Bitmap是否是可清除的，设置为true之后，该系统会自动把Bitmap存储在Ashmem中，
当系统存储不足的时候会被回收，等到需要的时候，会在主线程重新进行解码，然而这种解码是会造成主线程卡顿的。

为了解决这种卡顿，Fresco调用AndroidBitmap_lockPixels这个native方法锁住这块内存，锁住这块内存之后GC便不会对该内存生效，因此就不会有在主线程重编码的卡顿问题了。Fresco需要自己进行这块内存的管理。Fresco里面只使用了pin方法，unpin操作通过Bitmap的recycle的操作来完成，如果Bitmap最后没有释放，那么会造成内存泄漏，影响系统的运行状况。所幸的是，Fresco的引用计数方式已经很完善，并且当SimpleDraweeView
onDetachWindow的时候也会做释放操作，在这种情况下内存交给Fresco还是挺令人放心的。

## 5.X以上系统的Fresco

然而purgeable
bitmap引起主线程卡顿的这一缺陷最终使得谷歌在5.0以上的系统废弃了它，所以Fresco在5.0以上系统再也没法使用Ashmem层了，Bitmap的内存压力重新回到了Java
Heap中。随着主流操作系统逐渐趋向于5.0，6.0，Fresco导致的OOM问题也趋于严重。

经过对Fresco内存缓存系统的分析，我们可以看到CountingMemoryCache这个内存缓存类里面实际上是包含两块内存区域的。

![](/image/Fresco_4_X_he_5_X_nei_cun_fen_xi/5bde7de985f03b908ac501b757df049df78f76063dd1e464475cea64782351df)

mExclusiveEntries和mCacheEntries都是基础Lru策略进行存储管理，mExclusiveEntries这块存储是用来缓存没有被使用等待回收的Bitmap内存的，也就是说，如果一个Bitmap的引用计数为0，他会进入到mExclusiveEntries中，被mExclusiveEntries
lru淘汰的Bitmap才会被真正的释放。

![](/image/Fresco_4_X_he_5_X_nei_cun_fen_xi/9c423d4793f93ede2186fb9196972426279cbe746f9b214c0b91dcb9316c70fb)

然而，坑爹的是，默认配置中对这块缓存的大小和数量限制简直可以说是没有，之前代码内限制都是Integer.MAX_VALUE，在DefaultBitmapMemoryCacheParamsSupplier这个类里面对这块内存的配置项进行限制，对5.0以上Fresco的内存优化效果巨大，目前我这里的限制是（150，17M），mCacheEntries还是保持原配置，这里需要结合具体业务进行设置。

