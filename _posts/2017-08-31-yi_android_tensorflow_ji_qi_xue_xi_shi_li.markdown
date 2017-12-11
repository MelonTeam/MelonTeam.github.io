---
layout: post
title: "[译]Android TensorFlow机器学习示例"
date: 2017-08-31 20:25:00 +0800
categories: 未分类
author: jennyxia
tags: tensorflow 机器学习 Android
---

* content
{:toc}



原文地址：<https://blog.mindorks.com/android-tensorflow-machine-learning-example-
ff0e9b2654cc>

<!--more-->
###
![](/image/yi_android_tensorflow_ji_qi_xue_xi_shi_li/ddbbcacf495f4b2dee33840141469dfec7af4a3ef5eff22f4ff505a9d35d41a0)

### 机器学习：将Tensorflow集成到Android中

众所周知，Google已经开放了一个名为[TensorFlow](https://www.tensorflow.org/)的开源软件库，可以在Android中应用于机器学习。

我在网上搜索了很多，但没有找到一个简单的方法或一个简单的例子来构建TensorFlow for
Android。自己尝试了很久才构建好。于是我决定写下来，以节省他人时间。

分类器示例来自于Google TensorFlow示例。

本文适用于那些已经熟悉机器学习的人，并且了解如何使用机器学习的构建模型（本例中我将使用 pre-trained
的模型）。很快，我会写一系列关于机器学习的文章，以便每个人都可以学习如何建立机器学习模型。

### 1.Android的构建过程

几个重要的点，我们应该知道：

  * TensorFlow的核是用c ++编写的。
  * 为了构建android，我们必须使用JNI（Java Native Interface）来调用像LoadModel，getPredictions等c ++函数。
  * 我们将有一个.so（共享对象）文件，它是一个c ++编译的文件和一个jar文件，由一些调用native c ++的JAVA API组成。然后，我们将调用JAVA API来轻松完成任务。
  * 所以，我们需要jar（Java API）和.so（c ++编译）文件。
  * 我们必须具有pre-trained 的模型文件和分类的标签文件。

下图就是我们将要构建的一个物体识别程序。

![](/image/yi_android_tensorflow_ji_qi_xue_xi_shi_li/f0da7558ee38c63d52c3eff73623b3a1698459677ebc78726987153962a25a42)

#### 2.构建jar和.so文件

    
    
    git clone --recurse-submodules   <https://github.com/tensorflow/tensorflow.git>

注意：`--recurse-submodules`拉取submodules

从[这里](
downloads)下载NDK。[](
#ndk-12b-downloads)

下载Android SDK，或者我们可以提供Android Studio SDK的路径。

从[这里](https://bazel.build/versions/master/docs/install.html)安装Bazel。Bazel是TensorFlow的主要构建系统。[](https://bazel.build/versions/master/docs/install.html)

现在，编辑WORKSPACE文件，我们可以在之前克隆的TensorFlow的根目录中找到WORKSPACE文件。

    
    
    # Uncomment and update the paths in these entries to build the Android demo.  
    #android_sdk_repository(  
    #    name = "androidsdk",  
    #    api_level = 23,  
    #    build_tools_version = "25.0.1",  
    #    # Replace with path to Android SDK on your system  
    #    path = "",  
    #)  
    #  
    #android_ndk_repository(  
    #    name="androidndk",  
    #    path="",  
    #    api_level=14)

这样设置sdk和ndk路径：

    
    
    android_sdk_repository(  
        name = "androidsdk",  
        api_level = 23,  
        build_tools_version = "25.0.1",  
        # Replace with path to Android SDK on your system  
        path = "/Users/amitshekhar/Library/Android/sdk/",  
    )
    
    
    android_ndk_repository(  
        name="androidndk",  
        path="/Users/amitshekhar/Downloads/android-ndk-r13/",  
        api_level=14)

然后构建.so文件。

    
    
    bazel build -c opt //tensorflow/contrib/android:libtensorflow_inference.so \   
       --crosstool_top = // external：android / crosstool \   
       --host_crosstool_top = [@bazel_tools](http://twitter.com/bazel_tools "@bazel_tools的Twitter个人资料" ) // tools / cpp：toolchain \   
       --cpu = armeabi-v7a

替换我们所需的armeabi-v7a。

构建玩之后Tensorflow的库将位于：

    
    
    bazel-bin/tensorflow/contrib/android/libtensorflow_inference.so

构建Jar文件：

    
    
    bazel build // tensorflow / contrib / android：android_tensorflow_inference_java

我们可以在以下位置找到JAR文件：

    
    
    bazel-bin/tensorflow/contrib/android/libandroid_tensorflow_inference_java.jar

现在我们有jar和.so文件。我已经构建了.so文件和jar，可以直接从下面的项目中使用。

我创建了一个完整的运行示例应用程序[在这里](https://github.com/MindorksOpenSource/AndroidTensorFlowMachineLearningExample)。

#### 3.训练模型

我们需要预训练的模型和标签文件。

在这个例子中，我们将使用Google预训练的模型，该模型在给定图像上进行对象检测。

我们可以从[这里](

解压缩这个zip文件，我们将获得imagenet_comp_graph_label_strings.txt（对象的标签）和tensorflow_inception_graph.pb（预训练的模型）。

现在，在Android Studio中创建一个Android示例项目。

将imagenet_comp_graph_label_strings.txt和tensorflow_inception_graph.pb放入Assets文件夹。

将libandroid_tensorflow_inference_java.jar放在libs文件夹中，右键单击并添加为库。

    
    
    compile files('libs/libandroid_tensorflow_inference_java.jar')

在主目录中创建jniLibs文件夹，并将libtensorflow_inference.so放在jniLibs / armeabi-v7a /文件夹中。

现在，我们可以通过一个类`TensorFlowInferenceInterface，`调用TensorFlow Java API。

然后，我们可以输入图像来获得检测的结果。

感兴趣的可以直接克隆[项目](https://github.com/MindorksOpenSource/AndroidTensorFlowMachineLearningExample)，构建和运行，试试吧。

