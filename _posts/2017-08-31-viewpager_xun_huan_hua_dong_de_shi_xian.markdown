---
layout: post
title: "Viewpager循环滑动的实现"
date: 2017-08-31 20:22:00 +0800
categories: android
author: arendgxma
tags: adapter ViewPager 循环
---

* content
{:toc}

| 导语 本文讲述实现ViewPager循环滑动效果的两种方案：

### **方案1：**

复写ViewPager或者Adapter，扩展dataList，左右各加1。
<!--more-->

核心思路就是将数据集的左右两侧加一条数据，分别是原来数据集的最后一条和第一条，在用户滑动到边界页面时自动跳转页面。

比如本来的页面有5页，对应5条数据，如下图：

![](/image/viewpager_xun_huan_hua_dong_de_shi_xian/be51b32da00c7c35b3df8c4145dee64511e5cac74417bbce14c8f9ec37cbbab2)

经过扩展后，数据集元素数量+2，变成

![](/image/viewpager_xun_huan_hua_dong_de_shi_xian/aa66c5183bfbcb6158ba2030f48d28c3e15175b659aab37f8e89e390bc9a11e0)

这个时候postion为1的数据成为实际上的第一个页面。展示的内容为a。

在postion为1的时候左滑，会跳转到展示内容为e的页面，当然这次跳转过程对用户是无感知的。

例：

if(curPos == 0){

      setCurrentItem(5, false) ;// false表示无动画

}

![](/image/viewpager_xun_huan_hua_dong_de_shi_xian/8a9b921a5437786f8f777dd37862fdcaf305830f231b8b5ce7cd5593ad93555d)

要做的工作：

•1.扩展list，getCount()==list.size()+2;

•2.当index为0时，自动设置index为list.size().

•3.当index为list.size()+1时，自动设置index为1.

•4.防止setCurrentItem时发生页面跳变，需要维护第一个页面和最后一个页面内容的缓存。即a 和 e的缓存.

•5.考虑刚好有2个数据的情况，重写getItemPostion方法：

因为b元素在viewPager的位置有两个，0和2，同理a也是。

当前页面为b页时，左右两页都是a，返回的postion都是1，在viewPager的排序过程中会把两个a页面都移动到b的左边，导致滑动异常。

例：在位置1上的view a，和位置3上的view a 都返回同一个position 1.

notifyDatasetChange之前：

![](/image/viewpager_xun_huan_hua_dong_de_shi_xian/f6a35aa6a41bf8b538bfa94f8b5245c1840b21c3c07552a1c53812ce02f5f794)

notifyDatasetChange中排序后：

![](/image/viewpager_xun_huan_hua_dong_de_shi_xian/b25122bd92f86ef2f20ea073c3e558ee222ca311eb671d1c07eaa6031fddf4dc)

关键在于list的数量是否一定大于2.

### **方案2：**

使viewPager得到的size非常长，长到一般用户无法触及边界，再用循环的数据集填满它，取中间的位置作为用户看到的起始页面。

![](/image/viewpager_xun_huan_hua_dong_de_shi_xian/52657f713263b501fdb52e8fccefcedd5ccde8ae79b47b5db2cbe2f1a4e9490f)

zzZ 就是这么任性。。

要做的工作：

•复写Adapter的getCount方法，返回一个较大的值，如data.size()*100。  

•复写instantiateItem()方法，用postion%dataSize的方式为viewPager返回一个正确位置上的view。  

•初始化后执行mViewPager.setCurrentItem(data.size()*50);

例：

@Override

public int getCount() {

      return mDatas.size() * 100; // 总量的100倍

}

public int getActualPosition(int pagerPosition) {

            final int size = mDatas.size();

            return pagerPosition % size;

}

•性能上的考虑：

这种方法要求在第一次加载的时候执行setCurrentItem();

调用此方法，ViewPager中会依次执行addNewItem，最后走到Adapter的instantiateItem方法。

setCurrentItem(101); 会走100+次instantiateItem();

![](/image/viewpager_xun_huan_hua_dong_de_shi_xian/b810a4b5f0018207f352562c9f956ebb4d1b6297041f9ea6b75dd3c0a2831cdb)

实现上，为了保证instantiateItem方法的效率，缓存是必须的，绝对不能每次instantiateItem的时候都重新inflate一个view。

