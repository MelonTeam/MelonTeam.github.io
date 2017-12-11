---
layout: post
title: "全卷积神经网络fcn学习笔记"
date: 2017-08-31 21:01:00 +0800
categories: ai
author: ginkgocheng
tags: 深度学习 全卷积神经网络 fcn
---

* content
{:toc}

| 导语 前段时间学习了一下全卷积神经网络fcn，现以笔记的形式总结学习的过程。主要包括四个部分：
（1）caffe框架的搭建；（2）fcn原理介绍；（3）分析具体fcn网络；（4）使用caffe框架进行fcn的训练和预测

# 一、caffe环境搭建

<!--more-->
## 1 环境

  * 1 硬件环境 笔记本双显卡，集显（Intel），独显（GF 920M）
  * 2 系统 Ubuntu16.4 (比Ubuntu14.4具有更好的兼容性)
  * 3 Cuda 8.0
  * 4 cudnn: cudnn-8.0-linux-x64-v5.1
  * 5 opencv: 3.1

## 2 更新源

可以选择阿里源

    
    
    sudo apt-get update
    

## 3 安装cuda

### 1 下载cuda-repo-ubuntu1404-7-5-local_7.5-18_amd64.deb

    
    
    sudo dpkg -i cuda-repo-ubuntu1404-7-5-local_7.5-18_amd64.deb
    sudo apt-get update
    sudo apt-get install cuda
    

### 2 打开~/.bashrc文件：

    
    
    sudo gedit ~/.bashrc
    

将以下内容写入到~/.bashrc尾部：

    
    
    export PATH=/usr/local/cuda-8.0/bin${PATH:+:${PATH}}
    export LD_LIBRARY_PATH=/usr/local/cuda8.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
    

### 3 测试CUDA的samples

    
    
    cd /usr/local/cuda-8.0/samples/1_Utilities/deviceQuerymake
    sudo make
    sudo ./deviceQuery
    

如果出现以下输出，则说明cuda安装成功。一般需要在重启后运行sudo ./deviceQuery 才会有正确的输出。  

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/6849faf21597c5802e67c840e65fa8e1a050ea4ba3bf61e4edf9d713bb59e8b2)  

[ image ]

## 4 安装cudnn

### 1 下载cuDNN5.1之后进行解压：

    
    
    sudo tar -zxvf ./cudnn-8.0-linux-x64-v5.1.tgz 
    cd cuda
    sudo cp lib64/lib* /usr/local/cuda/lib64/
    sudo cp include/cudnn.h /usr/local/cuda/include/
    

### 2 更新软链接

    
    
    cd /usr/local/cuda/lib64/
    sudo rm -rf libcudnn.so libcudnn.so.5    #删除原有动态文件
    sudo ln -s libcudnn.so.5.1.5 libcudnn.so.5  #生成软衔接
    sudo ln -s libcudnn.so.5 libcudnn.so      #生成软链接
    sudo ldconfig
    

最后一句代码出现错误

    
    
    sudo mv /usr/lib/nvidia-375/libEGL.so.1 /usr/lib/nvidia-375/libEGL.so.1.org
    sudo mv /usr/lib32/nvidia-375/libEGL.so.1 /usr/lib32/nvidia-375/libEGL.so.1.org
    sudo ln -s /usr/lib/nvidia-375/libEGL.so.375.39 /usr/lib/nvidia-375/libEGL.so.1
    sudo ln -s /usr/lib32/nvidia-375/libEGL.so.375.39 /usr/lib32/nvidia-375/libEGL.so.1
    
    
    
    sudo ldconfig
    

## 5 安装opencv3.1

