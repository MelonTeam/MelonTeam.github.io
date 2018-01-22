---
layout: post
title: "如何得到幂法收敛的Markov转移矩阵"
date: 2017-10-30 22:44:00 +0800
categories: 未分类
author: raymondguo
tags: Markov PageRank
---

* content
{:toc}



[马尔科夫链](https://zh.wikipedia.org/wiki/%E9%A9%AC%E5%B0%94%E5%8F%AF%E5%A4%AB%E9%93%BE)被广泛的应用于预测模型中，而与马尔科夫链关联最紧密的概念就是[转移矩阵](https://zh.wikipedia.org/wiki/%E8%BD%89%E7%A7%BB%E7%9F%A9%E9%99%A3)了，转移矩阵可以通过数据统计计算得到，然而一般根据现实数据的样本得到的转移矩阵无法直接代入模型进行计算。譬如谷歌搜索的[PageRank](https://zh.wikipedia.org/wiki/%E4%BD%A9%E5%A5%87%E6%8E%92%E5%90%8D)算法，需要对转移矩阵反复迭代直至收敛。但在何种情况下可以得到收敛值呢，本文从基本的矩阵性质入手对这个问题进行分解。

关于如何使得转移矩阵能够收敛的问题搜索，  
<!--more-->
其中一部分是lecture性质的，比如[这个](http://www.math.chalmers.se/Stat/Grundutb/Chalmers/TMS081/oldpage/Lecture_notes/lecture3.pdf)，以及[yale的](http://www.stat.yale.edu/~pollard/Courses/251.spring2013/Handouts
/Chang-MarkovChains.pdf)

他们都在从特别数学的角度严谨的介绍了和markov稳态相关的makrov链的性质。每一个简洁的数学定理背后都是大量的概念及性质。可以作为详细的资料进行阅读，但是对于从工程角度迅速理解问题与解决问题，可能会消耗一些时间，特别是这几个材料阐释的角度还不太统一的情况下。

重新定义一下问题就是要得到一个某种适用于马尔科夫链的数据集对其求解特征向量：

  1. 对一个数据集进行统计
  2. 得到转移矩阵Trans
  3. 对这个转移矩阵使用幂法求特征向量

如何保证3中对Trans求特征向量(张量)可以有唯一解。或者说保证基于Trans的这样一个markov链有唯一稳态。

针对这样一个问题从更加工程或者是应用的角度对这样一个问题进行阐述，比较好的资料有:

  1. [这篇ams](http://www.ams.org/samplings/feature-column/fcarc-pagerank)数学和工程结合的很好，适合细读。特别难得的是这篇结合pagerank把markov链介绍的详略得当，本文探讨的如何保证收敛的问题也是马上给读者讲清楚了。
  2. 这篇[谷歌背后的数学-卢昌海](http://www.changhai.org/articles/technology/misc/google_math.php)中文博客写的也很好，博主的其他博文也很有意思。
  3. [这篇sjsu](http://www.cs.sjsu.edu/faculty/pollett/masters/Semesters/Fall11/tanmayee/Deliverable3.pdf)的slides也是非常简单明了，另外他们也有更详尽的[Handoff](http://scholarworks.sjsu.edu/cgi/viewcontent.cgi?article=7971&context=etd_theses).

## 1\. 收敛的条件

> Theorem [Basic Limit Theorem].  
> Let X0, X1, . . . be an irreducible, aperiodic Markov chain having a
stationary distribution π(·). Let X0 have the distribution π0, an arbitrary
initial distribution. Then limn→∞ πn(i) = π(i) for all states i.

来自[yale](http://www.stat.yale.edu/~pollard/Courses/251.spring2013/Handouts
/Chang-MarkovChains.pdf)这篇就说了，要想得到这么一个收敛的极值，要满足两个条件:

    
    
    1. irreducible
    2. aperiodic
    

分别来看看。

### 1.1 irreducible

上面yale这篇用了特别长的篇幅来介绍irreducible，这里，我觉得[这篇](http://www.math.chalmers.se/Stat/Grundutb/Chalmers/TMS081/oldpage/Lecture_notes/lecture3.pdf)里的解释更加简单明了:

> irreducible:  
> regardless the present state we can reach any other state in finite time.

这个其实就是之前学的图论里面的强连通图嘛

为什么要求这一点呢，上两个图示

![](/image/ru_he_de_dao_mi_fa_shou_lian_de_markov_zhuan_yi_ju_zhen/07f2112d06595653bee2463246f41e47a46fafdab090d1bcef3731ca6b425bea)

这两个都不是强连通图，即都不是irreducible

对这样一个markov
chain求稳态是不可行的，很直观的一种解释就是你知道一个Trans的特征向量的求得和初始值的取值肯定是没有关系的，然而对于非强连通图来说你要是选的初始状态不同，最后停留的状态也会不同，这显然是矛盾的。

因此收敛的条件之一就是markov chain必须是强连通图，那么他就是irreducible的。

### 1.2 aperiodic

看下面这样一个markov chain：

![](/image/ru_he_de_dao_mi_fa_shou_lian_de_markov_zhuan_yi_ju_zhen/84100a9e0bb41a87fdcab9e22819e9712e4b2305c1dc398e0ae885163712f3c7)

他是强连通图，即一定满足条件一irreducible，但他也没有稳态，为啥呢

还是放一个最简单的例子:

![](/image/ru_he_de_dao_mi_fa_shou_lian_de_markov_zhuan_yi_ju_zhen/4844b794d6b225106dc6e77e05563597daeba38eb9c2522bd01af1d7d5c349bc)

这样的一个markov chain 是强连通的，他的转移矩阵是  

![](/image/ru_he_de_dao_mi_fa_shou_lian_de_markov_zhuan_yi_ju_zhen/92828b56b805ea113f68010f7e4b6f24c7841296b09a7320f6030d30815d5f57)

然后你就会发现譬如你的初始值取得是(0,1)，那么下一步状态是(1,0)再下一步是(0,1)，，以此下去，其实就是永远在这两个状态之间来回震荡，根本谈不上什么极值了。

**至此，我们知道了，一个转移矩阵要是希望它能够运用到更广泛的预测模型中需要他满足irreducible和aperiodic两个条件**

**那么如何来使得我们通过统计得到的转移矩阵能够满足上两个条件从而可以收敛呢？**

## 2\. 对转移矩阵的操作使其满足收敛特性

前面是判断一个转移矩阵可以收敛的方法，而在建模过程中将统计得到的转移矩阵进行处理使其收敛的方法是什么呢？

处理的方法主要是吸取了这两篇:  
[amd](ttp://www.ams.org/samplings/feature-column/fcarc-
pagerank)的和[sjsu](http://www.cs.sjsu.edu/faculty/pollett/masters/Semesters/Fall11/tanmayee/Deliverable3.pdf)的这篇

在sjsu那篇里面这样对Trans处理的:

  1. Stochasticity adjustment (随机修正)
  2. Primitivity adjustment （素性修正）

这两个修正方法,用完第一个使得转移矩阵是Stochastic的，第二个使得Trans是Primitive的。

这里是围绕Stochastic和Primitive两个性质来进行处理的，不过着并不意味着前面的两个irreducible和aperiodic概念没有意义。

还是分别来看Stochastic和Primitive性质各代表什么：

### 2.1 Stochastic matrix

#### 2.1.1 Stochastic的定义

> A stochastic matrix describes a Markov chain $X_t$ over a finite state space
S.  
> If the probability of moving from i to j in one time step is
$Pr(j|i)=P_{i,j}$, the stochastic matrix P is given by using $P_{i,j}$ as the
$i^{th}$ row and $j_{th}$ column element.Since the total of transition
probability from a state i to all other states must be 1, this matrix is a
right stochastic matrix, so that
> Sum(P{i,j})=1
> 来自[维基](https://en.wikipedia.org/wiki/Stochastic_matrix)

这里的 right stochastic matrix就是指行加起来是1的矩阵  

![](/image/ru_he_de_dao_mi_fa_shou_lian_de_markov_zhuan_yi_ju_zhen/faf932f144adbf6223329bc15c2d79550bcecc9f75e6601d8a3f3b75b3880f37)

> A right stochastic matrix is a real square matrix, with each row summing to
1.  
> A left stochastic matrix is a real square matrix, with each column summing
to 1.

其实就是由markov 转移矩阵物理意义决定的从当前状态出发到其他状态的概率必须和为1。这里在转移矩阵中反映为列加起来为1.

#### 2.1.2 为什么要满足Stochastic

其实就是比如我们的转移矩阵Trans列到行是from->to，那么我们在统计的时候很有可能得到全0的列表示他不会再去往任何一个其他状态，他是一个黑洞点。
这样的黑洞点是我们不想看到的,
当然会发现其实这样的一个Trans不是irreducible的。现在先抛开irreducible，从这里提到的两个性质:stochastic和Primitive去处理Trans，

这里可以发现如果存在这样的黑洞点是不满足stochastic性质的( _如果我们设定列到行是from->to，那么Trans应该是一个left
stochastic矩阵，要满足列之和等于1_)

为什么黑洞结点对我们求极值有害呢?

这里结合pagerank 有这样一个解释:

> 因为任何一个 “悬挂网页” 都能象黑洞一样， 把其它网页的几率 “吸收” 到自己身上 (因为虚拟用户一旦进入那样的网页，
就会由于没有对外链接而永远停留在那里)， 这显然是不合理的。 这种不合理效应是如此显著，以至于在一个连通性良好的互联网上， 哪怕只有一个 “悬挂网页”，
也足以使整个互联网的网页排序失效， 可谓是 “一粒老鼠屎坏了一锅粥”。  
> [谷歌背后的数学-
卢昌海](http://www.changhai.org/articles/technology/misc/google_math.php)

#### 2.1.2 Stochastic adjustment

那么Stochasticity adjustment 是怎么做的呢:

> Mathematically, the stochastic matrix S is created from a rank one update to
H. S is given as,

    
    
        S= H + a(1/neT )
    
        where ai =1, if page i is a dangling node and, ai =0, otherwise
    

可以发现Stochasticity adjustment做的其实就是一件事:

    
    
    把列全为0的补成1/n,n是状态数
    

消灭了黑洞(进入原来的黑洞状态后可以有平均的机会进入其他状态包括自己)  
如此便得到了S矩阵，S矩阵有以下特性：

>  * S is a combination of the original hyperlink matrix H and a rank-one matrix 1/neT
  * S matrix alone cannot guarantee the convergence results.
  * For this reason, another adjustment called primitivity adjustment has been done to the page rank model.

总结关键就是S矩阵还不能保证转移矩阵是收敛的，必须还要用到 primitivity adjustment

### 2.2 Primitive matrix

前面说道了S矩阵还没办法保证转移矩阵是收敛的  
例子的话看这个:

![](/image/ru_he_de_dao_mi_fa_shou_lian_de_markov_zhuan_yi_ju_zhen/d9aa7e0129b5cd5b7a9d1ffb4b8cf3d4d2e1fd275e4d444b8ce07bcce0bae675)

如果把这个markov
chain写成转移矩阵的话可以发现并没有哪一列是和非1的，即这个转移矩阵肯定是stochastic的，但是他还是存在那种黑洞的性质，只是此时黑洞是由好多结点一起组成的没那么明显。

所以这里引入了第二个adjustment: Primitivity Adjustment

#### 2.2.1 Primitive的定义

> A matrix A is primitive if it is non-negative and its mth power is positive
for some natural number m (i.e. the same m works for all pairs of indices). It
can be proved that primitive matrices are the same as irreducible aperiodic
non-negative matrices.
> 来自[维基](https://en.wikipedia.org/wiki/Stochastic_matrix)

可以很清楚的发现原来这个primitive性质就是本文最开始描述的两个性质的组合：

    
    
    1. irreducible
    2. aperiodic
    

#### 2.2.2 为什么要保证Primitive

所以契合第一节内容，只要做完Primitive Adjustment就一定可以保证转移矩阵是irreducible和aperiodic即可以求得特征向量的。

所以可以说:

    
    
    Primitive matrix 一定是可以求得特征向量的
    

#### 2.2.3 Primitivity Adjustment

> Primitivity Adjustment  
> In this adjustment, Brin and Page introduced a new matrix G, called the
Google matrix.
     G=αS+(1-α)1/neeT
>where α is a scalar between 0 and 1.

我自己是这么理解Primitive adjustment这个操作的。

他让每个状态都多了n条路去所有状态，这样一来markov
chain肯定就是强连通图啦，也就达成了irreducible啦。同时因为任何一个状态有机会去任何一个状态，就不存在说在不断前进的过程中会有”震荡”的现象了。达成了aperiodic啦。

看到这里就有疑问了:  
既然primitive解决了所有问题，干嘛还要Stochasticity adjustment啊。  
当然要啊，要是列向量全为0，那么

    
    
    G=αS+(1-α)1/neeT 
    

得出来的列向量和不为1不满足物理意义啊，要进行Primitivity Adjustment首先一定要进行Stochasticity adjustment。

素性修正中的α的值影响着收敛速度和模型的精度。如何平衡这两点是工程应用中可以研究与探讨的点。

## 后记

  1. 学习本文最开始的lecture，虽然可以从更严谨的角度去理解问题，但可能需要耗费更多的时间，而从具体的模型或者图下手，可以更快的解决工程上的问题。
  2. 本文所描述的收敛问题是使用markov模型的一个小点。但是从小点入手进行细节的理解可以更高效的补充对整体模型的理解。

