---
layout: post
title: "配置tensorflow GPU 版本填坑路"
date: 2017-07-29 23:21:00 +0800
categories: ios
author: soapyang
tags: tensorflow cuda 安装 pycharm 教程
---

* content
{:toc}

| 导语 运气好按照教程一把过，运气不好遇到一堆抓狂的问题，记录下踩到的坑

如果是练习教程中的例子tensorflow cpu 版本够用了，要训练的话还是gpu版本要快很多，

本文记录了在我们配备的主流Mac电脑上，安装gpu版本常见问题和解决方法
<!--more-->

显卡为：

    
    
      芯片组型号：    NVIDIA GeForce GTX 775M
      类型：    GPU
      总线：    PCIe
      PCIe Lane 宽度：    x16
      VRAM（总和）：    2048 MB
      供应商：    NVIDIA (0x10de)  
    一. 环境
    
    
    Mac OSX 10.12
    Python:3.6.2
    CUDA Toolkit 8.0
    cuDNN 5.1
    

 二. tensorflow 的安装

 参考官方教程，[https://www.tensorflow.org/install/install_mac,
不再赘述](https://www.tensorflow.org/install/install_mac)

建议

1 如果你使用Pycharm编辑器的话，Pycharm自带虚拟环境创建，建议安装到PyCharm的虚拟环境中。

2如果你裸写，建议使用virtualenv来安装tensorflow

三. 安装CUDA

1.安装 CUDA Driver 8.0：

请到如下地址安装最新版 CUDA Driver for Mac： http://www.nvidia.com/object/mac-driver-
archive.html

安装完成后再偏好设置里会看到这个选项  
![](/image/pei_zhi_tensorflow_gpu_ban_ben_tian_keng_lu/466e633eb2ef9c4e0807ecd630304e5d8096d57fcd2ce40ae951f62ece8cc010)

2\. 安装 CUDA Toolkit 8.0：  
建议在线下载 dmg 安装包安装 CUDA Toolkit 8.0，下载地址如下：  
https://developer.nvidia.com/compute/cuda/8.0/Prod/local_installers/cuda_8.0
.55_mac-dmg

3.配置CUDA环境，这一步出了很多问题，基本上都会遇到ImportError: dlopen和Segmentation fault:
11两个问题，安装下面的配置就可以了，

输入

    
    
    sudo open ~/.bash_profile

 在打开文件后面追加以下内容

    
    
    export PATH
    export CUDA_HOME=/usr/local/cuda
    export DYLD_LIBRARY_PATH=${CUDA_HOME}/lib:${CUDA_HOME}/extras/CUPTI/lib:/Developer/NVIDIA/CUDA-8.0/lib
    export LD_LIBRARY_PATH=$DYLD_LIBRARY_PATH
    export PATH=$DYLD_LIBRARY_PATH:$PATH

完成后是这个样子的，记得保存，用下面的命令刷新，如果遇到没权限之类的，重启电脑吧....顺便休息以下

    
    
    . ~/.bash_profile

 4.编译使用 CUDA 的 deviceQuery` `

    
    
    cd /usr/local/cuda/samples
    sudo make -C 1_Utilities/deviceQuery
    ./bin/x86_64/darwin/release/deviceQuery

5 安装 cuDNN 5.1： 下载地址如下： https://developer.nvidia.com/compute/machine-
learning/cudnn/secure/v5.1/prod_20161129/8.0/cudnn-8.0-osx-x64-v5.1-tgz  
  

然后解压并进入该目录，执行如下操作：` `

    
    
    sudo mv include/cudnn.h /Developer/NVIDIA/CUDA-8.0/include/
    sudo mv lib/libcudnn* /Developer/NVIDIA/CUDA-8.0/lib
    sudo ln -s /Developer/NVIDIA/CUDA-8.0/lib/libcudnn* /usr/local/cuda/lib/



好了，大功告成。

但是如果你运行例子遇到以下错误

    
    
    ImportError: dlopen(/Users/valiantliu/tensorflow/lib/python3.6.1/site-packages/tensorflow/python/_pywrap_tensorflow.so, 10):   
    Library not loaded: @rpath/libcudart.7.5.dylib Referenced from: /Users/valiantliu/tensorflow/lib/python3.6.1/site-packages/tensorflow/python/_pywrap_tensorflow.so Reason:   
    image not found

 是第3步的环境没有配置好，找不到CUDA的库，重新配置以下

如果遇到

    
    
    I tensorflow/stream_executor/dso_loader.cc:108] successfully opened CUDA library libcublas.dylib locally
    I tensorflow/stream_executor/dso_loader.cc:108] successfully opened CUDA library libcudnn.dylib locally
    I tensorflow/stream_executor/dso_loader.cc:108] successfully opened CUDA library libcufft.dylib locally
    Segmentation fault: 11

 这个错误也是和第2步有关，检测是不是有这一句话，总之LD_LIBRARY_PATH也要有值。

    
    
    export LD_LIBRARY_PATH=$DYLD_LIBRARY_PATH

如果运行Import tensorflow 出现以下内容，说明就安装成功了，散花

    
    
    python -c "import tensorflow as tf"
    I tensorflow/stream_executor/dso_loader.cc:135] successfully opened CUDA library libcublas.8.0.dylib locally
    I tensorflow/stream_executor/dso_loader.cc:135] successfully opened CUDA library libcudnn.5.dylib locally
    I tensorflow/stream_executor/dso_loader.cc:135] successfully opened CUDA library libcufft.8.0.dylib locally
    I tensorflow/stream_executor/dso_loader.cc:135] successfully opened CUDA library libcuda.1.dylib locally
    I tensorflow/stream_executor/dso_loader.cc:135] successfully opened CUDA library libcurand.8.0.dylib locally`

四. 可能你高高兴兴的去跑训练，发现IDE里又报错了，My God，人生如此艰难

    
    
    ImportError: dlopen(/Library/Frameworks/Python.framework/Versions/3.5/lib/python3.5/site-packages/tensorflow/python/_pywrap_tensorflow.so, 10): 
    Library not loaded: @rpath/libcudart.7.5.dylib
      Referenced from: /Library/Frameworks/Python.framework/Versions/3.5/lib/python3.5/site-packages/tensorflow/python/_pywrap_tensorflow.so
      Reason: image not found

解决方法是

![](/image/pei_zhi_tensorflow_gpu_ban_ben_tian_keng_lu/068fb1243b24ad4d4bb9e348589bc0d00692809ca75e2ffc154025e6a7bda64d)

![](/image/pei_zhi_tensorflow_gpu_ban_ben_tian_keng_lu/55d24547bdb44f435a89bf7d45e2748d589e118d83a5ebff78487a563fcb63ba)

![](/image/pei_zhi_tensorflow_gpu_ban_ben_tian_keng_lu/8358c9b586845675741ba6403153031e9861bc1ef9a6c7ab9d09a2a225fb6fbb)

增加以下配置

    
    
    1 DYLD_LIBRARY_PATH  /usr/local/cuda/lib:/usr/local/cuda/extras/CUPTI/lib:/Developer/NVIDIA/CUDA-8.0/lib  
    2 LD_LIBRARY_PATH /usr/local/cuda/lib:/usr/local/cuda/extras/CUPTI/lib:/Developer/NVIDIA/CUDA-8.0/lib  
    

如果没有第一行，会出现Image error问题，如果没有第二行，python进程会crash，默默终止了。

好走到这里应该可以正常运行了，如果出现oom错误，调小程序参数。

还有每次运行之后，显卡的内存看起来并没有正常释放，导致第二次运行必现oom，需要重启电脑，如果有其他好方法，也留言造福大家。