### 1
从官网(<

    
    
    unzip opencv-3.1.0.zip
    sudo cp ./opencv-3.1.0 /home
    sudo mv opencv-3.1.0 opencv
    

### 2 安装前准备，创建编译文件夹：

    
    
    cd ~/opencv
    mkdir build
    cd build
    

### 3 配置：

    
    
    sudo apt install cmake
    sudo cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local ..
    

### 4 修改源码

因为opecv3.0与cuda8.0不兼容导致的。解决办法：修改
～/opencv/modules/cudalegacy/src/graphcuts.cpp文件内容，如图：  

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/1d3546c63af69c1eaabaf9cda7b962ca5337811e2a3b50f3f47177bce6a81890)  

[ image ]

  
代码：

    
    
    #if !defined (HAVE_CUDA) || defined (CUDA_DISABLER)||(CUDART_VERSION>=8000)
    

### 5 编译：

    
    
    sudo make -j8
    

### 6 安装

以上只是将opencv编译成功，还没将opencv安装，需要运行下面指令进行安装：

    
    
    sudo make install
    

## 6 编译caffe

[参考官方教程](http://caffe.berkeleyvision.org/install_apt.html)

[caffe下载](https://github.com/BVLC/caffe)

### 1 安装依赖库

    
    
    sudo apt-get install libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler
    sudo apt-get install --no-install-recommends libboost-all-dev
    sudo apt-get install libatlas-base-dev
    sudo apt-get install libgflags-dev libgoogle-glog-dev liblmdb-dev
    

### 2 修改makefile.config

因为make指令只能make
Makefile.config文件，而Makefile.config.example是caffe给出的makefile例子，因此，首先将Makefile.config.example的内容复制到Makefile.config：

    
    
    sudo cp Makefile.config.example Makefile.config
    

  * a.若使用cudnn，则将
    
        USE_CUDNN := 1
    修改成： 
    USE_CUDNN := 1
    

  * b.若使用的opencv版本是3的，则将
    
        #OPENCV_VERSION := 3 
    修改为： 
    OPENCV_VERSION := 3
    

  * c.若要使用python来编写layer，则

    
    
    将
    #WITH_PYTHON_LAYER := 1  
    修改为 
    WITH_PYTHON_LAYER := 1
    

  * d.重要的一项 :  
将 # Whatever else you find you need goes here. 下面的

    
    
    INCLUDE_DIRS := $(PYTHON_INCLUDE) /usr/local/include
    LIBRARY_DIRS := $(PYTHON_LIB) /usr/local/lib /usr/lib
    

修改为：

    
    
    INCLUDE_DIRS := $(PYTHON_INCLUDE) /usr/local/include /usr/include/hdf5/serial
    LIBRARY_DIRS := $(PYTHON_LIB) /usr/local/lib /usr/lib /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu/hdf5/serial
    

这是因为ubuntu16.04的文件包含位置发生了变化，尤其是需要用到的hdf5的位置，所以需要更改这一路径.

### 3 修改makefile文件

打开makefile文件，做如下修改：  
将：

    
    
    NVCCFLAGS +=-ccbin=$(CXX) -Xcompiler-fPIC $(COMMON_FLAGS)
    

替换为：

    
    
    NVCCFLAGS += -D_FORCE_INLINES -ccbin=$(CXX) -Xcompiler -fPIC $(COMMON_FLAGS)
    

### 4 编辑/usr/local/cuda/include/host_config.h

将其中的第115行注释掉：将

    
    
    #error-- unsupported GNU version! gcc versions later than 4.9 are not supported!
    

改为

    
    
    //#error-- unsupported GNU version! gcc versions later than 4.9 are not supported!
    

### 5 拷贝cuda的一些so文件

将一些文件复制到/usr/local/lib文件夹下：

> 注意自己CUDA的版本号！

    
    
    sudo cp /usr/local/cuda-8.0/lib64/libcudart.so.8.0 /usr/local/lib/libcudart.so.8.0 && sudo ldconfig
    sudo cp /usr/local/cuda-8.0/lib64/libcublas.so.8.0 /usr/local/lib/libcublas.so.8.0 && sudo ldconfig
    sudo cp /usr/local/cuda-8.0/lib64/libcurand.so.8.0 /usr/local/lib/libcurand.so.8.0 && sudo ldconfig
    sudo cp /usr/local/cuda-8.0/lib64/libcudnn.so.5 /usr/local/lib/libcudnn.so.5 && sudo ldconfig
    

### 6 编译

    
    
    make all -j8 #-j根据自己电脑配置决定
    sudo make runtest
    

如果运行之后出现下图，说明caffe配置成功。

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/203474c8f3c8a90f256dc445ec28c12f1e9bf0e6426f0aa5ece2b5521490c61b)  

[ image ]

### 7 测试minist

  * 1.将终端定位到Caffe根目录

    
    
    cd ~/caffe
    

  * 2.下载MNIST数据库并解压缩
    
        ./data/mnist/get_mnist.sh
    

  * 3.将其转换成Lmdb数据库格式
    
        ./examples/mnist/create_mnist.sh
    

  * 4.训练网络
    
        ./examples/mnist/train_lenet.sh
    

### 8 编译python接口

在caffe根目录的python文件夹下，有一个requirements.txt的清单文件，上面列出了需要的依赖库，按照这个清单安装就可以了。

  * 1 首先回到caffe的根目录，然后执行安装代码：

    
    
    cd ~/caffe
    sudo apt-get install gfortran
    cd ./python
    for req in $(cat requirements.txt); do pip install $req; done
    

  * 2 安装完成以后，再次回到caffe根目录我们可以执行：
    
        sudo pip install -r python/requirements.txt
    

就会看到，安装成功的，都会显示Requirement already satisfied,
没有安装成功的，也可以按照requirements.txt所罗列的一个一个安装

  * 3 编译python接口
    
        sudo make pycaffe -j8
    

# 二、fcn网络介绍

## 1 CNN和FCN

### 1 CNN卷积神经网络

  * 卷积神经网络较浅的卷积层感知域较小，学习到一些局部区域的特征；较深的卷积层具有较大的感知域，能够学习到更加抽象的特征。这些特征对物体的大小、位置和方向等敏感性更低，从而有助于识别性能的提高。这些抽象特征对于分类很有帮助，但是因为丢失了一些物体的细节，不能很好地给出物体具体的轮廓，不能对物体做精确的分割。

### 2 传统使用CNN进行图像分割

  * 传统的基于CNN的分割方法：为了对一个像素进行分类，传统的方法是将像素与周围的像素组成像素块作为CNN的输入用于训练和预测。这种方法存储开销大、计算效率低下，而且像素块的大小相对于整幅图像而言小很多，只能提取一些局部的特征，从而导致分类的性能受到限制。

### 3 CNN与FCN

  * 通常cnn网络在卷积之后会接上若干个全连接层，将卷积层产生的特征图（feature map）映射成为一个固定长度的特征向量。一般的CNN结构适用于图像级别的分类和回归任务，因为它们最后都期望得到输入图像的分类的概率，如ALexNet网络最后输出一个1000维的向量表示输入图像属于每一类的概率。
  * FCN对图像进行像素级的分类，从而解决了语义级别的图像分割问题。与经典的CNN在卷积层使用全连接层得到固定长度的特征向量进行分类不同，FCN可以接受任意尺寸的输入图像，采用反卷积层对最后一个卷基层的特征图（feature map）进行上采样，使它恢复到输入图像相同的尺寸，从而可以对每一个像素都产生一个预测，同时保留了原始输入图像中的空间信息，最后奇偶在上采样的特征图进行像素的分类。  
-全卷积网络(FCN)是从抽象的特征中恢复出每个像素所属的类别。即从图像级别的分类进一步延伸到像素级别的分类。  

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/2dfe0ecdb6f91dd64d9c970bad7cf1e7eb56935457ae3e5168565073dea4cc15)  

