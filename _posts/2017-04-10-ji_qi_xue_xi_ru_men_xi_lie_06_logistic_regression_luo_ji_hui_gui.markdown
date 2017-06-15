---
layout: post
title: "机器学习入门系列06，logistic regression逻辑回归"
date: 2017-04-10 09:25:00
categories: ios
author: yoferzhang
tag: 判别方法 交叉熵
---

* content
{:toc}


> 

引用课程：[http://speech.ee.ntu.edu.tw/~tlkagk/courses_ml16.html](http://speech.ee.ntu.edu.tw/~tlkagk/courses_ml16.html)



先看这里，可能由于你正在查看这个平台行间公式不支持很多的渲染，所以最好在我的csdn上查看，传送门：（无奈脸）

> 

csdn博客文章地址：[http://blog.csdn.net/zyq522376829/article/details/69941886](http://blog.csdn.net/zyq522376829/article/details/69941886)


<!--more-->


# <a name="step1 逻辑回归的函数集" class="reference-link"/>step1 逻辑回归的函数集

上一篇讲到分类问题的解决方法，推导出函数集的形式为：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/705d4dca130a98d7daaa0f77e3fe3369f2a8449bf1b6a7ef159c1c40dda6e02a" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegtzgbqkqj20zm0lk77t.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegtzgbqkqj20zm0lk77t.jpg';}" alt=""/>

将函数集可视化：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/919cdee0bd7eca20194daf1e7521141a4c4bae7fa77ea3eec1a121fc6754196c" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegtzxnktpj213k0lyjuv.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegtzxnktpj213k0lyjuv.jpg';}" alt=""/>

图中z写错了，应该是 z=∑iwixi+bz = \sum_{i} w_{i} x_{i} + bz=∑​i​​w​i​​x​i​​+b。这种函数集的分类问题叫做 <strong>logistic regression（逻辑回归）</strong>，将它和第二篇讲到的线性回归简单对比一下函数集：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/79dba25ed0ed9c791d5cf6d7886a1bcfd4c5098689b2e45926e5999659526859" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu0gmykvj213o094gn8.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu0gmykvj213o094gn8.jpg';}" alt=""/>

# <a name="step2 定义损失函数" class="reference-link"/>step2 定义损失函数

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/2900afdd595cfabd8be3d0858662b100cee136f7cb8874514e86049779c28acb" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu1tsbvxj20sm06waad.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu1tsbvxj20sm06waad.jpg';}" alt=""/>

上图有一个训练集，每个对象分别对应属于哪个类型（例如 x3x^{3}x​3​​ 属于 c2c_{2}c​2​​ ）。假设这些数据都是由后验概率 fw,b(x)=pw,b(c1∣x)f_{w,b}(x) = p_{w, b}(c_{1} | x)f​w,b​​(x)=p​w,b​​(c​1​​∣x)产生的。

给定一组 w和b，就可以计算这组w，b下产生上图n个训练数据的概率，

l(w,b)=fw,b(x1)fw,b(x2)(1−fw,b(x3))⋯fw,b(xn)(1−1)l(w, b) = f_{w,b}(x^{1})f_{w,b}(x^{2}) \left( 1-f_{w,b}(x^{3}) \right) \cdots f_{w,b}(x^{n}) \qquad (1-1)l(w,b)=f​w,b​​(x​1​​)f​w,b​​(x​2​​)(1−f​w,b​​(x​3​​))⋯f​w,b​​(x​n​​)(1−1)

对于使得 l(w,b)l(w, b)l(w,b)最大的www和 bbb，记做wstarw^{star}w​star​​ 和 bstarb^{star}b​star​​ ，即：

wstar,bstar=argmaxw,bl(w,b)(1−2)w^{star},b^{star} = \arg \max_{w,b} l(w,b) \qquad (1-2)w​star​​,b​star​​=argmax​w,b​​l(w,b)(1−2)

将训练集数字化，并且将式1-2中求max通过取负自然对数转化为求min ：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/10cf1f7262bb76330c9a92e62a8bbde6aa230fd598bcaa42468948d287f38baf" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu2bunz0j21340sctcu.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu2bunz0j21340sctcu.jpg';}" alt=""/>

然后将−lnl(w,b)-\ln l(w,b)−lnl(w,b)改写为下图中带蓝色下划线式子的样子：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/fb9d61ef6c0003a1eba83a4af4e768eaf6fb623582ab7c7c21c3d7cd617dbb52" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu3jn47xj210u0modk3.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu3jn47xj210u0modk3.jpg';}" alt=""/>

图中蓝色下划线实际上代表的是两个伯努利分布（0-1分布，两点分布）的 <strong>cross entropy（交叉熵）</strong> 

假设有两个分布 p 和 q，如图中蓝色方框所示，这两个分布之间交叉熵的计算方式就是 h(p,q)h(p,q)h(p,q)；交叉熵代表的含义是这两个分布有多接近，如果两个分布是一模一样的话，那计算出的交叉熵就是0

> 

交叉熵的详细理论可以参考《information theory（信息论）》，具体哪本书我就不推荐了，由于学这门科目的时候用的是我们学校出版的教材。。。没有其他横向对比，不过这里用到的不复杂，一般教材都会讲到。



下面再拿逻辑回归和线性回归作比较，这次比较损失函数：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/7bc69dc0ffa797244f20af0e493fa3c9df14b190d251f62a0bb2d0b92ec86db1" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu40e5rlj213i0ow78j.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu40e5rlj213i0ow78j.jpg';}" alt=""/>

此时直观上的理解：如果把function的输出和target（真正的function y^n\hat{y}^{n}​y​^​​​n​​）都看作是两个伯努利分布，所做的事情就是希望这两个分布越接近越好。

# <a name="step3 寻找最好的function" class="reference-link"/>step3 寻找最好的function

下面用梯度下降法求：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/795d35b794c2cee04bb242a26cb0da8dea3f529cab763e9d725cd4d05ab09f0c" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu5y340zj212e0nudk4.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu5y340zj212e0nudk4.jpg';}" alt=""/>

要求−lnl(w,b)-\ln l(w,b)−lnl(w,b) 对 wiw_{i}w​i​​的偏微分，只需要先算出lnfw,b(xn)\ln f_{w,b}(x^{n})lnf​w,b​​(x​n​​) 对 wiw_{i}w​i​​的偏微分以及 ln(1−fw,b(xn))\ln \left( 1- f_{w,b}(x^{n}) \right) ln(1−f​w,b​​(x​n​​)) 对 wiw_{i}w​i​​的偏微分。计算lnfw,b(xn)\ln f_{w,b}(x^{n})lnf​w,b​​(x​n​​) 对 wiw_{i}w​i​​偏微分，fw,b(x)f_{w,b}(x)f​w,b​​(x)可以用σ(z)\sigma (z)σ(z)表示，而zzz可以用wiw_{i}w​i​​和 bbb表示，所以利用链式法则展开。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/3699e3073224908cdcd45a625a09c03ed84217612254636d97ea12b2751c0690" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu6e4kgqj212w0no0wo.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu6e4kgqj212w0no0wo.jpg';}" alt=""/>

计算 ln(1−fw,b(xn))\ln \left( 1- f_{w,b}(x^{n}) \right) ln(1−f​w,b​​(x​n​​)) 对 wiw_{i}w​i​​ 的偏微分，同理求得结果。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/1a66eaf56a92a809fa426a85bc16b544089e7da0b9c0b571139ba04494cfb88a" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu6ulmxhj212g0o6tcn.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu6ulmxhj212g0o6tcn.jpg';}" alt=""/>

将求得两个子项的偏微分带入，化简得到结果。

现在 wiw_{i}w​i​​ 的更新取决于学习率 η\etaη ，xinx^{n}_{i}x​i​n​​ 以及上图的紫色划线部分；紫色下划线部分直观上看就是真正的目标 y^n\hat{y}^{n}​y​^​​​n​​ 与我们的function差距有多大。

下面再拿逻辑回归和线性回归作比较，这次比较如果挑选最好的function：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/d3b91b6140b54f94623879e229ddc75957e09a1061b083d0307cbad83f6e8f01" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu7cc2owj213q0te79e.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu7cc2owj213q0te79e.jpg';}" alt=""/>

对于逻辑回归，target y^n\hat{y}^{n}​y​^​​​n​​ 是0或者1，输出是介于0和1之间。而线性回归的target可以是任何实数，输出也可以是任何值。

# <a name="为什么不学线性回归用平方误差？" class="reference-link"/>为什么不学线性回归用平方误差？

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/922de6c7d31ad5910c481b0ff949f5534eb9c6dea524f5775eccc34a032e23bb" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu7u3y64j211o0sgtdx.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu7u3y64j211o0sgtdx.jpg';}" alt=""/>

考虑上图中的平方误差形式。在step3计算出了对 wiw_{i}w​i​​ 的偏微分。假设 y^n=1\hat{y}^{n} = 1​y​^​​​n​​=1 ，如果 fw,b(xn)=1f_{w,b}(x^{n}) = 1f​w,b​​(x​n​​)=1，就是非常接近target，会导致偏微分中第一部分为0，从而偏微分为0；而 fw,b(xn)=0f_{w,b}(x^{n}) = 0f​w,b​​(x​n​​)=0，会导致第二部分为0，从而偏微分也是0。

对于两个参数的变化，对总的损失函数作图：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/d61bf201ebb9b9c10596b1825a3c30548b910104ed88f5815fb0bef52b84a29f" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu8ajigbj20x60kmn7x.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu8ajigbj20x60kmn7x.jpg';}" alt=""/>

如果是交叉熵，距离target越远，微分值就越大，就可以做到距离target越远，更新参数越快。而平方误差在距离target很远的时候，微分值非常小，会造成移动的速度非常慢，这就是很差的效果了。

# <a name="discriminative（判别）v.s. generative（生成）" class="reference-link"/>discriminative（判别）v.s. generative（生成）

逻辑回归的方法称为<strong>discriminative（判别）</strong> 方法；上一篇中用高斯来描述后验概率，称为 <strong>generative（生成）</strong> 方法。它们的函数集都是一样的：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/eb1824d607082e84f8869b321d53d73caabf56b5b9455c05d5d1827b6b8fa675" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu8si932j21160pqn0v.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu8si932j21160pqn0v.jpg';}" alt=""/>

如果是逻辑回归，就可以直接用梯度下降法找出w和b；如果是概率生成模型，像上篇那样求出 μ1\mu^{1}μ​1​​ ， μ2\mu^{2}μ​2​​ ，协方差矩阵的逆，然后就能算出w和b。

用逻辑回归和概率生成模型找出来的w和b是不一样的。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/93d723632f762e6edc16b4e6eee5ec5f145a23c9c90e55d63f87bb189bdeec10" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu98hriwj20zo0jcgpx.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu98hriwj20zo0jcgpx.jpg';}" alt=""/>

上图是前一篇的例子，图中画的是只考虑两个因素，如果考虑所有因素，结果是逻辑回归的效果好一些。

## <a name="一个好玩的例子" class="reference-link"/>一个好玩的例子

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/d6fec8d6f2bc99f0547eef27758a87203a6059506b0c6b658208a10742d11632" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu9otwf6j212a0kgju6.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegu9otwf6j212a0kgju6.jpg';}" alt=""/>

上图的训练集有13组数据，类别1里面两个特征都是1，剩下的(1, 0), (0, 1), (0, 0) 都认为是类别2；然后给一个测试数据(1, 1)，它是哪个类别呢？人类来判断的话，不出意外基本都认为是类别1。下面看一下朴素贝叶斯分类器（naive bayes）会有什么样的结果。

朴素贝叶斯分类器如图中公式：xxx属于cic_{i}c​i​​ 的概率等于每个特征属于cic_{i}c​i​​ 概率的乘积。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/85617f494e45fdca09db343da0d3417a8c31088326f4e8902f800f23f6ab85ff" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegua47345j213a0t0n1c.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegua47345j213a0t0n1c.jpg';}" alt=""/>

计算出p(c1∣x)p(c_{1} | x)p(c​1​​∣x)的结果是小于0.5的，即对于朴素贝叶斯分类器来说，测试数据 (1, 1)是属于类别2的，这和直观上的判断是相反的。其实这是合理，实际上训练集的数据量太小，但是对于 (1, 1)可能属于类别2这件事情，朴素贝叶斯分类器是有假设这种情况存在的（机器脑补这种可能性==）。所以结果和人类直观判断的结果不太一样。

## <a name="判别（discriminative）方法不一定比生成（generative）方法好" class="reference-link"/>判别（discriminative）方法不一定比生成（generative）方法好

生成方法的优势：
- 训练集数据量很小的情况；因为判别方法没有做任何假设，就是看着训练集来计算，训练集数量越来越大的时候，error会越小。而生成方法会自己脑补，受到数据量的影响比较小。- 对于噪声数据有更好的鲁棒性（robust）。- 先验和类相关的概率可以从不同的来源估计。比如语音识别，可能直观会认为现在的语音识别大都使用神经网络来进行处理，是判别方法，但事实上整个语音识别是 generative 的方法，dnn只是其中的一块而已；因为还是需要算一个先验概率，就是某句话被说出来的概率，而估计某句话被说出来的概率不需要声音数据，只需要爬很多的句子，就能计算某句话出现的几率。
# <a name="multi-class classification（多类别分类）" class="reference-link"/>multi-class classification（多类别分类）

## <a name="softmax" class="reference-link"/>softmax

下面看一下多类别分类问题的做法，具体原理可以参考《pattern recognition and machine learning》christopher m. bishop 著 ，p209-210

假设有3个类别，每个都有自己的weight和bias

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/f018040ca2793cf18f32d07689da576cf9cd4a86344aa9b071000bcd664bcb39" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegual9vb4j21300p8wio.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegual9vb4j21300p8wio.jpg';}" alt=""/>

把z1,z2,z3z_{1}, z_{2}, z_{3}z​1​​,z​2​​,z​3​​放到一个叫做softmax的方程中，softmax做的事情就是它们进行exponential（指数化），将exponential 的结果相加，再分别用 exponential 的结果除以相加的结果。原本z1,z2,z3z_{1}, z_{2}, z_{3}z​1​​,z​2​​,z​3​​可以是任何值，但做完softmax之后输出会被限制住，都介于0到1之间，并且和是1。softmax做事情就是对最大值进行强化。

把结果看成 

yi=p(ci∣x)=exp(zk)∑j=1nexp(zj)y_{i} = p(c_{i}|x) = \frac{\exp (z_{k})}{\sum^{n}_{j = 1}\exp (z_{j})}y​i​​=p(c​i​​∣x)=​∑​j=1​n​​exp(z​j​​)​​exp(z​k​​)​​

比如图中数字的例子，即输入x，属于类别1的几率是0.88，属于类别2的几率是0.12，属于类别3的几率是0。

softmax的输出就是用来估计后验概率（posterior probability）。为什么会这样？下面进行简单的说明：

## <a name="为什么softmax的输出可以用来估计后验概率？" class="reference-link"/>为什么softmax的输出可以用来估计后验概率？

假设有3个类别，这3个类别都是高斯分布，它们也共用同一个协方差矩阵，进行类似上一篇讲述的推导，就可以得到softmax。

信息论学科中有一个 <strong>maximum entropy（最大熵）</strong>的概念，也可以推导出softmax。简单说信息论中定义了一个最大熵。指数簇分布的最大熵等价于其指数形式的最大似然界。二项式的最大熵解等价于二项式指数形式(sigmoid)的最大似然，多项式分布的最大熵等价于多项式分布指数形式(softmax)的最大似然，因此为什么用sigmoid函数，那是因为指数簇分布最大熵的特性的必然性。假设分布求解最大熵，引入拉格朗日函数，求偏导数等于0，直接求出就是sigmoid函数形式。还有很多指数簇分布都有对应的最大似然界。而且，单个指数簇分布往往表达能力有限，就引入了多个指数簇分布的混合模型，比如高斯混合，引出了em算法。想lda就是多项式分布的混合模型。

> 

关于最大熵推导softmax有一篇论文讲的比较好：<the equivalence="" of="" logistic="" regression="" and="" maximum="" entropymodels="">。传送门：[http://www.win-vector.com/dfiles/logisticregressionmaxent.pdf](http://www.win-vector.com/dfiles/logisticregressionmaxent.pdf)。如果传送门失效，google一下就好。</the>



## <a name="定义target" class="reference-link"/>定义target

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/3cfed25d647af05985bc450c47b50fb74bce2ae1e2b60d9a7f704124a370f39c" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegub3mqjcj21280o4acs.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegub3mqjcj21280o4acs.jpg';}" alt=""/>

上一篇讲到如果定义类别1 y^=1\hat{y} = 1​y​^​​=1，类别2 y^=2\hat{y} = 2​y​^​​=2，类别3 y^=3\hat{y} = 3​y​^​​=3，这样会人为造成类别1 和类型2有一定的关系这种问题。但可以将 y^\hat{y}​y​^​​定义为矩阵，这样就避免了。而且为了计算交叉熵，y^\hat{y}​y​^​​也需要是个概率分布才可以。

# <a name="逻辑回归的限制" class="reference-link"/>逻辑回归的限制

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/9c84ca55ad8572427302e69c4dfac6835de3e75f688c5b95960461207efe78c8" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegubnf6lbj210y0n4gp1.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegubnf6lbj210y0n4gp1.jpg';}" alt=""/>

考虑上图的例子，两个类别分布在两个对角线两端，用逻辑回归可以处理吗？

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/a71fb74d098a55fc9d344beffcaa481258cd010d4f7ce75a406c7c757a3ac5ee" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feguc3pfwdj212a0nqwrr.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feguc3pfwdj212a0nqwrr.jpg';}" alt=""/>

这里的逻辑回归所能做的分界线就是一条直线，没有办法将红蓝色用一条直线分开。

## <a name="feature transformation（特征转换）" class="reference-link"/>feature transformation（特征转换）

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/c709d8af2ff696318ad6ea21d88dd41376f42ce625f5f50762227cbf8ac7280b" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegucj35y8j211w0n0diz.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegucj35y8j211w0n0diz.jpg';}" alt=""/>

特征转换的方式很多，举例类别1转化为某个点到 (0,0)(0, 0)(0,0) 点的距离，类别2转化为某个点到 (1,1)(1,1)(1,1) 点的距离。然后问题就转化右图，此时就可以处理了。但是实际中并不是总能轻易的找到好的特征转换的方法。

## <a name="cascading logistic regression models（级联逻辑回归模型）" class="reference-link"/>cascading logistic regression models（级联逻辑回归模型）

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/69a5313f4b05f7b5648bc2e27ac49da5ab73846d155d7feb6ddd93b9e06e0bc1" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegucxcuzzj211k0h4wgg.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegucxcuzzj211k0h4wgg.jpg';}" alt=""/>

可以将很多的逻辑回归接到一起，就可以进行特征转换。比如上图就用两个逻辑回归 z1z_{1}z​1​​和 z2z_{2}z​2​​来进行特征转换，然后对于 x1x_{1}x​1​​撇 和 x2x_{2}x​2​​撇（km上右上角打不出来一撇，单引号什么的都是失效），再用一个逻辑回归zzz来进行分类。

对上述例子用这种方式处理：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/43587afcb1eef92ed9534da74c96b964331dc665bf7353e0f495bab2507c4dea" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegudc72xmj213c0syqh5.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegudc72xmj213c0syqh5.jpg';}" alt=""/>

右上角的图，可以调整参数使得得出这四种情况。同理右下角也是

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/71f3828763c388f6073de0cdd7c87b3b15cc62928d40ad4bc586571e1811c129" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegudsjc2dj21260suh0k.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegudsjc2dj21260suh0k.jpg';}" alt=""/>

经过这样的转换之后，点就被处理为可以进行分类的结果。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_06_logistic_regression_luo_ji_hui_gui/12c326c635a696aff4718e23f4ab3c6b49106fa6c0006b508dacc9aa0992c0ee" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegue7og8mj21220rw152.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1fegue7og8mj21220rw152.jpg';}" alt=""/>

一个逻辑回归的输入可以来源于其他逻辑回归的输出，这个逻辑回归的输出也可以是其他逻辑回归的输入。把每个逻辑回归称为一个  <strong>neuron（神经元）</strong>，把这些神经元连接起来的网络，就叫做 <strong>neural network（神经网络）</strong>。
