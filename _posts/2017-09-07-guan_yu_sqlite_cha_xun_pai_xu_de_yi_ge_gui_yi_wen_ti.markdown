---
layout: post
title: "关于sqlite查询排序的一个诡异问题"
date: 2017-09-07 20:55:00 +0800
categories: 未分类
author: henrikwu
tags: sqlite 排序 unique
---

* content
{:toc}

| 导语 sqlite3关于unique关键字有一个排序的坑，一不小心就会踩上。

首先建一个表，CREATE TABLE post_gift (_id INTEGER PRIMARY KEY AUTOINCREMENT,bid
INTEGER,gift_count INTEGER DEFAULT 1,gift_id INTEGER,pid TEXT,uid
TEXT,UNIQUE(bid,gift_id,pid));
<!--more-->

![](/image/guan_yu_sqlite_cha_xun_pai_xu_de_yi_ge_gui_yi_wen_ti/f7e0b2df3f5dae1070217254f4a3c9cb18aa7cc8134ee60189a9bcc9100073a1)

对于这个表，

     select * from post_gift ;

     select * from post_gift where post_gift.bid = 10171;

    这两个sql查询结果一样吗？

   答案可能出乎你意料之外，这两种查询结果并不一致!

   select * from post_gift ; 的结果如下，我们看到是按着_id的自然插入顺序排的

![](/image/guan_yu_sqlite_cha_xun_pai_xu_de_yi_ge_gui_yi_wen_ti/cf4a2195e78a93152bcda6db19008bed483934c02094cd185857edec2eeefa73)

    select * from post_gift where post_gift.bid = 10171;结果如下：

![](/image/guan_yu_sqlite_cha_xun_pai_xu_de_yi_ge_gui_yi_wen_ti/80d311f0a43c7ec01da5eb09932c10a95b0559a1c9b8138bc6c7063f69430a45)

    这里并没有按插入顺序给出结果，而似乎是按着gift_id升序给出的结果。但是我们的sql里面并没有按着gift_id的升序查询啊。

    这里似乎是sqlite的一个问题，因为bid gift_id pid 是unique的，所以似乎在where语句中带上这里的unique
key就会将结果按着这些unique key自然升序排序。不知道这算不算bug