[ image ]

> 简单的说，FCN与CNN的区别在于FCN把CNN最后的全连接层换成卷积层，输出一张已经label好的图。

## 2 FCN全卷积神经网络

### 1 卷积化（Convolutionalization）

  * 分类所使用的cnn通常会在最后使用全连接层，全连接层将原来的二维（图片）压缩成一维的，从而丢失了控件信息，最后训练输出一个标量，这就是我们的分类标签。而在图像语义分割的输出则需要是个分割图，是个二维的，所以在fcn中丢弃全连接层，换上卷积层，这就是所谓的卷计化。

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/280ddd076b71da551d888411ec46098896dfd1b2ae8994b010c96bd50e00460d)  

[ image ]

  * 全连接层和卷积层之间唯一的不同就是卷积层中的神经元只与输入数据中一个局部区域连接连接，并且在一个卷积核中的神经元共享权值参数。然而在卷基层和全连接层中，神经元都是计算点积，所以他们的函数形式是一样的。两者之间存在相互转化的可能。

  1. 对于任一个卷积层，都存在一个能实习那和它一样的前向传播函数的全连接层。权重矩阵中，除了某些特定的块，其余不都为0；
  2. 任何一个全连接层都可以转化为卷积层。如，对于一个K=4096的全连接层，输入数据的大小为7x7x512， 这个全连接层可以等效地看作一个卷积核的大小（感受野）F=7;步长S=1;输出特征个数NNUM = 4096的卷基层。

    
    
    对于FC6(4096)，使用4096个filter，filter的大小是7*7，做完以后大小为1*1*4096
    对于FC7(4096)，使用4096个filter，filter的大小是1*1，做完以后大小为1*1*4096
    对于FC8(1000)，使用1000个filter，filter的大小是1*1，做完以后大小为1*1*1000
    

