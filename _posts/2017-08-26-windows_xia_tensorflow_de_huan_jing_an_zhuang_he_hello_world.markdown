---
layout: post
title: "Windows下Tensorflow的环境安装和Hello world"
date: 2017-08-26 16:48:00 +0800
categories: 未分类
author: kylepeng
tags: 环境搭建
---

* content
{:toc}

| 导语 深度学习 数字识别 Tensorflow 环境搭建

本人对深度学习是0基础，python也是没有用过，最近很流行深度学习，因此也想学习一下，上次听同学的培训介绍深度学习的hello
world就是写一个数字识别的程序，下面我按照Tensorflow的网站介绍，搭建了windows的开发环境。

<!--more-->
为什么是Tensorflow呢，因为Tensorflow是google推出的开源项目，很多公司都使用这个来进行深度学习开发，因此我就随大流，也用Tensorflow来学习。

环境的安装

我的是windows环境，没装python。

1.去python网站下载python3.5.x的
windows版安装程序，虽然现在最新版的python是3.6.1，但TensorFlow的教程上写的是3.5.x,
所以我没有用最新的，而是下载了3.5.3版本的python安装包来安装，安装包地址：<https://www.python.org/ftp/python/3.5.3/python-3.5.3-amd64.exe>

安装步骤如下：

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/ec4698eaa750f780f8f88afb26bdb621d32b126d87cf0b4a1d79147a18aa7b93)

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/ecf8e04f6f980a047570a8ba6d1cd4c6b9620e1f62bd0b0b304782f9ab6d7dc9)

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/0072a551c0f35541b7cdae7018fa9999b8daaca015390c802a857b4a937ab3d0)

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/ce17b4c69311be46b7d449a03af8305f9a54af6b6af4a02fa5e95218b5c49f62)

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/b3236883b153d842b1c3d41d0b93a11509ee65936493ae366de7d444724139e5)

2.安装TensorFlow，tensorflow有两个版本，一个是支持GPU的，需要有NVIDIA的显卡，然而我的机器并没有，所以装的是cpu版。

打开个新cmd窗口，输入如下命令

    
    
    **pip3 install --upgrade tensorflow**

如果要装GPU版，请输入如下命令

    
    
    **pip3 install --upgrade tensorflow-gpu**

安装完成

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/a8b2f3a6cc38ab5c0f8222591d40cc5dd98f9fb5a43c02f035d1a4fb0327164c)

3.注意还需要安装Microsoft Visual C++ 2015Redistributable(x64) ,
不然tensorflow的模块还是不能用的，安装包下载地址：

<
96E7-D4B285925B00/vc_redist.x64.exe>

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/b00f9fe0a7798975c930ca28d73dcb5c92c2912ab0460a7595a31cf5ece6c90b)

4\. 校验环境是否正确

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/5a23999402fd3de6974f2455d8d06b2988ccb26782612159550bb4d55fc788a5)

虽然中间打印了一条warning，但环境是ok了，可以开始用来深度学习了。

开始“写”Hello world了，说是写，其实把Tensorflow自带上的一个例子拿来运行。这个例子的位置是

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/c914622b810d77acec7e577f1efacddc2f3c45c683a39808bc1b9ebbed638bac)

这里都是例子，其中mnist_deep.py就是一个进行数字识别的深度学习的例子，它使用了Tensorflow上的图片库来进行学习和校验，让我们看看它运行的结果，把mnist_deep.py拷贝到某个目录，然后在那个目录运行下面的命令。

    
    
    python mnist_deep.py

 如果在公司开发网中，这样运行会报错，连不上服务器，是因为开发网要设代理，那么把代理设上

    
    
    set https_proxy=

 之后再运行python mnist_deep.py, 就可以正常的运行了

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/53b42c3656a943fcf1a54ca73446b174acf7c8deb6871f35a4cc56efa1ac9aca)

这个例子的功能是首先开始去Tensorflow网站下载训练和校验的素材，

然后开始进行数字识别训练

最后进行校验训练的效果，会拿校验素材来进行验证学习之后的数字识别准确率。

![](/image/windows_xia_tensorflow_de_huan_jing_an_zhuang_he_hello_world/cd447bfe0fde2389378db03512c3ef583aa9ca2584af2bb8eb8ba932094334a0)

因为本人也是python 零基础的，所以到这步之后，也需要仔细的去读代码，就不班门弄斧了。

在这里欢迎各位新手也都能加入到深度学习的坑里来

注：这里例子使用的素材不是普通的图片格式，而是自定义的格式，格式的介绍可以看这里

<http://yann.lecun.com/exdb/mnist/>

参考资料：

<https://www.tensorflow.org/install/install_windows>

<https://www.tensorflow.org/get_started/mnist/pros>

<http://yann.lecun.com/exdb/mnist/>

