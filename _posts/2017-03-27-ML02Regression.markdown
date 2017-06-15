---
layout: post
title: "机器学习入门系列02，Regression 回归：案例研究"
date: 2017-03-27 10:02:44
categories: 机器学习
---
* content
{:toc}
> 引用课程：[http://speech.ee.ntu.edu.tw/~tlkagk/courses_ML16.html](http://speech.ee.ntu.edu.tw/~tlkagk/courses_ML16.html)


先看这里，可能由于你正在查看这个平台行间公式不支持很多的渲染，所以最好在我的CSDN上查看，传送门：（无奈脸）

> CSDN博客文章地址：[http://blog.csdn.net/zyq522376829/article/details/66577532](http://blog.csdn.net/zyq522376829/article/details/66577532)

# 为什么要先进行案例研究？

没有比较好的数学基础，直接接触深度学习会非常抽象，所以这里我们先通过一个预测 Pokemon Go 的 Combat Power (CP) 值的案例，打开深度学习的大门。


# Regression （回归）

<!--more-->

![](http://wx3.sinaimg.cn/mw690/a9c4d5f6gy1fe0me8ssa8j20zc0kcn5j.jpg)

## 应用举例（预测Pokemon Go 进化后的战斗力）

比如估计一只神奇宝贝进化后的 CP 值（战斗力）。
下面是一只妙蛙种子，可以进化为妙蛙草，现在的CP值是14，我们想估计进化后的CP值是多少；进化需要糖果，好处就是如果它进化后CP值不满意，那就不用浪费糖果来进化它了，可以选择性价比高的神奇宝贝。

![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mf7rxiij20xo0hgn53.jpg)

输入用了一些不同的 $x$ 来代表不同的属性，比如战斗力用 $x_{cp}$ 来表示，物种 $x_{s}$ 来表示…
输出就是进化后的CP值

### 三个步骤
上一篇提到了机器学习的三个步骤：
Step1.确定一组函数（Model）。
Step2.将训练集对函数集进行训练。
Step3.挑选出“最好”的函数 $f^{*}$ 
然后就可以使用 $f^{*}$ 来对新的测试集进行检测。

### Step1: Model
这个model 应该长什么样子呢，先写一个简单的：我们可以认为进化后的CP值 $y$ 等于进化前的CP值 $x_{cp}$ 乘以一个参数 $w$ 再加上一个参数 $b$ 。

$$
y = b + w \cdot x_{cp}   \qquad (1-1)
$$

$w$ 和 $b$ 是参数，可以是任何数值。

可以有
$$
f_{1}: y = 10.0 + 9.0 \cdot x_{cp}
$$

$$
f_{2}: y = 9.8 + 9.2 \cdot x_{cp}
$$

$$
f_{3}: y = -0.8 -1.2 \cdot x_{cp}
$$

这个函数集中可以有无限多的 function。所以我们用 $y = b + w \cdot x_{cp} $ 代表这些 function 所成的集合。还有比如上面的 $f_{3}$ ，明显是不正确的，因为CP值有个条件都是正的，那乘以 $-1.2$ 就变成负的了，所以我们接着就要根据训练集来找到，这个 function set 里面，哪个是合理的 function。

我们将式1-1 称作 Linear model， Linear model 形式为：

$$
y = b + \sum w_{i}x_{i}
$$

$x_{i}$ 就是神奇宝贝的各种不同的属性，身高、体重等等，我们将这些称之为 “feature（特征）”；$w_{i}$ 称为 weight（权重），b 称为 bias（偏差）。

### Step2: 方程的好坏
现在就需要搜集训练集，这里的数据集是 Supervised 的，所以需要 function 的输入和输出（数值），举例抓了一只杰尼龟，进化前的CP值为612，用 $x^{1}$ 代表这只杰尼龟进化前的CP值，即用上标标示一个完整对象的编号；进化后的CP值为 979，用 $\hat{y}^{1}$ 表示进化后的CP值，用 hat（字母头顶的上尖符号）来表示这是一个正确的值，是实际观察到function该有的输出。

下面我们来看真正的数据集（来源 Source: [https://www.openintro.org/stat/data/?data=pokemon](https://www.openintro.org/stat/data/?data=pokemon)）

![](http://wx1.sinaimg.cn/mw690/a9c4d5f6gy1fe0mfqcewwj211i0jiwhn.jpg)

来看10只神奇宝贝的真实数据，$x$ 轴代表进化前的CP值，$y$ 轴代表进化后的CP值。

有了训练集，为了评价 function 的好坏，我们需要定义一个新的函数，称为 **Loss function (损失函数)**，定义如下：

Loss function $L$ :

input: a function, output: how bad it is

Loss function是比较特别的函数，是函数的函数，因为它的输入是一个函数，而输出是表示输入的函数有多不好。 可以写成下面这种形式：

$$
L(f) = L(w, b)
$$

损失函数是由一组参数 w和b决定的，所以可以说损失函数是在衡量一组参数的好坏。

这里用比较常见的定义形式：

$$
L(f) = L(w, b) =\sum_{n=1}^{10}\left(\hat{y}^{n} -(b + w\cdot x_{cp}^{n})\right)^{2} \qquad   (1-2)
$$

将实际的数值 $\hat{y}^{n}$ 减去 估测的数值 $b + w\cdot x_{cp}^{n}$，然后再给平方，就是 Estimation error（估测误差，总偏差）；最后将估测误差加起来就是我们定义的损失函数。

这里不取各个偏差的代数和$\sum_{n=1}^{10}\hat{y}^{n} -(b + w\cdot x_{cp}^{n})$ 作为总偏差，这是因为这些偏差（$\hat{y}^{i} -(b + w\cdot x_{cp}^{i})$）本身有正有负，如果简单地取它们的代数和，就可能互相抵消，这是虽然偏差的代数和很小，却不能保证各个偏差都很小。所以按照式1-2，是这些偏差的平方和最小，就可以保证每一个偏差都很小。

为了更加直观，来对损失函数进行作图：

![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mg9bqyyj210o0o678o.jpg)

图上每个点都代表一个方程，比如红色的那个点代表 $y=-180-2\cdot x_{cp}$ 。颜色代表用这个点的方程得到的损失函数有多不好，颜色越偏红色，代表数值越大，越偏蓝色蓝色，代表方程越好。最好的方程就是图中叉叉标记的点。

### Step3：最好的方程

定好了损失函数，可以衡量每一个方程的好坏，接下来需要从函数集中挑选一个最好的方程。将这个过程数学化：

$$
f^{*}=\arg \min_{f} L(f) 
$$

$$
w^{*},b^{*} = \arg \min_{w,b} L(w,b)=\arg \min_{w,b} \sum_{n=1}^{10}\left(\hat{y}^{n} -(b + w\cdot x_{cp}^{n})\right)^{2} \qquad  (1-3)
$$

由于这里举例的特殊性，对于式1-3，直接使用最小二乘法即可解出最优的 w 和 b，使得总偏差最小。

>简单说一下**最小二乘法**，对于二元函数 $f(x,y)$，函数的极值点必为 $\frac{\partial f}{\partial x}$ 及$\frac{\partial f}{\partial y}$ 同时为零或至少有一个偏导数不存在的点；这是极值的必要条件。用这个极值条件可以解出w 和 b。（详情请参阅《数学分析，第三版下册，欧阳光中 等编》第十五章，第一节）

但这里会使用另外一种做法，**Gradient Descent（最速下降法）**，最速下降法不光能解决式1-3 这一种问题；实际上只要 $L$ 是可微分的，都可以用最速下降法来处理。

### Gradient Descent（梯度下降法）
简单来看一下梯度下降法的做法。

![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mgsxi8wj212i0ocjwj.jpg)

考虑只有一个参数 $w$ 的损失函数，随机的选取一个初始点，计算 $w = w^{0}$ 时 $L$ 对 $w$ 的微分，然后顺着切线下降的方向更改 $w$ 的值（因为这里是求极小值），即斜率为负，增加$w$ ；斜率为正，减小$w$ .

那么每次更改 $w$ ，更改多大，用 $\eta \frac{\mathrm{d}L}{\mathrm{d}w} |_{w=w^{0}}$ 表示，$\eta$ 被称为“learning rate”学习速率。

由于这里斜率是负的，所以是 $w^{0} - \eta \frac{\mathrm{d}L}{\mathrm{d}w} |_{w=w^{0}}$ ，得到 $w^{1}$；接着就是重复上述步骤。


![](http://wx3.sinaimg.cn/mw690/a9c4d5f6gy1fe0mh9cr4mj21220najwa.jpg)

直到找到一个点，这个点的斜率为0。但是例子中的情况会比较疑惑，这样的方法很可能找到的只是局部极值，并不是全局极值，但这是由于我们例子的原因，针对回归问题来说，是不存在局部极值的，只有全局极值。所以这个方法还是可以使用。

下面来看看两个参数的问题。


![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mhq93m2j210c0lg0w5.jpg)

两个参数的区别就是每次需要对两个参数求偏微分，然后同理更新参数的值。

>关于梯度可以参阅《数学分析，第三版下册，欧阳光中 等编》，第十四章第六节。也可以大概看看[百度百科](http://baike.baidu.com/link?url=zcPz3cjP_TPVZOHaLK49CD8CBSRJgD2ZyJ8fq9FOlqB6zX1NHw5p5ilA-CDTc87ujD3waWQygEnhPL7ERofrbI7AhRWLMDKTCtLXjbhFvve)又或者[wikipedia](https://en.wikipedia.org/wiki/Gradient)

将上述做法可视化：

![](http://wx1.sinaimg.cn/mw690/a9c4d5f6gy1fe0mi9ztuvj20y80maqnz.jpg)

同理梯度下降的缺陷如下图：

![](http://wx1.sinaimg.cn/mw690/a9c4d5f6gy1fe0mir5gsdj212c0lo7qj.jpg)

可能只是找到了局部极值，但是对于线性回归，可以保证所选取的损失函数式1-2是 convex（凸的，即只存在唯一极值）。上图右边就是损失函数的等高线图，可以看出是一圈一圈向内减小的。

## 结果怎么样呢？

将求出的结果绘图如下

![](http://wx3.sinaimg.cn/mw690/a9c4d5f6gy1fe0mmwc0tgj212m0l4tck.jpg)

可以计算出训练集上的偏差绝对值之和为 31.9

但真正关心的并不是在训练集上的偏差，而是Generalization的情况，就是需要在新的数据集（测试集）上来计算偏差。如下图：


![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mnf5r0uj212o0lmn22.jpg)

使用十个新的神奇宝贝的数据作为测试集计算出偏差绝对值之和为35.

接下来考虑是否能够做的更好，可能并不只是简单的直线，考虑其他model的情况：


![](http://wx4.sinaimg.cn/mw690/a9c4d5f6gy1fe0mnwbr3gj21360tgn32.jpg)

比如重新设计一个model，多一个二次项，来求出参数，得到Average Error为15.4，在训练集上看起来更好了。在测试集上得出的Average Error是18.4，确实是更好的Model。

再考虑三次项：


![](http://wx4.sinaimg.cn/mw690/a9c4d5f6gy1fe0moh17mgj213g0tsgs2.jpg)

得到的结果看起来和二次项时候的结果差别不大，稍微好一点点。也可以看到$w_{3}$已经非常小了，说明三次项影响已经不大了。

再考虑四次项：


![](http://wx3.sinaimg.cn/mw690/a9c4d5f6gy1fe0moxjsx4j21380to44a.jpg)

此时在训练集上可以做的更好，但是测试集的结果变差了。

再考虑五次项：


![](http://wx4.sinaimg.cn/mw690/a9c4d5f6gy1fe0mpebvrmj213c0twjx7.jpg)

可以看到测试集的结果非常差。

## Overfitting（过拟合，过度学习）

将训练集上的Average Error变化进行作图：


![](http://wx1.sinaimg.cn/mw690/a9c4d5f6gy1fe0mpwdlv6j212y0soafr.jpg)

可以看到训练集上的 Average Error 逐渐变小。

上面的那些model，高次项是包含低次项的function。理论上确实次幂越高越复杂的方程，可以让训练集的结果越低。但加上测试集的结果：


![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mqdlyzij212o0m6adw.jpg)

观察得出结果：虽然越复杂的model可以在训练集上得到更好的结果，但越复杂的model并不一定在测试集上有好的结果。这个结论叫做“**Overfitting（过拟合）**”。

如果此时要选model的话，最好的选择就是三次项式子的model。

>实际生活中典型的学驾照，学驾照的时候在驾校的训练集上人们可以做的很好，但上路之后真正的测试集就完全无法驾驭。这里只是举个训练集很好，而测试集结果很差的例子^_^

## 如果数据更多会怎样？

考虑60只神奇宝贝的数据


![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mqsw1iuj20y40ms7ff.jpg)

可以看出物种也是一个关键性的因素，只考虑进化前的CP值是太局限的，刚才的model就设计的不太好。

新的model如下


![](http://wx1.sinaimg.cn/mw690/a9c4d5f6gy1fe0mr9qf2mj20yo0joq51.jpg)

将这个model写成linear model的形式：


![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mrpzq6hj21bm0u0qof.jpg)

来看做出来的结果：


![](http://wx1.sinaimg.cn/mw690/a9c4d5f6gy1fe0ms6u00hj21020t6gs0.jpg)

不同种类的神奇宝贝用的参数不同，用颜色区分。此时model在训练集上可以做的更好，在测试集上的结果也是比之前的18.1更好。


## 还有其他因素的影响吗？

比如对身高，体重，生命值进行绘图：


![](http://wx4.sinaimg.cn/mw690/a9c4d5f6gy1fe0mspg7tjj213k0sgdkf.jpg)

重新设计model：



![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mt6esluj213c0m6788.jpg)

考虑上生命值（$x_{hp}$）、高度（$x_{h}$）、重量（$x_{w}$）

这么复杂的model，理论上训练集上可以得到更好的结果，实际为1.9，确实是更低。但是测试集的结果就过拟合了。

## Regularization（正则化）

对于上面那么多参数结果并不理想的情况，这里进行正则化处理，将之前的损失函数进行修改：

$$
y = b + \sum w_{i}x_{i}  \qquad  (1-4)
$$

$$
L(f) = L(w, b) =\sum_{n=1}^{10}\left(\hat{y}^{n} -(b + w\cdot x_{cp}^{n})\right)^{2} + \lambda \sum (w_{i})^{2} \qquad   (1-5)
$$

式1-5 中多加了一项： $\lambda \sum (w_{i})^{2}$ ，结论是$w_{i}$越小，则方程（式1-4）就越好。还可以说当 $w_{i}$ 越小，则方程越平滑。

平滑的意思是当输入变化时，输出对输入的变化不敏感。比如式1-5 中输入增加了 $\Delta x_{i}$ 则输入就增加了 $w_{i}\Delta x_{i}$ ，可以看出当$w_{i}$越小，输出变化越不明显。还比如测试集的输入有一些噪音数据，越平滑的方程就会受到更小的影响。


![](http://wx2.sinaimg.cn/mw690/a9c4d5f6gy1fe0mtp38ryj212g0smte8.jpg)

上图是对 $\lambda$进行调整得出的结果。当 $\lambda$ 越大的时候， $\lambda \sum (w_{i})^{2}$ 这一项的影响力越大，所以当$\lambda$  越大的时候，方程越平滑。

训练集上得到的结果是：当 $\lambda$ 越大的时候，在训练集上得到的Error 是越大的。这是合理的现象，因为当 $\lambda$ 越大的时候，就越倾向于考虑 $w$ 本身值，减少考虑error。但是测试集上得到的error 是先减小又增大的。这里喜欢比较平滑的function，因为上面讲到对于噪音数据有很好的鲁棒性，所以开始增加 $\lambda$ 的时候性能是越来越好；但是又不喜欢太平滑的function，最平滑的function就是一条水平线了，那就相当于什么都没有做，所以太平滑的function又会得到糟糕的结果。

 所以最后这件事情就是找到最合适的 $\lambda$ ，此时带进式1-5 求出$b$ 和 $w_{i}$，得到的function就是最优的function。

>对于Regularization 的时候，多加的一项：$\lambda \sum (w_{i})^{2}$，并没有考虑 $b$ ，是因为期望得到平滑的function，但bias这项并不影响平滑程度，它只是将function上下移动，跟function的平滑程度是没有关系的。

# 总结

- **Pokemon**：原始的CP值极大程度的决定了进化后的CP值，但可能还有其他的一些因素。
- **Gradient descent**：梯度下降的做法；后面会讲到它的理论依据和要点。
- **Overfitting**和**Regularization**：过拟合和正则化，主要介绍了表象；后面会讲到更多这方面的理论


> 新博客地址：[http://yoferzhang.com/post/20170326ML02Regression](http://yoferzhang.com/post/20170326ML02Regression)

