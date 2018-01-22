---
layout: post
title: "手把手教你使用Xcode clang插件"
date: 2017-09-14 17:55:00 +0800
categories: ios
author: yockieyang
tags: Clang
---

* content
{:toc}

| 导语
最近突然兴起想看一下clang插件的内容，作为一个初学者疯狂的搜索各个博客网站的内容，结果按各个网站的步骤尝试下来，一直error，error。（也可能是我能力有限，看不懂大神们的操作），终于在今天编译成功了，所以想把自己的操作详细的记录下来，跟博客差不多，但把博客的一些错误最近突然兴起想看一下clang插件的内容，作为一个初学者疯狂的搜索各个博客网站的内容，结果按各个网站的步骤尝试下来，一直error，error。（也可能是我能力有限，看不懂大神们的操作），终于在今天编译成功了，所以想把自己的操作详细的记录下来，跟博客差不多，但把博客的一些点给去掉了，也算方便后面的学习者吧。

本次学习的环境是Xcode8.3.1，其他版本的Xcode不一定保证成功  
**1.获取clang源码**  
<!--more-->
从这里<https://opensource.apple.com/tarballs/clang/>
把相应的clang源码下下来，最好是最新版的，目前最新版的源码是clang-800.0.42.1。其中LLVM主要的子项目包括：

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/49333ea368611ee8cde34ca99a9c6b5f64b9291ff3a74aa661b3aee3238cf1aa)

  
**2.编译LLVM得到相应的dylib文件**  
下载源码完成后解压目录，接下来就是要做编译LLVM的工作了。首先来对这些源码生成一个Xcode工程，源码项目的编译是由cmake管理（关于cmake详细资料请参考：cmake官方教程），因此生成Xcode工程非常方便。具体编译LLVM的步骤如下：  
1.进入到你的（非终端）/clang-800.0.42.1/src/tools/clang/examples这个路径，向里面的CMakeLists.txt添加一行add_subdirectory(MyPlugin)

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/52d6867743abea37c0626e19473b2a82d532c57c5a008c65e79b326bb042c25b)

  
2.然后用命令行创建文件夹MyPlugin及其里面的文件  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/e2f12f36c9edcedb92a658819c9b5a9142f6cfa08a278bc4968d5424c32c1c0a)

  
3.向MyPlugin你新创建出来的CMakeLists.txt加入下面的代码  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/617258fc0996f52f6c1753bbbee1137abbb5e6498719620984b5a92630291c24)

  
4.MyPlugin你新创建出来的MyPlugin.cpp加入下面的代码,代码一个截图截不下来，看后面附件吧。  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/42210bdaaba636027d1854f935eada96c6e201c5599809a6333a1e29ab6f15c9)

  
5.然后cd到clang-800.0.42.1根目录，执行下面的命令。  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/d964a0bbdea862414647dbaf1e6fd7b1f7d8feaf7d0e31f1c97840744368852e)

  
6.就会得到如下的LLVM Xcode工程。

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/a293c075a0bd3851f465508a021f0a1c210bd815b5d28d302d231aaa9a3ef6d9)

  
7.编译这个工程的MyPlugin,同时编译clang源码，看看是否可以编译得过。  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/0fdea81c71f2bca4f6f74c0a8d423b530b3c6264ec6975d436b8b8cea746549c)

  
8.这时你就会在／Debug/lib得到一个MyPlugin.dylib的库  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/56bb9a8ea58225d2dcbb8d65a66f9d3bc1de19622b8cd128c3bfc8e19087fbfe)

  
**3.通过Xcode使用相应的插件文件**  
1.新建一个test工程  
2.在Build Settings other C Flags里面添加如下选项  
-Xclang -load -Xclang /Users/yockieyang/Desktop/homeWork/llvm/llvm/clang-800.0.42.1/build/Debug/lib/MyPlugin.dylib -Xclang -add-plugin -Xclang MyPlugin -Xclang -plugin-arg-MyPlugin -Xclang $SRCROOT/..  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/6abead43ddffe0d73e4b12f1c4164b70e78930902c0abc8557b615c9dace6f0b)

  
3.如果你此时运行你相应的程序，你会发现会出现下面这样一个错误。是因为你的程序用的是IOS原生默认的clang.原生默认的clang是编译不过你的dylib库的，必须用你上面编译出来的clang文件编译，可以通过在Xcode工程的buildSetting添加CC和CXX将系统默认的clang改为你自己的clang.具体添加方法如下：  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/fe8b9b3d7ce837d8d98581e28a09c2a352923011393fd7faa2154b397e61dd39)

  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/4f7ea12a4fc5d52d06ed6856ee2995e869bb149ac26864e33204e99f920dc9ec)

  
4.这时你就可以编译你的test工程了，编译过程有点慢。但还是成功编译了，如果你此时建立一个叫a_bc的Cocoa
Class文件。由于我们这个插件的作用是检测文件名是否按照驼峰命名法命名，如果不是会报相应的错误，所以你此时的程序是编译不过的。提示信息如下：  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/646ec280a2252afe93d90134094da66d52e98cef73f68eb5a189481f2afff2b3)

  
至此，一个插件就算安装完成了。  
**4.随包处理**  
上面的相应clang程序和dylib程序都只是在本地，而我们的程序最终要上传到AppStore上去的，所以就不能指向本地了，我们所做的操作就是随包处理。也很简单，将LLVM
Debug 里面的bin的所有可执行程序和lib你的dylib程序和clang文件夹一起Add到你的应用程序里面，然后build
Setting重新指向正确的路径就可以了，具体效果如下。  

![](/image/shou_ba_shou_jiao_ni_shi_yong_xcode_clang_cha_jian/963a7bbb6312018c77d53815202538995fbec547af309439dc3f2c6ad05fb5cf)

  
**5.总结**  
以上只是教你在Xcode中怎么使用一个相应的clang插件，至于怎么调试插件程序，以及插件程序所用到的知识，代码，接口我们在之后的文章给出来。  
文章参考：<http://www.jianshu.com/p/581ef614a1c5>

