---
layout: post
title: "机器学习入门系列05，classification: probabilistic generative model（分类：概率生成模型）"
date: 2017-04-04 22:24:00
categories: ios
author: yoferzhang
tag: 后验概率 最大似然...
---

* content
{:toc}


> 

引用课程：[http://speech.ee.ntu.edu.tw/~tlkagk/courses_ml16.html](http://speech.ee.ntu.edu.tw/~tlkagk/courses_ml16.html)



先看这里，可能由于你正在查看这个平台行间公式不支持很多的渲染，所以最好在我的csdn上查看，传送门：（无奈脸）

> 

csdn博客文章地址：[http://blog.csdn.net/zyq522376829/article/details/69216876](http://blog.csdn.net/zyq522376829/article/details/69216876)


<!--more-->


# <a name="classification 分类" class="reference-link"/>classification 分类

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/35ddf4ea91dc86c88e25f0ce51913d5a78788c197b31696f396e8b518dda4f75" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavpzbidfj20j605qt8w.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavpzbidfj20j605qt8w.jpg';}" alt=""/>

分类要找一个function，输入就是对象 xxx ，输出是这个对象属于n个类别的哪一个。

比如信用评分
- 输入：收入，储蓄，行业，年龄，金融史…- 输出：结果或者拒绝贷款
比如医疗诊断
- 输入：当前症状，年龄，性别，医疗史…- 输出：患了哪种疾病
比如手写文字辨识

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/25836644a04c9ebcf4d4cfd82cc68a2f5306a134cd85ae33711ef35ebcdf3c13" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavqj65ogj20fs054dg2.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavqj65ogj20fs054dg2.jpg';}" alt=""/>

# <a name="又是神奇宝贝举例" class="reference-link"/>又是神奇宝贝举例

## <a name="分类神奇宝贝" class="reference-link"/>分类神奇宝贝

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/185074b95909a113da9d922d50a6535a87fe36dafbaf599dc6fae80c7d51cdf6" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavr0enqmj213c0n64mn.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavr0enqmj213c0n64mn.jpg';}" alt=""/>

神奇宝贝有很多的属性，比如电，火，水。要做的就是一个分类的问题：需要找到一个function，输入一只神奇宝贝，输出它是什么属性。

## <a name="将神奇宝贝数值化" class="reference-link"/>将神奇宝贝数值化

比如皮卡丘
- total：整体强度，大概的表述神奇宝贝有多强，比如皮卡丘是320.- hp：生命值，比如皮卡丘35- attack：攻击力，比如皮卡丘55- defense：防御力，比如皮卡丘40- sp atk：特殊攻击力，比如皮卡丘50- sp def：特殊防御力，比如皮卡丘50- speed：速度，比如皮卡丘90
所以一只神奇宝贝可以用一个向量来表示，上述7个数字组成的向量。

需要预测是因为在战斗的时候会有属性相克，下面给了张表，只需要知道，战斗的时候遇到对面神奇宝贝的属性己方不知道的情况，会吃亏，所以需要预测它的属性。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/4a395cfc10ab982dfc7f3e45ec63c96a3105f63bdea3bb32962e1bdb1267a0ee" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavrgyqt1j213a0jo49j.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavrgyqt1j213a0jo49j.jpg';}" alt=""/>

## <a name="如何分类？" class="reference-link"/>如何分类？

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/03ee16cba725c05b98cc0924e50ac66730b750ff59e9ce8603a54dff9e5d613e" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavrxbar8j210a0ao79m.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavrxbar8j210a0ao79m.jpg';}" alt=""/>

### <a name="当作回归问题处理？" class="reference-link"/>当作回归问题处理？

假设还不了解怎么做，但之前已经学过了regression。就把分类当作回归硬解。举一个二分类的例子：

假设输入xxx 属于类别1，或者类别2，把这个当作回归问题：类别1就当作target是1，类别2就当作target是-1。训进行训练：因为是个数值，如果数值比较接近1，就当作类别1，如果数值接近-1，就当做类别2。这样做遇到什么问题？

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/cd0d463ea1c6ec119960c303778fed388ef28015255d026532d1d11e55643e57" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavsddomuj211m0kon28.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavsddomuj211m0kon28.jpg';}" alt=""/>

左边绿色的线是分界线，绿色线左边红色点就是-1的，绿色线右边蓝色点就是1的。但是如果训练集有很多的距离远大于1的点，比如有图右下角所示，这样用回归的方式硬训练可能会得到紫色的这条。直观上就是将绿色的线偏移一点到紫色的时候，就能让右下角的那部分的值不是那么大了。但实际是绿色的才是比较好的，用回归硬训练并不会得到好结果。此时可以得出用回归的方式定义，对于分类问题来说是不适用的。（penalize to the examples that are “too correct” …）

还有另外一个问题：比如多分类，类别1当作target1，类别2当作target2，类别3当作target3…如果这样做的话，就会认为类别2和类别3是比较接近的，认为它们是有某种关系的；认为类别1和类别2也是有某种关系的，比较接近的。但是实际上这种关系不存在，它们之间并不存在某种特殊的关系。这样是没有办法得到好的结果。

### <a name="ideal alternatives（理想替代品）" class="reference-link"/>ideal alternatives（理想替代品）

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/d2891c31b86001c1dfeec05735347f3bb0abd4961a9516cc1b597228d3380ba4" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavstgff2j21140g8dii.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feavstgff2j21140g8dii.jpg';}" alt=""/>

先看二分类，将function中内嵌一个函数g(x)g(x)g(x)，如果大于0，就认识是类别1，否则认为是类别2。损失函数的定义就是，如果选中某个funciton fff，在训练集上预测错误的次数。当然希望错误次数越小越好。

但是这样的损失函数没办法解，这种定义没办法微分。这是有方法的，比如perceptron（感知机），svm，这里先不讲这些。

# <a name="盒子抽球" class="reference-link"/>盒子抽球

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/75b721c1c1f51b8a297431b393c4e450bcfb7839dee0798e3843b502f8cc29d2" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazm3567vj21320d6mz4.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazm3567vj21320d6mz4.jpg';}" alt=""/>

假设两个盒子，各装了5个球，还得知随机抽一个球，抽到的是盒子1的球的概率是三分之二，是盒子2的球的概率是三分之一。从盒子中蓝色球和绿色球的分配可以得到：在盒子1中随机抽一个球，是蓝色的概率为五分之四，绿的的概率为五分之一，同理得到盒子2的信息。

现在求随机从两个盒子中抽一个球，抽到的是盒子1中蓝色球的概率是多少？（高中数学得：）

p(b1∣blue)=p(blue∣b1)p(b1)p(blue∣b1)p(b1)+p(blue∣b2)p(b2)p(b_{1} | blue) = \frac{p(blue | b_{1}) p(b_{1})}{p(blue | b_{1}) p(b_{1}) + p(blue | b_{2}) p(b_{2})}p(b​1​​∣blue)=​p(blue∣b​1​​)p(b​1​​)+p(blue∣b​2​​)p(b​2​​)​​p(blue∣b​1​​)p(b​1​​)​​

## <a name="抽球的概率和分类有什么关系？" class="reference-link"/>抽球的概率和分类有什么关系？

将上面两个盒子换成两个类别

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/0815590fea0e17b193c1e84de089ac37724445385af39ef8ec7aa48ca5a757f2" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazmmufl0j20zw0mutbp.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazmmufl0j20zw0mutbp.jpg';}" alt=""/>

同理知道红色方框的值，就可以计算出给一个x，它是属于哪个类型的，p(c1∣x)p(c_{1} | x)p(c​1​​∣x) 和 p(c2∣x)p(c_{2}| x)p(c​2​​∣x) ，谁大就属于谁。接下来就需要从训练集中估测红色方框中的值。

这一套想法叫做 generative model。因为有了这个model，就可以生成一个x，可以计算某个x出现的几率，知道了x的分布，就可以自己产生x。

> 

p(c1∣x)p(c_{1} | x)p(c​1​​∣x) 是由贝叶斯（bayes）公式得到的；p(x)是由全概率公式得到的，详情见《概率论与数理统计，浙江大学，第一章》。



### <a name="prior 先验" class="reference-link"/>prior 先验

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/6f10c82e83891b6a97ba9a612a0e1f7d5b308bab3cf6fc3ebfb13a0ff27b1454" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazpzoy04j21020m8gok.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazpzoy04j21020m8gok.jpg';}" alt=""/>

先考虑简单的二分类，水属性或者一般属性，通过训练集的数据可以计算出 $p(c**{1})$ 和 $p(c**{2})$。

下面想计算 p(x∣c1)p(x | c_{1})p(x∣c​1​​)

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/98fb3dfebf8a64d76e4c15a7136333c70481feabe2b5cea24392095a220011fe" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazqgcet5j212c0ksgvb.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazqgcet5j212c0ksgvb.jpg';}" alt=""/>

也就是在水系的神奇宝贝中随机选一只，是海龟的概率。下面将训练集中79个水系的神奇宝贝，属性defense 和 sp defense进行可视化

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/f3434e46a52cbde56d699bc5cf62b7b962c7920c92bd7b7cf4864ca22cb3cdd7" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazqxghmkj20yq0jkk1l.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazqxghmkj20yq0jkk1l.jpg';}" alt=""/>

这里假设这79点是从高斯分布（gaussian distribution）中得到的，现在需要从这79个点找出符合的那个高斯分布。

### <a name="高斯分布" class="reference-link"/>高斯分布

下面简单说一下高斯分布：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/8a98cd8d23b355975ec7dd6429481665f568d4b5b29b7b294bd0d579416a156f" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazrcrzcmj210y0qan91.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazrcrzcmj210y0qan91.jpg';}" alt=""/>

简单点可以把高斯分布当作一个function，输入就是一个向量xxx ，输出就是选中 xxx的概率（实际上高斯分布不等于概率，只是和概率成正比，这里简单说成概率）。function由期望 μ\muμ 和协方差矩阵Σ\sigmaΣ 决定。上图的例子是说同样的Σ\sigmaΣ，不同的 μ\muμ ，概率分布的最高点的位置是不同的。下图的例子是同样的  μ\muμ，不同的Σ\sigmaΣ，概率分布的最高点是一样的，但是离散度是不一样的。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/fc24bf11240a5df0c246fdfc03b2408c483ec6ebce4b9f78f51a6a4c7bec833d" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazrsad29j213c0gsna5.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazrsad29j213c0gsna5.jpg';}" alt=""/>

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/6995275c8bdda2e8797fc3857c2de9eb99e410f07179594597cf3e207da2963f" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazsae8nsj212a0n444d.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazsae8nsj212a0n444d.jpg';}" alt=""/>

假设通过79个点估测出了期望 $\mu$ 和协方差矩阵 Σ\sigmaΣ。期望是图中的黄色点，协方差矩阵是红色的范围。现在给一个不在79个点之内的新点，用刚才估测出的期望和协方差矩阵写出高斯分布的function fμ,Σ(x)f_{\mu,\sigma}(x)f​μ,Σ​​(x)，然后把x带进去，计算出被挑选出来的概率

### <a name="maximum likelihood（最大似然估计）" class="reference-link"/>maximum likelihood（最大似然估计）

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/29f861e97788883ae254e3f433e587660dceecc28bf77deb23214da46ed9d0b0" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazss6werj21340psdly.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazss6werj21340psdly.jpg';}" alt=""/>

首先对于这79个点，任意期望和协方差矩阵构成的高斯分布，都可以生成这些点。当然，像图中左边的高斯分布生成这些点，比右边高斯分布生成这些点的几率要大。那给一个μ\muμ 和 Σ\sigmaΣ，它生成这79个点的概率为图中的 l(μ,Σ)l(\mu, \sigma)l(μ,Σ)，l(μ,Σ)l(\mu, \sigma)l(μ,Σ)也称为样本的似然函数。

将使得  l(μ,Σ)l(\mu, \sigma)l(μ,Σ) 最大的 (μ,Σ)(\mu, \sigma)(μ,Σ) 记做 (μstar,Σstar)(\mu^{star}, \sigma^{star})(μ​star​​,Σ​star​​)，(μstar,Σ)(\mu^{star}, \sigma^{})(μ​star​​,Σ​​​)**就是所有  (μ,Σ)(\mu, \sigma)(μ,Σ) 的 <em>*maximum likelihood（最大似然估计）**</em>

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/d01f21d5ade8522edc7eee8e70bf7a14dbcce0a0f3515782f97d613e1effcec2" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazt9aa53j20y60fcq55.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazt9aa53j20y60fcq55.jpg';}" alt=""/>

这些解法很直接，直接对l(μ,Σ)l(\mu, \sigma)l(μ,Σ) 求两个偏微分，求偏微分是0的点。

> 

最大似然估计更多详情参看《概率论与数理统计，浙江大学，第七章》



### <a name="应用最大似然估计" class="reference-link"/>应用最大似然估计

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/35ae4e33a8c2b4568c2b8816ac1ec763d130566af7842fd80f0fcfe6b3ffddbb" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feaztqpbiej21340l2adz.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feaztqpbiej21340l2adz.jpg';}" alt=""/>

算出之前水属性和一般属性高斯分布的期望和协方差矩阵的最大似然估计值。

## <a name="开始分类" class="reference-link"/>开始分类

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/82118f34f71cd7180731a46e68c7b0fb5b04eec93ecbbda64a30f5312a67d87b" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazugug84j212g0miaeg.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazugug84j212g0miaeg.jpg';}" alt=""/>

上图看出我们已经得到了需要计算的值，可以进行分类了。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/6a3ba51c17a5e462b04a73e47a275aa86b0455ff75fbb49dc10c4d65ce50adcf" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazuwqfz3j213s0t6h0j.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazuwqfz3j213s0t6h0j.jpg';}" alt=""/>

左上角的图中蓝色点是水属性的神奇宝贝，红色点是一般属性的神奇宝贝，图中的颜色：越偏向红色代表是水属性的可能性越高，越偏向蓝色代表是水属性的可能性越低。

右上角在训练集上进行分类的结果，红色就是 p(c1∣x)p(c_{1} | x)p(c​1​​∣x) 大于0.5的部分，是属于类别1，相对蓝色属于类别2。右下角是放在测试集上进行分类的结果。结果是测试集上正确率只有 47% 。当然这里只处理了二维（两个属性）的情况，那在7维空间计算出最大释然估计值，此时μ\muμ是7维向量，Σ\sigmaΣ是7维矩阵。得到结果也只有54% 的正确率，so so。。。

## <a name="修改model" class="reference-link"/>修改model

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/06cddbd0853767c035c9e081ed67138ef7ced8b4061ca193d060e514943a5648" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazvdv026j212o0mwgq3.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazvdv026j212o0mwgq3.jpg';}" alt=""/>

通常来说，不会给每个高斯分布都计算出一套不同的最大似然估计，协方差矩阵是和输入feature大小的平方成正比，所以当feature很大的时候，协方差矩阵是可以增长很快的。此时考虑到model参数过多，容易overfitting，为了有效减少参数，给描述这两个类别的高斯分布相同的协方差矩阵。

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/83d6c72e1aab1c7c27102d2298b5e955b248e97f7cf33016ec4ac395335bd68e" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazvtk3ygj211e0lcwhm.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazvtk3ygj211e0lcwhm.jpg';}" alt=""/>

此时修改似然函数为 l(μ1,μ2,Σ)l(\mu^{1}, \mu^{2}, \sigma)l(μ​1​​,μ​2​​,Σ)。μ1,μ2\mu^{1}, \mu^{2}μ​1​​,μ​2​​ 计算方法和上面相同，分别加起来平均即可；而Σ\sigmaΣ的计算有所不同。

> 

这里详细的理论支持可以查看《pattern recognition and machine learning》christopher m. bishop 著，chapter4.2.2



<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/f3ab33561b047785892a0b95b82baa5bb23198c951a7ae055966f773097375e9" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazwax1qxj213q0mcdlz.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx2.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazwax1qxj213q0mcdlz.jpg';}" alt=""/>

右图新的结果，分类的boundary是线性的，所以也将这种分类叫做 linear model。如果考虑所有的属性，发现正确率提高到了73%。

# <a name="三大步" class="reference-link"/>三大步

将上述问题简化为前几个系列说过的三大步：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/911e7b9555c9db78d279bccbd614116a397e5639bb8d54c82e38419c9d2ea612" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazwrcjklj211i0koq6a.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazwrcjklj211i0koq6a.jpg';}" alt=""/>

实际做的就是要找一个概率分布模型，可以最大化产生data的likelihood。

# <a name="为什么是高斯分布？" class="reference-link"/>为什么是高斯分布？

可能选择其他分布也会问同样的问题。。。

有一种常见的假设

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/8012148ef614d26097adcba2066770dad9b253396c3008be575abc0ebeed66ae" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazxd86fhj20wg0huq5i.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx3.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazxd86fhj20wg0huq5i.jpg';}" alt=""/>

假设每一个维度用概率分布模型产生出来的几率是相互独立的，所以可以将 p(x∣c1)p(x | c_{1})p(x∣c​1​​) 拆解。

可以认为每个 p(xk∣c1)p(x_{k} | c_{1})p(x​k​​∣c​1​​) 产生的概率都符合一维的高斯分布，也就是此时p(x∣c1)p(x | c_{1})p(x∣c​1​​) 的高斯分布的协方差是对角型的（不是对角线的地方值都是0），这样就可以减少参数的量。但是试一下这种做法会坏掉。

对于二元分类来说，此时用通常不会用高斯分布，可以假设是符合 <strong>bernoulli distribution（伯努利分布）</strong>。

假设所有的feature都是相互独立产生的，这种分类叫做 <strong>naive bayes classifier（朴素贝叶斯分类器）</strong>

# <a name="posterior probability（后验概率）" class="reference-link"/>posterior probability（后验概率）

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/08932baf249e0081259203dcacfe17c041964ec62508f2fa92394d2f431701c2" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazxverh2j21160la41u.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazxverh2j21160la41u.jpg';}" alt=""/>

将 p(c1∣x)p(c_{1} | x)p(c​1​​∣x)整理，得到一个 σ(z)\sigma(z)σ(z)，这叫做sigmoid function。

接下来算一下zzz 长什么样子。

数学推导：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/a98ed19f3d404504e6fdc1e8edb3b8165e7b6e9773b06f52132177564571d05c" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazybj8nkj211e0lmq6l.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazybj8nkj211e0lmq6l.jpg';}" alt=""/>

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/b9011bc476ec85121391913d73ed123e376af6badede4b3f141cf9b57a1816f5" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazysexmwj213w0tagr6.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazysexmwj213w0tagr6.jpg';}" alt=""/>

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/10c38b2c824361708b31f20fa70ce802c37c61592eec59206a4e82719cad7422" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazz9c8vgj213u0smwj3.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx1.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazz9c8vgj213u0smwj3.jpg';}" alt=""/>

求得z，然后：

<img src="/image/ji_qi_xue_xi_ru_men_xi_lie_05_classification__probabilistic_generative_model__fen_lei___gai_lv_sheng_cheng_mo_xing__/8673014f2236d05e5639fa7170612b0327f57d462a500bf932fd7d5f052fbb26" onerror="if(!this.err){this.err=true;this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazztgikej213g0rs0x2.jpg';}else{this.onerror='';this.src='http%3a%2f%2fwx4.sinaimg.cn%2fmw690%2fa9c4d5f6gy1feazztgikej213g0rs0x2.jpg';}" alt=""/>

> 

这里用到简单的矩阵知识，比如转置，矩阵的逆，矩阵乘法。详情可参考《高等代数》or《线性代数》；喜欢代数的，推荐丘维声著的《高等代数》，分上下册，这本书是国内代数方面的翘楚，数学系的鄙人强烈推荐。别被抄来抄去的书害了—||



化简z，x的系数记做向量wtw^{t}w​t​​，后面3项结果都是标量，所以三个数字加起来记做bbb。最后p(c1∣x)=σ(w⋅x+b)p(c_{1} | x) = \sigma(w\cdot x + b)p(c​1​​∣x)=σ(w⋅x+b)。从这个式子也可以看出上述当共用协方差矩阵的时候，为什么分界线是线性的。

既然这里已经化简为上述的式子，直观感受就是可以估测n1,n2,μ1,μ2,Σn_{1}, n_{2}, \mu^{1}, \mu^{2}, \sigman​1​​,n​2​​,μ​1​​,μ​2​​,Σ，就可以直接得到结果了。下一篇讲述另外一种方法

> 

参考：《pattern recognition and machine learning》christopher m. bishop 著 chapter4.1 -4.2<br/>data:  [https://www.kaggle.com/abcsds/pokemon](https://www.kaggle.com/abcsds/pokemon)


