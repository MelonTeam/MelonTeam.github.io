---
layout: post
title: "深度学习入门实战（二）"
date: 2017-03-28 11:04:58
author: chaodong
categories: 机器学习
tags: tensorflow 机器学习
---
* content
{:toc}
> 导语：上一篇文章我们介绍了MxNet的安装，但MxNet有个缺点，那就是文档不太全，用起来可能是要看源代码才能理解某个方法的含义，所以今天我们就介绍一下TensorFlow，这个由谷歌爸爸出品的深度学习框架，文档比较全～以后的我们也都使用这个框架～

<!--more-->

## 0x00 概要

TensorFlow是谷歌爸爸出的一个开源机器学习框架，目前已被广泛应用，谷歌爸爸出品即使性能不是最强的（其实性能也不错），但绝对是用起来最方便的，毕竟谷歌有Jeff Dean坐镇，这波稳。


## 0x01 TensorFlow安装

官方有一个Mac上TensorFlow的安装指南，点[这里](https://www.tensorflow.org/install/install_mac)
我们现在就照着这个安装指南操作一把，官方推荐在virtualenv中安装TF，我们就在virtualenv安装吧，大家也可以直接安装。前几天TF发布1.0版了，我们就安装1.0版吧～

1.先安装下pip和six

```bash
$ sudo easy_install --upgrade pip
$ sudo easy_install --upgrade six 
```

2.安装下virtualenv

```bash
$ sudo pip install --upgrade virtualenv
```

3.接下来, 建立一个全新的 virtualenv 环境。这里将环境建在 ~/tensorflow目录下, 执行:

```bash
$ virtualenv --system-site-packages ~/tensorflow
$ cd ~/tensorflow
```

4.然后, 激活 virtualenv:

```bash
$ source bin/activate  # 如果使用 bash
$ source bin/activate.csh  # 如果使用 csh
```

(tensorflow)$ # 终端提示符应该发生变化
如果要退出虚拟环境可以执行

```bash
(tensorflow)$ deactivate
```

也可以直接在shell里执行下面的代码激活

```bash
source ~/tensorflow/bin/activate
```

5.在 virtualenv 内, 安装 TensorFlow:
因为我用的是Python 2.x所以执行

```bash
$ sudo pip install --upgrade  https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-1.0.0-py2-none-any.whl
```

要是使用Python3可以执行

```bash
 $ pip3 install --upgrade https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-1.0.0-py3-none-any.whl
```

当然也可以执行下面这个命令直接安装最新版

```bash
pip install --upgrade tensorflow
```

等命令执行完TF就安装好了

安装完成后可以在python中执行以下代码

```bash
import tensorflow as tf
hello = tf.constant('Hello, TensorFlow!')
sess = tf.Session()
print(sess.run(hello))
```

如果输出
Hello, TensorFlow!
就说明安装成功啦
PS:运行脚本的时候会提示不支持SSE xxx指令集的提示，这是因为我们是通过pip直接安装的编译好的版本导致的，如果想针对机器优化，可以直接从GitHub上的源代码编译安装。但这样会复杂些，而且我觉得其实提升不大，用CPU都很慢。。。不如直接上GPU性能提升快
PS2:如果想安装GPU版会复杂些，首先要有一块支持CUDA的N卡，再安装CUDA驱动啥的，各位看官可以谷歌一下查询相关资料。如果不想搜索，也可以看本系列后续文章，以后也会介绍如何在Mac下安装GPU版。

## 0x02 TensorFlow基本使用

在介绍样例之前，我们先介绍一下TensorFlow的一些基本概念

### 1.placehoder（占位符）

> tf.placeholder(dtype, shape=None, name=None)
  Args:
    dtype: The type of elements in the tensor to be fed.
    shape: The shape of the tensor to be fed (optional). If the shape is not specified, you can feed a tensor of any shape.
    name: A name for the operation (optional).

dytpe:占位符的数据类型
shape:占位符的纬度，例如[2,2]代表2x2的二维矩阵，None可以代表任意维度，例如[None,2]则代表任意行数，2列的二维矩阵
name:占位符的名字

变量在定义时要初始化，但可能有些变量我们一开始定义的时候并不一定知道该变量的值，只有当真正开始运行程序的时候才由外部输入，比如我们需要训练的数据，所以就用占位符来占个位置，告诉TensorFlow，等到真正运行的时候再通过输入数据赋值。
例如

```python
x = tf.placeholder(tf.float32, [2, 2])
```

就是生成了一个2x2的二维矩阵，矩阵中每个元素的类型都是tf.float32（也就是浮点型）
有时候定义需要训练的参数时候，会定义一个[input_size,output_size]大小的矩阵，其中input_size数输入数据的维度，output_size是输出数据的维度

### 2.Variable（变量）

官方说明 有些长，我就不引用啦，这里介绍一个简单的用法，有一点变量在声明的时候要有一个初始值

```python
x = tf.Variable(tf.zeros([2,2])) # 声明一个2x2的矩阵，并将矩阵中的所有元素的值赋为0，默认每个元素都是tf.float32类型的数据
y = tf.Variable(1.0, tf.float32) # 声明一个tf.float32的变量，并将初始值设为1.0
```

我们一般还需要运行下global_variables_initializer真正在TensorFlow的Session中初始化所有变量，后面的样例中也会有体现。

### 3.Constant（常量）

[官方说明](https://www.tensorflow.org/api_docs/python/tf/Variable) 同样不引用啦，这里介绍一个简单的用法

```python
x = tf.constant(3.0, tf.float32) # 定义一个值为3.0的浮点型常量
```

### 4.Session（会话）

TensorFlow所有的操作都必须在Session中运行，才能真正起作用，可以将Session当作TensorFlow运行的环境，Session运行完需要close～

```python
#用close()关闭
sess = tf.Session()
sess.run(...)
sess.close()

#使用with..as..语句关闭
with tf.Session() as sess:
    sess.run(...)
```

### 5.简单使用

我们介绍下3+5应该如何在TensorFlow中实现

```python
import tensorflow as tf

x = tf.Variable(3, tf.int16) // 声明一个整型变量3
y = tf.Variable(5, tf.int16) // 声明一个整型变量5
z = tf.add(x,y) // z = x + y
init = tf.global_variables_initializer() // 初始化变量的操作
with tf.Session() as sess:
    sess.run(init)  // 在Session中初始化变量
    print(sess.run(z)) // 输出计算出的z值
```

## 0x03 样例

Github上有一个比较好的[Demo合集](https://github.com/aymericdamien/TensorFlow-Examples)，有注释有源代码还蛮好的，但今天我们不讲上面的代码，我们讲如何用TF实现线性回归模型
所谓线性回归模型就是y = W * x + b的形式的表达式拟合的模型。
我们如果想通过深度学习拟合一条直线 y = 3 * x 应该怎么做呢？咱不讲虚的先展示下代码！然后我们在逐步分析。

```python
#coding=utf-8
import tensorflow as tf

x = tf.placeholder(tf.float32)
W = tf.Variable(tf.zeros([1]))
b = tf.Variable(tf.zeros([1]))
y_ = tf.placeholder(tf.float32)

y = W * x + b

lost = tf.reduce_mean(tf.square(y_-y))
optimizer = tf.train.GradientDescentOptimizer(0.0000001)
train_step = optimizer.minimize(lost)

sess = tf.Session()
init = tf.global_variables_initializer()
sess.run(init)

steps = 1000
for i in range(steps):
    xs = [i]
    ys = [3 * i]
    feed = { x: xs, y_: ys }
    sess.run(train_step, feed_dict=feed)
    if i % 100 == 0 :
        print("After %d iteration:" % i)
        print("W: %f" % sess.run(W))
        print("b: %f" % sess.run(b))
        print("lost: %f" % sess.run(lost, feed_dict=feed))
```

1.先导入需要使用的python库

```python
#coding=utf-8
import tensorflow as tf
```

毕竟是基于TensorFlow的，那我们肯定要导入TensorFlow滴，导入之后取个别名tf，之后用起来方便些。

2.定义需要的变量，我们看看y = W * x + b中都有哪些变量

```python
x = tf.placeholder(tf.float32)
W = tf.Variable(tf.zeros([1]))
b = tf.Variable(tf.zeros([1]))
y_ = tf.placeholder(tf.float32)
```

x：我们训练时需要输入的真实数据x
W: 我们需要训练的W，这里我们定义了一个1维的变量（其实吧，就是一个普普通通的数，直接用tf.float32也行）并将其初值赋为0
b : 我们需要训练的b，定义一个1维变量，并将其初值赋为0
y_ ：我们训练时需要输入的x对应的y

3.定义线性模型

```python
y = W * x + b
```

4.定义损失函数和优化方法

```python
lost = tf.reduce_mean(tf.square(y_-y))
optimizer = tf.train.GradientDescentOptimizer(0.0000001)
train_step = optimizer.minimize(lost)
lost = tf.reduce_mean(tf.square(y_- y))
```

损失函数(Lost Function)是用来评估我们预测的值和真实的值之间的差距是多少，损失函数有很多种写法，我们这里使用（y预测-y真实)^2再取平均数来作为我们的损失函数（用这个函数是有原因的，因为我们用的是梯度下降法进行学习）损失函数的值越小越好，有些教程也叫Cost Function

```python
optimizer = tf.train.GradientDescentOptimizer(0.0000001)
```

优化函数代表我们要通过什么方式去优化我们需要学习的值，这个例子里指的是W和b，优化函数的种类有很多，大家到[官网](https://www.tensorflow.org/api_guides/python/train)查阅，
平时我们用的比较多的是GradientDescentOptimizer和AdamOptimizer等，这里我们选用最常用也是最最基本的GradientDescentOptimizer（梯度下降），后面传入的值是学习效率。一般是一个小于1的数。越小收敛越慢，但并不是越大收敛越快哈，取值太大甚至可能不收敛了。。。
我们简单介绍下什么是梯度下降，梯度顾名思义就是函数某一点的导数，也就是该点的变化率。梯度下降则顾名思义就是沿梯度下降的方向求解极小值。
详细解释大家可以自行谷歌一下～当然可以可以看[这篇文章](http://blog.csdn.net/yhao2014/article/details/51554910)，当然由于性能的原因梯度下降有很多种变种，例如随机梯度下降 (Stochastic Gradient Descent)，小批梯度下降 (Mini-Batch Gradient Descent)。本文样例采用的是SGD，每次只输入一个数据。

```python
train_step = optimizer.minimize(lost)
```

这个代表我们每次训练迭代的目的，本例我们的目的就是尽量减小lost的值，也就是让损失函数的值尽量变小

5.变量初始化

```python
sess = tf.Session()
init = tf.global_variables_initializer()
sess.run(init)
```

这个之前有所介绍了，我们需要在Session中真正运行下global_variables_initializer才会真正初始化变量

6.开始训练

```python
steps = 1000
for i in range(steps):
    xs = [i]
    ys = [3 * i]
    feed = { x: xs, y_: ys }
    sess.run(train_step, feed_dict=feed)
    if i % 100 == 0 :
        print("After %d iteration:" % i)
        print("W: %f" % sess.run(W))
        print("b: %f" % sess.run(b))
        print("lost: %f" % sess.run(lost, feed_dict=feed))
```

我们定义一个训练迭代次数1000次
这里我们图方便，每次迭代都直接将i作为x，3*i作为y直接当成训练数据。
我们所有通过placeholder定义的值，在训练时我们都需要通过feed_dict来传入数据。
然后我们每隔100次迭代，输出一次训练结果，看看效果如何～

```python
After 0 iteration:
W: 0.000000
b: 0.000000
lost: 0.000000
After 100 iteration:
W: 0.196407
b: 0.002951
lost: 78599.671875
After 200 iteration:
W: 1.249361
b: 0.009867
lost: 122582.625000
After 300 iteration:
W: 2.513344
b: 0.015055
lost: 21310.636719
After 400 iteration:
W: 2.960238
b: 0.016392
lost: 252.449890
After 500 iteration:
W: 2.999347
b: 0.016484
lost: 0.096061
After 600 iteration:
W: 2.999971
b: 0.016485
lost: 0.000001
After 700 iteration:
W: 2.999975
b: 0.016485
lost: 0.000001
After 800 iteration:
W: 2.999978
b: 0.016485
lost: 0.000001
After 900 iteration:
W: 2.999981
b: 0.016485
lost: 0.000000
```

可以看到在迭代了500次之后效果就很好了，w已经达到2.999347很接近3了，b也达到了0.016484也比较接近0了，因为这里学习率选择的比较小，所以收敛的比较慢，各位也可以尝试调大学习率，看看收敛的速度有何变化。