> 所有的层都是卷积层，故称为全卷积网络。

### 2 上采样（Upsampling）

  * 在一般的CNN结构中均是使用pooling层来缩小输出图片的size，如果在VGG16中，五次pooling之后特征图的大小比输入图缩小了32倍。而在fcn网络中，要求网络输出与原图size相同的分割图，因此我们需要对最后一层进行上采样。在caffe中也被称为反卷积（Deconvolution）。
  * 虽然转置卷基层和卷积层一样，也是可以训练参数的，但是在实验中发现，让转置卷基层可学习，并没有带来性能的提高，所以在实验中转置卷基层的lr全部设为0.

### 3 跳跃结构（Skip Layer）

  * 如下图所示：对原图进行卷积conv1、pool1后图像缩小为1/2；对图像进行第二次卷积conv2、pool2后图像缩小为1/4；对图像进行第三次卷积conv3、pool3后图像缩小为1/8，此时保留pool3的featuremap；对图像进行第四次卷积conv4、pool4后图像缩小为1/16，此时保留pool4的featuremap；对图像进行第五次卷积conv5、pool5后图像缩小为1/32，然后把原来CNN操作过程中的全连接编程卷积操作的conv6、conv7，图像的featuremap的大小依然为原图的1/32,此时图像不再叫featuremap而是叫heatmap。

  * 其实直接使用前两种结构就已经可以得到结果了，这个上采样是通过反卷积（deconvolution）实现的，对第五层的输出（32倍放大）反卷积到原图大小。但是得到的结果还上不不够精确，一些细节无法恢复。于是将第四层的输出和第三层的输出也依次反卷积，分别需要16倍和8倍上采样，结果过也更精细一些了。这种做法的好处是兼顾了local和global信息。

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/0672a434af63ac7728b6f2f71d679a20efbcb48629eae7d40bbcf2efa0b00b09)  

[ image ]

下图是32倍，16倍和8倍上采样得到的结果的对比，可以看到它们得到的结果越来越精确：

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/43e4b23d48efd5de0194f60c217923ae8940cabaa6a066519ed708037af95666)  

[ image ]

在不同层级的赤化层分别上采样，然后叠加在一起，这样就产生了很好的结果。

