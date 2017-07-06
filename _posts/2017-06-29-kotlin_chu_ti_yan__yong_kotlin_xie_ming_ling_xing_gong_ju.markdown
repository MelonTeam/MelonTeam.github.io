---
layout: post
title: "Kotlin 初体验: 用 Kotlin 写命令行工具"
date: 2017-06-29 22:56:00
categories: android
author: vashzhong
tags: java kotlin
---

* content
{:toc}

| 导语 可喜可贺, kotlin 在今年的 google I/O 大会上, 成为 google android 平台的新一门官方语言,
偶尔有了个写工具的机会试着用它来替代原来常用的 python

## 工具需求

<!--more-->
工具需求很简单: 批量处理 proj 工程代码, 对符合条件的代码做后续的字符串替换, 然后存储到目标路径

按理说用批处理加 find/sed 工具也能搞定, python 撸脚本工具也一样高效, 但我想体验一下 kotlin, 所以就用它上了, 结果一晚上,
百行代码解决问题

### 工具执行大概示例如图

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/561e340954b438b6cc388aa0dd20c0d9e58b864cc4133e1a0f8b6836406dd5d2)  
如图, root 下边 N 层目录, M 个文件  
找到关心的文件(示例中为 *.java )  
根据规则替换文件内容, 重新把替换内容写入目标位置

### 文件处理流程

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/129521323c8e14695a0d7dee37389c31b42db93dd8b607153ceccb79a0ec5a58)

如上图画了个大致图示, 因为过滤文件规则, 按照规则匹配和替换, 这两个操作不依赖额外的资源, 可以进行一定的多线程并行

了解 reactive programming 的同学应该会感到这个图示相当山寨, 和那种 marble 图挺像, 确实如此.

so, 就是用reactive.io对应的kotlin库, 实现这套功能

## 代码流水账

### 1\. 线程池初始化

获取机器核数, 自定义线程池:  
自定义线程池代码, 因为要指定线程名称, 所以实现了匿名 ThreadFactory 实现类, kotlin 代码相对比较简单  
![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/43826b407a6e951472eb9a84fcd3476c5249f1c06c0311dba1e8a2e5dbfe4986)

### 2\. 参数解析

命令行工具当然需要读入参数了  
我这里定义 src, dst 参数  
使用 joptsimple.OptionParser 轻松实现:  
![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/705a8609e2bae5b8eed8f86a1167c54e9a196425fe70783d1586b68ecc2136e1)

### 3\. 解析参数, 根据目标文件夹, 创建目录结构

工具中如果指定了 dst, 那么会镜像创建 src 的所有文件夹, 实现如下

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/adeac795e2c6bea573fd2180d47e380c7c06b29a257eb60037ba7ce82d1d8797)

kotlin 中的类型转换用 as 这个关键字, 其中 as String, 表示会将结果转换为 String, 如果结果为 null,
那么这里直接会发生运行时异常  
第二句, 先转换成 String? 类型, 即可为空的String类型, 接下来 ?: srcPath, 表示如果为null, 那么使用 srcPath  
后边的判断, 如果srcPath和dstPath不等, 那么按照srcPath创建目录结构  
这里String的判等, 用两个=号, 判断值类相等, 用三个=号, 判断引用相等  
kotlin的文件遍历有一个函数式的扩展: walk(), 用起来也是函数式的感觉, 一气呵成

### 4\. 给reactive库创建几个线程切换的scheduler

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/7d0b7b1dcdb400a9a73063595e8461d6c554025eac191fa9a68f338c6e05f291)  
可以看到 readScheduler/writeScheduler, ThreadFactory 没有显式的写匿名对象, 因为 kotlin 支持这种
lambda 式的语法糖, 来实现一个单函数接口(比如 Runnable / Callable), 后边还会看到

### 5\. 执行图示的那一坨 reactive 流程

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/578e2d6f672d817b3e340f88130bd3c48310358994c1ea20bad298e6ac91d390)  
完成, 就是这么简单

