---
layout: post
title: "易踩的坑：32&64bit架构下BOOL类型不同"
date: 2017-09-29 17:13:00 +0800
categories: ios
author: dalei
tags: 32bit 64bit BOOL
---

* content
{:toc}



**起因**

之前接到一个关于某UI控件在部分机型上无法正常显示的bug单，定位至此：
<!--more-->

![](/image/yi_cai_de_keng_32_64bit_jia_gou_xia_bool_lei_xing_bu_tong/238a73d60e869be02f1d0731bdb14df39d3fe854f948726914eab9d0545c1e6a)



发现是由于这行语句在部分机型上无法将UI控件的hidden属性置为NO。

此外，控件在iphone5上不可见，在iphone5s及以上机型中均可正常显示。



**思路**

首先，iPhone 5是32位架构，苹果从iPhone 5s开始对全线移动产品使用64位架构。

其次，performSelector: withObject:要求所传参数为对象。

因此初步判断，这是在32、64位操作系统中，NSNumber与BOOL类型之间转换结果不同导致的。



**验证**

验证结果的确如此。

在iphone5s（64位架构）上，将由NO初始而来的NSNumber赋予BOOL变量，得到的仍为NO：

![](/image/yi_cai_de_keng_32_64bit_jia_gou_xia_bool_lei_xing_bu_tong/bef790253f37a5b2c9f26d68e85c183a3dda18458630e91b7867ecb7fbd45b4c)



但在iphone5（32位架构）上，结果却既非YES也非NO

![](/image/yi_cai_de_keng_32_64bit_jia_gou_xia_bool_lei_xing_bu_tong/9d9e985a670f277aac759d0a4a3a357c57270203f4c3b4ff5f28cb5e32247b8a)



**探寻**

究其原因，32-bit下，@encode(BOOL)返回’c’

![](/image/yi_cai_de_keng_32_64bit_jia_gou_xia_bool_lei_xing_bu_tong/a3bd9880512cbb2962237d073a4ceaa351e6cb94d303ae09b93c040c6ed14a42)



而在64-bit下，@encode(BOOL)返回’B’

![](/image/yi_cai_de_keng_32_64bit_jia_gou_xia_bool_lei_xing_bu_tong/37c03c2ca00e0db1aa6df0f5cbc750aabddfba6d250090b771bb64345d84b9ef)



根据苹果官方文档：

![](/image/yi_cai_de_keng_32_64bit_jia_gou_xia_bool_lei_xing_bu_tong/21ddee992364f87168a620122eac810fad8a294a28757ceeda1c9d8f56342474)



由上可知，32-bit下，BOOL被定义为signed char；64-bit下，BOOL被定义为bool。

因此，32-bit版本的BOOL包括了256个值的可能性，而64-bit下只有0（NO），1（YES）两种可能，是真正意义上的Boolean类型。



**结论**

通过performSelector等方式调用系统API时，若参数为BOOL，不可直接传由BOOL值初始而来的NSNumber（除非APP已不需要支持iphone5及其以下的机型）。

可调用自定义函数来实现相同的功能，比如此例中的修改方式便为：

![](/image/yi_cai_de_keng_32_64bit_jia_gou_xia_bool_lei_xing_bu_tong/ebac2973fac44e9da5db7ab4a96ecf5c4ccfdd687af380e143ace82f0f0f469b)