## 3 FCN的优点和不足

  * 与传统用CNN进行图像分割的方法相比，FCN有两大明显的优点：一是可以接受任意大小的输入图像，而不用要求所有的训练图像和测试图像具有同样的尺寸。二是更加高效，因为避免了由于使用像素块而带来的重复存储和计算卷积的问题。

  * 同时FCN的缺点也比较明显：一是得到的结果还是不够精细。进行8倍上采样虽然比32倍的效果好了很多，但是上采样的结果还是比较模糊和平滑，对图像中的细节不敏感。二是对各个像素进行分类，没有充分考虑像素与像素之间的关系，忽略了在通常的基于像素分类的分割方法中使用的空间规整（spatial regularization）步骤，缺乏空间一致性。

# 3 fcn网络分析-以voc数据集为例

## 1 准备

我们主要分析voc-fcn32s文件夹下train.prototxt文件，这是网络训练模型，以此模型为例，分析fcn网络。

  * [train.protext的下载地址](https://github.com/shelhamer/fcn.berkeleyvision.org/blob/master/voc-fcn32s/train.prototxt)
  * 建议使用[Netscope](http://ethereon.github.io/netscope/#/editor)查看分析网络模型。把train_protext的内容复制粘贴到左边输入框，按shift+enter即可显示网络结构，鼠标移动到某一层之后，显示该层的具体参数。

  * fcn与cnn不同的的地方还有cnn输入的图像大小固定，每层特征图的大小也是预先设定好的；fcn可以输入不同大小的图像，设fcn输入图像的高度为h。

  * 输入为h,卷积层卷积核大小k，pading为p，步长为s，则经过卷积层之后特征图h变为

    
    
    h' = (h-k+2*p)/s+1
    

## 2 逐层分析

### 1 输入层

    
    
    layer {
      name: "data"
      type: "Python"
      top: "data"
      top: "label"
      python_param {
        module: "voc_layers"
        layer: "SBDDSegDataLayer"
        param_str: "{\'sbdd_dir\': \'../data/sbdd/dataset\', \'seed\': 1337, \'split\': \'train\', \'mean\': (104.00699, 116.66877, 122.67892)}"
      }
    }
    

  * fcn网络的数据输入层与一般的caffe网络输入lmdb格式不同，作者自定义了输入层，在voc_layer.py文件中。  
==所以在编译caffe时，一定要把Makefile.config文件==

    
    
    #WITH_PYTHON_LAYER := 1 
    改为
    WITH_PYTHON_LAYER := 1
    

==表示允许使用python来编写layer==

  * voc_layer.py中有两个类，VOCSegDataLayer(测试时使用)和SBDDSegDataLayer(训练时使用)，两个类都继承于caffe.Layer.因而必须重写setup()，reshape()，forward()，backward()函数

函数名 | 作用  
---|---  
setup() | 数据初始化  
reshape() | 取数据然后把它规范化为四维的矩阵  
forward() | 把取到的数据往前传递  
backward() | 数据输入层没有反向传播，所以直接pass  
load_image() | 将输入转化为caffe的标准输入数据  
load_label() | 加载输入数据对应的label，是一个二维的图  
  
### 2 第一个卷积阶段

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/ab81ba720f4a7c80a74a6d36f8851caec55e3bf47dee02aef60c1f02b5477b13)  

[ image ]

  * conv1_1: k=3,p=100(==为什么要设定这么大的padding？==)，s=1,则经过conv_1_1之后，，h的大小变为

    
    
    h_1_1 = (h-3+2*100)/1+1 = h+198
    

激活层不改变特征图的大小。

  * conv_1_2: k=3,p=1,s=1,经过conv_1_2之后，特征图的大小变为：
    
        h_1_2 = (h_1_1-3+2*1)/1+1 = h_1_1 = h+198
    

没有改变特征图的大小

  * pool1 ： k=2， s=2,则经过pool之后
    
        h_1 = (h_1_2-2)/2+1 = h_1_2/2 = (h+198)/2
    

特征图的大小变为输入图像的1/2

### 3 第二到第五个卷积阶段

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/5e122f1fed3b208bfed1d9b3317b7b5975d34b082ba28bb1cb1be9d97e98b732)  