rxkotlin的扩展, 简化了各种常用类型创建Observable对象的写法:

#### 多线程过滤部分:

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/d07ca50ddd41c440cec0ffbb8d7495994792a7433df48a08e749e21dd68b529a)  
可以看到 filter和flatmap 里边又是一个 lambda 实现了一个接口 (java8中也是类似的, x -> {})

#### 读取文件部分:

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/94f1bb2bca04c9d7272b3a558ff3252d65b374c3c08b3b3095f14105286543e4)  
读取文件这里之所以用flatMap, 是因为需要每次读完文件后, 下一步切换到多线程 scheduler

#### 写文件部分:

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/2dc9a44c8115d84ff006c0088a4ce1a834fed10d9c352c64b1dff595dfae5f00)  
kotlin没有 java 的 X ? y : z 的三目运算语法, 只能写成if else, 有点类似python.

#### 计数统计部分

![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/1b80a61cc1bb296c00dc96d994f90ad44701262417c04c06b823b30a24fe52da)  
count().blockingGet()返回的便是最后写了多少个文件的个数了.

## 其他:

### 替换的实现在哪里呀?

其实就在这里  
![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/398215288b0f1894726f6d056fac32f1a2332f4a42b17f9555f343473d6722bf)  
就是这一句 .compose(processStrategy)  
processStrategy是一个由你实现的 ObservableTransformer , 随意发挥即可  
比如这个实现:  
![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/ba5d7d66c45d21c2d7253cef58d9857803c20095eeda7727c7a31fa48694c6d8)  
在文本中找TODO的注释, 然后替换成””, 不想再骗自己了, 注意到这里用flatMap顺带做了filter的效果, 如果没有找到匹配,
相当于就在这一步被过滤掉, 不会进行下一步写文件.

### 写完了怎么编jar包?

我这里使用的是gradle + kotlin插件, 可以继承一个jar的任务来生成fatjar, 我的整个build.gradle如下:  
![](/image/kotlin_chu_ti_yan__yong_kotlin_xie_ming_ling_xing_gong_ju/6080e358601a2e1b63fcfd1353a3216aaccef66ca9899709e7abc4e013b9fc3d)

### 我看kotlin

kotlin 值得一玩了, 如果用在生产环境, 也需要团队的统一规范, 以及琢磨一下最好的实践. 自己并没有深入学习 kotlin, 只是了解了些皮毛,
会写像 C 一样的 Java, 会写像 Java 一样的 Kotlin…

看到有同事写的 < 为什么我不喜欢Kotlin > :
<http://km.oa.com/group/18297/articles/show/305773>, 说到了代码复杂度的增加, 理解的困难, 说的没错,
毕竟工具是死的人是活的.

因为没有深入理解, 也没有搞过 kotlin 的大型项目, 不敢吹捧:), 但这次的初体验, 总的感觉还不错.

#### 喜欢的点

  1. 常量特性 val, 对 [@NonNull](https://github.com/NonNull "@NonNull" ) 这种修饰的原生支持
  2. 对 Nullable 的 fallback 语法
  3. 字符串模板
  4. data class
  5. apply, let, with … 
  6. 待补充

#### 不喜欢的点

  1. X..Y 这样的 range 表示有点蛋疼. 因为定式思维, X..Y 的第一直觉会让我觉得是 [X, Y) 这样的开闭区间.
  2. class 里边没法放 static field, 查了一下似乎要写一个 Companion object, kotlin 的 singleton 模式难道也要这么写? -> 其实可以直接写 object xx {} 但也需要适应下.. 反直觉
  3. 待补充… 也许要多用才会躺坑, 发现新的点 :)

## 参考资料:

Introduction to Kotlin (Google I/O ‘17) -
<https://www.youtube.com/watch?v=X1RVYt2QKQE>

