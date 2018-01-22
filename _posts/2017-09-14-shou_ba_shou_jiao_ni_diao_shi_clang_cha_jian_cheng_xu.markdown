---
layout: post
title: "手把手教你调试Clang插件程序"
date: 2017-09-14 21:05:00 +0800
categories: ios
author: yockieyang
tags: 插件 调试
---

* content
{:toc}

| 导语
上一篇文章介绍了怎么给自己的Xcode安装Clang插件程序，但是有个问题，当我们想修改我们的插件代码的时候，却无法调试我们的程序，因为我们运行完MyPlugin后Xcode直接生成的相应地dylib，由于没有输入文件，所以我们是无法断点到我们的demo程序的。这篇文章主要给大家介绍怎么调试Clang插件程序。

**1.libTooling的简介**  
在我们学习调试插件程序之前，先大概了解一下libTooling这个库，根据相应参考文件中的解释，通过这个库我们很容易搭建我们编译器的前端工具。与之相对的还有一个libclang的库，这个库与libTooling相比就是他比较稳定，基本上没有什么更新。而libTooling跟clang是经常更新的，优缺点明显，缺点就是可能你在旧版本能跑的程序在新版本就不能跑了，优点就是提供给使用者远比libclang强大全面的AST解析和控制能力。至于该如何选择用libTooling和libclang，还是看官方说法吧。下面是官网的地址：  
<!--more-->
<http://clang.llvm.org/docs/Tooling.html>  
**2.生成libTooling程序**  
这步跟上一遍文章生成myPlugin差不多  
1.生成MyPluginTooling文件  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/6e121c95e80e88f60db5ea3de746849bb5450f6ac2b8715e709cdab84069662c)

  
2.添加myPluginTooling代码，其实就是把昨天的MyPlugin代码的静态注册插件  
static clang::FrontendPluginRegistry::AddX(“MyPlugin”, “My plugin”);的部分改成以下代码。  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/4a042681dbf41f29b46edbbc76e7ac6ceb6165bb3194a25d91418861a5468ebd)

  
同时把这个MyPluginASTAction这个方法给删了，以及更改成继承ASTFrontendAction  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/83d31fb65ea29b23eff4b5b8e0dbdee9f9ea507f8c35baaedc2fef85ac9deef3)

  
3.添加CMakeLists.txt文件，这个文件主要是用来设置运行你这个cpp所用到的库和相应的支持  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/921d1f9b800b2a362dc6cb9d91ffb459dad767a32456f95806cfb248a44c27a3)

  
4.然后外面的CMakeLists.txt文件添加下面这一行  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/305a5d654607c4b9d0ae133a178e30e97e83a18eda11593a5e6146be0d0f0f06)

  
5.跟上篇文章一样CMake来更新相应的LLVM程序  
6.最后看是否编译成功，确实是成功的  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/5a935c3ffe35618f3d4df3ff8a11c2ab5fc1b49bbb44c6545b41c698ea13ee66)

  
7.但是我们此时和上篇文章有一个问题，就是没有输入文件，我们执行这个程序是没有任何效果的。这就需要我们给她指定一个输入文件。在Manage
Scheme里面一个一个添加下面这些配置：  
/Users/yockieyang/Desktop/homeWork/test1/test1/adsd_dasd.m  
（—）（下面给的图把，只打——会出问题）  
-isysroot  
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk  
-isystem  
-I/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/8.1.0/include  
-I/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1  
-I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include  
-F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/7f420051ff7d9410ae2b4d8c28bd702e18a5e30477d9c45ecfa202e490ac8b09)

  
上面—是高速你要编译这个adsd_dasd.m文件必须使用下面-I，-F标出来的库，也就是当编译器执行到adsd_dasd.m里面的#import
这段代码的时候，系统会在你标注中的-I,-F的库寻找相应的文件，编译才能正常执行下去。否则会报找不到的错误。  
8.最后编译运行，效果和上篇文章一样  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/f73a5e4b9eebe66ab541efa48e44bc683a4eb21e2dc9ac24de371ea38e3cca4e)

  
9.但是我们却可以断点调了  

![](/image/shou_ba_shou_jiao_ni_diao_shi_clang_cha_jian_cheng_xu/e3739361517772e6e75382a80e9fc5bc0545d012b9d7428fe88f612dcee64043)

  
**3.总结**  
这篇文章主要告诉你怎么样调试Xcode clang 程序，具体clang,AST相关的知识将在以后学习给出来  
参考文件：<http://www.jianshu.com/p/01c988cae897>