[ image ]

  
第二到第五个阶段的卷积层k=3,p=1,s=1,根据公式

    
    
    h' = (h-3+2*1)/1+1 = h
    

卷基层并没有改变特征图的大小，所以特征图都是在每个卷积阶段的pooling层较小的。

  * pool2 k=2,s=2

    
    
    h_2 = (h_1-2)/2+1 = h_1/2 = (h+198)/2^2
    

  * pool3 k=2,s=2

    
    
    h_3 = (h_2-2)/2+1 = h_2/2 = (h+198)/2^3
    

  * pool4 k=2,s=2

    
    
    h_4 = (h_3-2)/2+1 = h_3/2 = (h+198)/2^4
    

  * pool5 k=2,s=2

    
    
    h_5 = (h_4-2)/2+1 = h_4/2 = (h+198)/2^5
    

即在第二到第五个卷积阶段，特征图分别为第一个卷积阶段之后的1/4,1/8,1/16,1/32.

### 4 fc6、fc7、score_fr(原全连接层，转化为卷积层)

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/ef55c965f8f48bb527e9f3e3606d1d67de5d6f2fe2e5c310a372382214d95367)  

[ image ]

  * fc6原为全连接层，经过卷积化之后变为卷积层，k=7，p=0,s=1,所以经过fc6之后，特征图的大小为

    
    
    h_6 = (h_5-7)/1+1 = (h+198)/32-7+1 = (h+6)/32
    

到这里就解释了为什么要在第一个卷积层设置padding=100，如果设为1，那么fc6之后特征图的大小变为(h-192)/32,那么h小于192的图像都无法处理。

  * fc7和score_fr的k=1，p=0,s=1,不改变特征图的大小。

### 5 upscore层（上采样）

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/2996af68e644519cb5aaa7dd6d6c2b2d39193dff458e3247dfae59d18d653509)  

[ image ]

> 反卷积就是卷积计算的逆过程

    
    
    h' = (h-k+2*p)/s+1
    ===>所以在做反卷积时，
    h = (h'+1)*s-2*p+k
    

所以经过upscore,k=64,s=32，特征图的大小变为

    
    
    h_u = (h_6+1)*32+64 = [(h+6)/32+1]*32+64 = h+38
    

可以看到，经过upscore的上采样之后，特征图的大小为
h+38,这显然与输入图像大小不一致，所以为了与输入图像大小一致，在upscore之后，又添加了一层score（Crop）层

### 6 score（Crop层）

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/33ab2452adfacba9a55dc77f0873846175b7ae8cc616bd1bd2756893e6ce5ff1)  

[ image ]

Crop层有两个输入，一个是要裁剪的特征图A，一个是作为参考的输入B。

> 很显然crop的作用就是参考B裁剪A

  * 参数axis=2,表明我们只想裁剪后两个维度，亦即输出尺寸
  * offset=19,对应于C = A[: , : , 19: 19+h , 19: 19+h ],这正是从(h+38,w+38)的upscore层中裁剪出中间的(h,h)的图像，这也就产生了和原图尺寸相同的最终输出！

### 总结

我们把voc-fcn32s网络的各层都进行了分析，其他的网络结构可以参考这个总结进行分析。

# 四、使用caffe进行fcn的训练

## 1 配置caffe-master环境

这篇总结主要介绍使用caffe框架来进行fcn的训练，[caffe](https://github.com/BVLC/caffe)里面包含了卷积层等各种网络层的实现。caffe框架使用比较简单，只需要在prototxt中以文本的形式定义好网络就可以进行训练，但配置比较麻烦，我在上篇总结中已经给出了完整的配置步骤。

## 2 下载fcn开源代码

github下载地址[https://github.com/shelhamer/fcn.berkeleyvision.org
](https://github.com/shelhamer/fcn.berkeleyvision.org)  
这是根据论文CVPR FCN实现的fcn模型和代码，兼容BVLC/caffe:master。下载下来之后，使用比较简单，无需配置和编译，只要满足以下条件：

  * 编译好的caffe；
  * 编译caffe的python接口，因为该fcn代码都是以python实现的；
  * 在编译caffe时
    
        将
    #WITH_PYTHON_LAYER := 1  
    修改为 
    WITH_PYTHON_LAYER := 1
    

因为该开源代码中使用了python来编写layer。

下载之后，直接解压就可以使用，其中有多个经典的fcn模型。  

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/170aba0a239302002fd66a7c4352aafd6b7191e38080823efca92ed38ecb9803)  

[ image ]

## 3 数据准备

### 1 训练集下载

因为train用的是SBDDdata，而val用的是voc中的data，所以要下载两套数据集

  * 下载训练集<http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/semantic_contours/benchmark.tgz>

在data文件夹下新建sbdd文件夹，将下载的dataset解压到该文件夹下

  * 下载测试集 <http://host.robots.ox.ac.uk/pascal/VOC/voc2012/>

将下载好的测试数据集在data/pascal文件下解压。

### 2 下载预训练模型

下载VGG-16的预训练模型放至/fcn.berkeleyvision.org/ilsvrc-
nets/目录下，并重命名为vgg16-fcn.caffemodel

下载地址 <http://dl.caffe.berkeleyvision.org/siftflow-fcn16s-heavy.caffemodel>

下载这个预训练模型的目的就是在训练时以该模型为基础进行fintune，而不用从头开始训练。

## 4 训练32s

在使用fcn进行图像语义分割时，需要进行三次训练，分别是对pool5后得到的特征图以32为步长进行上采样（32s）、对pool4之后得到的特征图以16为步长进行上采样（16s）和对pool3之后得到的特征图以8为步长进行上采样（8s）。首先进行32s的训练。

  1. 修改solve.py

  * 由于FCN代码和caffe代码是独立的文件夹，因此，须将caffe的Python接口加入到path中去。在solve.py中加入以下代码

    
    
    import sys
    sys.path.append('caffe根目录/python')
    # sys.path.append('/home/csy/caffe/python')
    

  * 设置weights为下载的vgg16-fcn.caffemodel路径
  * 设置solver和val的路径

    1. 由于 vgg16-fcn.caffemodel是cnn网络训练的参数，最后几层为全连接层，所以在32s训练中，需要需要一个转换，即在最后的由全连接层转换得到的卷积层，权重相同，只是shape不同。在solve.py文件中修改：

    
    
    #solver = caffe.SGDSolver('solver.prototxt')
    #solver.net.copy_from(weights)
    solver = caffe.SGDSolver('solver.prototxt')
    vgg_net = caffe.Net(vgg_proto, vgg_weights, caffe.TRAIN)
    surgery.transplant(solver.net, vgg_net)
    del vgg_net
    

原先的方法仅仅是从vgg-16模型中拷贝参数，但是并没有改造原先的网络，造成网络不收敛。可以看一下transplant函数的作用

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/aa9d1f5dc14f87eb737247591c4ff98b953d45d809aa95b6390667bf94dc1e38)  

[ image ]

  1. 将fcn文件夹中的surgery.py文件、voc_layers.py文件、voc_helper.py文件拷到voc-fcn32s文件夹中。
  2. 开始训练  
打开终端，cd到voc-fcn32s，开始训练

    
    
    sudo python solve.py
    

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/f6107fb2306d349917b34f82131dd7ba90352439ec37458c81a7417f88d8a476)  

[ image ]

  
如果报outofmemory错误，说明显卡大小不够，可以减小输入图像的大小或者增大显卡。也可以换成cpu计算模式。在solve.py中更改网络的计算模式为cpu

    
    
    #caffe.set_device(0)
    #caffe.set_mode_gpu()
    caffe.set_mode_cpu()
    

## 5 依次训练16s和8s

在训练好32s后之后，我们需要依次以32s训练得到的模型训练16s，以16s训练得到的模型训练8s，由于在16s和8s中，不需要全连接层到卷积层的转换，所以在solve.py中直接使用代码

    
    
    solver = caffe.SGDSolver('solver.prototxt')
    solver.net.copy_from(weights)
    

即可，不需要上述训练32s时使用transplant函数。

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/547936bbe45ae02f77021062b558eb59c1709852dd2748d3e0c552f7362e97ad)  

[ image ]

## 6 用训练好的模型测试图片

对于对单张图片，这个开源实现也提供了脚本利用训练好的模型对其进行语义分割，就是根目录下的infer.py，我们只需要更改其中的测试图片路径、训练好的模型路径就可以对测试图片进行分割。

    
    
    import numpy as np
    from PIL import Image
    
    import caffe
    
    # load image, switch to BGR, subtract mean, and make dims C x H x W for Caffe
    im = Image.open('pascal/VOC2010/JPEGImages/2007_000129.jpg')  #测试图片的路径，可以换成自己想要测试的图片路径
    in_ = np.array(im, dtype=np.float32)
    in_ = in_[:,:,::-1]
    in_ -= np.array((104.00698793,116.66876762,122.67891434))
    in_ = in_.transpose((2,0,1))
    
    # load net
    net = caffe.Net('voc-fcn8s/deploy.prototxt', 'voc-fcn8s/fcn8s-heavy-pascal.caffemodel', caffe.TEST)   #训练好的模型路径
    # shape for input (data blob is N x C x H x W), set data
    net.blobs['data'].reshape(1, *in_.shape)
    net.blobs['data'].data[...] = in_
    # run net and take argmax for prediction
    net.forward()
    out = net.blobs['score'].data[0].argmax(axis=0)
    

为了保存分割图像，添加几句代码

    
    
    plt.imshow(out, cmap='gray')
    plt.axis('off')
    plt.savaflg(test.jpg)
    

输入测试图像

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/7f4f1f5b0c738de3cfc54b0c40f72e490e4dfd522e8795e5b85d4b731996119b)  

[ image ]

分割后的图像

![](/image/quan_juan_ji_shen_jing_wang_luo_fcn_xue_xi_bi_ji/a61a43cb4121375b30cb15388041c2bce268d9b0dfabe3fcceba851cba450f21)  

[ image ]

### 可能存在的问题

  * 报错 no caffe module  
这是因为没有加入caffe的python路径，在import代码之间加入代码

    
    
    import sys
    sys.path.append('caffe根目录/python')
    

或者在在终端或者bashrc中将接口加入到PYTHONPATH中：

    
    
    export PYTHONPATH=caffe根目录/python:$PYTHONPATH
    

  * 缺少xx模块，解决方法就是缺少什么模块就sudo apt-get install xx
  * 没有训练好的模型。如果在训练好模型，先尝试一下分割效果，可以使用别人已经训练好的模型，在32s，16s，8s每个文件夹中，都有一个caffemodel-url文件，根据该文件中提供的url，就可以下载训练好的模型。

# 参考

  * <https://github.com/shelhamer/fcn.berkeleyvision.org>
  * <http://www.cnblogs.com/xuanxufeng/p/6243342.html>
  * <http://blog.csdn.net/supe_king/article/details/54142973>
  * <https://zhuanlan.zhihu.com/p/22976342>
  * <http://blog.csdn.net/wangkun1340378/article/details/70238290>
  * [FCN全卷积网络](http://www.cv-foundation.org/openaccess/content_cvpr_2015/html/Long_Fully_Convolutional_Networks_2015_CVPR_paper.html)
  * [FCN学习:Semantic Segmentation](https://zhuanlan.zhihu.com/p/22976342?utm_source=tuicool&utm_medium=referral)
  * <http://www.cnblogs.com/gujianhan/p/6030639.html>

