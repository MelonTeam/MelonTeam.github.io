---
layout: post
title: "【译】关于深度神经网络必须知道的一些技巧（上）"
date: 2017-05-31 22:50:00 +0800
categories: 其他
author: cirolong
tags: 深度学习 网络训练技巧
---

* content
{:toc}



> 翻译自[魏秀参](http://lamda.nju.edu.cn/weixs/)博士的文章：[Must Know Tips/Tricks in Deep
Neural
Networks](http://lamda.nju.edu.cn/weixs/project/CNNTricks/CNNTricks.html)
<!--more-->

![tips/tricks](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/3b2fb8b5ae7ccd9c3cfe29a8aa4a7e82390eff8eaa2a1d2cf0a9f57fce97d6b1)
|
深度神经网络，特别是**卷积神经网络**（CNN），使得由许多处理层构成的计算模型能够完成对数据的多层抽象表示。它们已经非常显著地提高了计算机视觉诸多领域的现有水平，如物体识别，物体检测，文本识别等。并且还包括许多其他领域，如药物发现和基因研究。  
此外，在计算机视觉领域，目前已有许多优秀的论文发表，而且诞生了不少高质量的CNN开源软件和学习框架。同时也出现了许多不错的CNN教程和手册。然而，关于如何从零开始实现一个出色的深度卷积神经网络，目前可能还是缺少一个较新的、较全面的总结。因此，我们收集并总结了许多DCNNs的实现细节。**这里我们将介绍大量关于如何构建和训练神经网络的实现细节，也可以说是_技巧或秘诀_。**  
---|---  
  
## 前言

我们假设你已经掌握了基本的深度学习知识，并且我们这里介绍的实现细节（技巧）是关于深度神经网络的，尤指用于**图像相关任务**的卷积神经网络（CNN），主要包括以下**8个部分**：**1）**_数据扩增_；**2）**_数据预处理_；**3）**_网络初始化_；**4）**_训练过程中的一些技巧和注意事项_；**5）**_激活函数的选择_；**6）**_多种正则化方法_；**7）**_深刻理解训练图_；**8）**_组合多个网络_。  
另外，与本文对应的PPT在这里[[slide]](http://lamda.nju.edu.cn/weixs/slide/CNNTricks_slide.pdf)。如果关于这篇文章和PPT你有任何的疑问，或者发现了错误，或者还有其他重要的、有意思的东西你觉得应该加上，可以随时联系[我](http://lamda.nju.edu.cn/weixs/)。

## 1.数据扩增

因为深度网络需要使用大量的图片数据进行训练以达到满意的效果，如果原始的训练数据集数量较少，则应该对这些数据做一些扩增（Augmentation）来提高训练效果。其实，数据扩充已经成为了训练深度网络一个必不可少的步骤。

  * 数据扩增有许多方法，目前常用的有**水平翻转**，**随机剪裁**，**颜色抖动**。而且也可以尝试多种方式组合，比如同时对图像进行旋转和缩放。此外，可以调整一张图像中所有像素的饱和度和明度（饱和度S和明度V是指HSV色彩空间），调整方法具体是：先对S（或V值）进行幂运算，幂值在0.25~4之间，然后乘上一个0.7~1.4的系数，最后再加上一个-0.1~0.1的常数。这种方法同样适用于一个批（**batch**）大小里面的所有图像。也可以给色相（HSV色彩空间的H分量）加上1个-0.1~0.1的常数。
  * _**fancy PCA**_（Krizhevsky等人[[1]](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf)在2012年训练注明的_Alex-Net_时提出）。Fancy PCA在训练过程中改变了图像RGB通道的值。在实际使用中，首先对训练图像RGB像素值做PCA降维，然后对于每张训练图像的每一个像素点（即![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/19116195de0f96df04a218f36e606e6e6cbfab25e0de3ba6029e19314e7eadbf)），叠加上：![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/0e25bf16618ae60ea9751e09eea7fc421c8902cf651d959aa0dccfe169e677a6)，其中![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/643bd997cda5657301d338c95cd8530fd321960a13665623747deb5d02d24c91)和![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/132f06971d6ebc5d7ad011b2d148cd4908f0df2915d72fb0dd1e36270a6a6b10)分别是第i个特征向量和RGB像素值3x3协方差矩阵的特征值，![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/5ba270567ef14466100a07ff168367e254fa82b8878cd0367351bbcf4d1ddfaa)是服从高斯分布（均值为0，标准差为0.1）的随机数。每个![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/5ba270567ef14466100a07ff168367e254fa82b8878cd0367351bbcf4d1ddfaa)对于一张训练图像的所有像素点只初始化一次，直到这张图像再次用于训练。也就是说，当训练模型再次遇到同一张图像时，它会随机产生一个新的![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/5ba270567ef14466100a07ff168367e254fa82b8878cd0367351bbcf4d1ddfaa)用于数据扩增。在[[1]](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf)中指出，fancy PCA可以近似地提取出图像中的重要信息，也就是说对色彩饱和度变化以及光照具有不变性。在分类性能上，这种方法在ImageNet 2012比赛中将top1错误降低了1%。

## 2.数据预处理

现在我们手上已经有了大量的训练数据了，不过可千万别着急！我们需要对这些数据做一下预处理。在这个章节我们将介绍几种预处理的方法。

第一种简单的处理方法就是对数据进行**零中心化**（zero-center），然后进行**归一化**（normalize）。使用Python代码表示如下：

    
    
    >>> X -= np.mean(X, axis = 0) # zero-center
    
    >>> X /= np.std(X, axis = 0) # normalize

其中X是输入数据。另一种方式是对每一个维度的数据进行归一化，使得最小值和最大值分别为-
1和1。如果不同的输入特征具有不同的尺度，但它们对学习算法的影响效果大致相等，这样进行数据预处理才有意义。对于图像而言，像素的相对尺度是差不多相同的（在0~255之间），所以预处理操作也不是十分必须的。

另外一种方法跟第一种方法差不多，叫做**PCA白化**（PCA
Whitening）。首先同样是对数据进行零中心化，然后计算协方差，它展示了数据中的相关性结构：

    
    
    >>> X -= np.mean(X, axis = 0) # zero-center
    
    >>> cov = np.dot(X.T, X) / X.shape[0] # compute the covariance matrix

之后，把原始数据（已经零中心化）投射（projecting）到特征向量上进行去相关操作：

    
    
    >>> U,S,V = np.linalg.svd(cov) # compute the SVD factorization of the data covariance matrix
    
    >>> Xrot = np.dot(X, U) # decorrelate the data

最后一步就是白化操作，将上一个步骤得到的结果除以特征值：

    
    
    >>> Xwhite = Xrot / np.sqrt(S + 1e-5) # divide by the eigenvalues (which are square roots of the singular values)

这里加上1e-5（一个很小的常量）是为了防止除0。这一步变换有个缺点是它会极度放大数据中的噪声，因为输入数据的所有维度（包括方差很小的不相关维度，绝大部分是噪声）变成了同等大小。可以通过增大平滑参数来减小噪声影响
（比如把1e-5再增大一点）。

值得注意的是，这里提到预处理操作是为了介绍的完整性。在卷积神经网络中，一般不采用预处理操作。但是零中心化和归一化还是十分必要的。

## 3.网络初始化

现在数据已经准备好了。但是在开始训练网络之前，必须对网络的参数进行初始化。

**全零初始化**

对数据进行适当的归一化后，理想的情况是希望权值（weights）初始化约为一半正数一半负数。一个听起来蛮合理的方案就是将权值全部初始化为0，因为从期望上来讲，0是最佳猜测。但事实上证明这样做是错误的，因为如果每个神经元具有同样的输出，那么在反向传播
（back-
propagation）时就会计算得到同样的梯度值，参数的更新也就完全一样。换句话说，若权值初始化时都为同样的值，那么网络的各个神经元之间就缺少了不对称性。

**随机初始化为较小的值**

权值初始化为接近于0的值，但不完全等于0。每个权值都随机初始化为非常接近于0的值，这样就打破了网络的对称性（symmetry
breaking）。在训练的开始阶段，所有神经元都是随机且唯一的，然后它们将进行不同的更新，成为整个网络不同的一部分。这种初始化方式很简单：![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/d4ea91df622e81009f944af558c37b7815df91cd8124511ce13418d5097a5b05)，其中![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/c81827e6d93eb90b5cd345b3e06e2f30031f6f45ace61d761915636fd6917876)是均值为0，标准差为1的高斯分布。也可以使用服从均匀分布的较小值，但实际训练中发现其对最终训练结果的影响要小一些。

**校正方差**

上述随机初始化权值的方法存在一个问题，随着输入数据的增加，输出的方差也会增加。可以用随机初始化权值除以输入数据大小的开方，使得每个神经元输出的方差变为1，如下所示：

    
    
    >>> w = np.random.randn(n) / sqrt(n) # calibrating the variances with 1/sqrt(n)

其中“randn”是产生高斯分布的函数，“n”表示输入数据的大小。这样使得网络中所有神经元在训练开始的时候具有大致相同的输出分布，实验也证明这会提高收敛速度。详细的推导过程可见PPT的18~23页，要说明的是，这个推导并没有考虑ReLU（修正线性单元，见第5章节）的影响。

**推荐方法**

上述校正方差的方法并未考虑ReLU的影响。最近He等人[[4]](https://arxiv.org/abs/1502.01852)提出了一种专为ReLU设计的初始化权值方法，得出的结论是：网络中神经元的方差应为![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/2a2cf2926658204cef6572153f448cd041754c45dd1e97e73882d61e3caad8a1)。

    
    
    >>> w = np.random.randn(n) * sqrt(2.0/n) # current recommendation

如[[4]](https://arxiv.org/abs/1502.01852)中的讨论，这也是当前推荐在实际中使用的方法。

## 4.训练过程

现在所有的准备工作都做好了，让我们开始训练网络吧！

  * **卷积核和池化的大小。**训练过程中，输入图像的大小最好为2的幂，比如32（CIFAR-10），64，244（通常在ImageNet中使用），384或者512。另外采用较小的卷积核（比如3x3）和较小的滑动步长（比如1）并进行补0操作（zeros-padding）是比较重要的，这样不仅能够减少参数的个数，而且能够提高整个网络的准确率。同时，上面提到的3x3卷积核大小和滑动步长为1的组合用例，能够使得输入图像/输出特征保持大小一致（比如(32-3+2*1)/1+1=32）。对于池化层，池化大小通常为2x2。
  * **学习速率。**如Ilya Sutskever在其博客[[2]](http://yyue.blogspot.sg/2015/01/a-brief-overview-of-deep-learning.html/)中所述，他建议将梯度值除以mini批大小（mini-batch size）。因此，如果在训练过程中改变了批大小，就不必要一直改变学习速率（LR）。为了得到一个合适的LR，可以使用验证集。通常，在训练开始的时候采用的LR为0.1。在实际训练过程中，若发现当前使用的LR在验证集上损失（loss）不再下降，可以尝试将LR除以2（或者5），再继续进行训练，会有惊喜发生。
  * **预训练模型调优（fine-tune）。**目前，许多预训练好的模型被一些著名的研究团队公布，如[_Caffe Model Zoo_](https://github.com/BVLC/caffe/wiki/Model-Zoo)和[_VGG Group_](http://www.vlfeat.org/matconvnet/pretrained/)。得益于这些预训练模型良好的泛化能力，可以直接拿来使用到自己的应用中。为了进一步提高这些模型在自己的训练集上的分类效果，一个简单有效的方法便是在自己数据集上对这些预训练模型进行调优（fine-tuning）。如下表所示，两个重要的因素：新数据集的大小，以及它与原始数据集之间的相似度。不同的情况应采用不同的调优策略。举例说明，比如你的数据集与预训练模型采用的训练数据集非常相似，在此情况下，若自己的数据集较小，只要在预训练模型最顶层输出特征上再训练一个线性分类器即可；若自己的数据集较大，可以使用一个较小的学习速率对预训练模型的最后几个顶层进行调优。如果自己的数据集与预训练模型采用的训练数据集相差较大但拥有足够多的数据，在这种情况下则需要对网络的多个层进行调优，同样也要使用较小的学习速率。还有一种情况是，自己的数据集不仅较小，而且与原始数据集相差较大，那这个就比较麻烦了。因为数据集较小，所以最好只训练一个线性分类器；因为数据差异很大，所以只对网络的最后几个顶层调优并不是很好的方案，因为这几个层包含了更多数据相关（dataset-specific）的特征。针对此种情况，在网络较为靠前的特征层就使用SVM分类器可能是相对而言较好的方案。

![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/b8731d3bee28daa6feac3b714c21b23442941e83a50d0d2668d37d6cb43a042c)
| 在自己的数据集上调优（fine-tune）预训练模型。不同情况下采用不同的调优策略。对于数据集，_Caltech-
101_与_ImageNet_比较相似，都是关于物体的数据集；而_Place Database_就与_ImageNet_不同，它是关于场景的数据集。  
---|---  
  
## 5.激活函数

激活函数（_activation
function_）是深度网络几个重要特点之一，它使得网络具有**非线性**表达能力。这里将介绍几种常用的激活函数，然后提出一些使用建议。

![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/9b00674a43c412f4c71096be85c5b04acddab4316319df366ec0d0bc36b2d0aa)
| 图片来自[Stanford CS231n](http://cs231n.stanford.edu/index.html)  
---|---  
  
**Sigmoid**

![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/f91b746fb6bb4a823d9d40905b13b124f292f5054c71ead130863a5a5dd3b131)
|
**sigmoid**非线性函数：![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/b1d849c9cd4d3fd8d4206184c8523b45283303ec77e9d7a9e9f007e2d115f4df)  
它将实数“压扁”在0~1之间，正无穷趋向于1，负无穷趋向于0。sigmoid函数过去经常被使用，因为它很好地模拟了神经元的激活状态：从根本不被激活（0）到完全被激活（1）。  
---|---  
  
在实际使用中，已经很少采用sigmoid函数，因为它有两个主要的缺点：

  1. _sigmoid函数容易饱和梯度，并终止梯度传递。_sigmoid函数有个不太好的特性，就是当神经元的激活值饱和在0或1的“小尾巴”处时（见sigmoid函数图），这些区域的梯度值为0。在反向传播的过程中，这个（局部）梯度将会与整个损失函数关于该门单元（gate）输出的梯度相乘。因此，如果局部梯度的值非常小，它会“杀死”梯度，这样几乎就没有信号通过神经元传到权值并传到数据了。此外，为了防止梯度饱和，在初始化权值的时候需要特别注意。比如，若初始化权值过大，那么大多数神经元将会饱和，导致网络几乎失去学习能力。
  2. _sigmoid函数的输出不是零中心化的（zero-centered）。_这个特性也是不合需要的，因为网络中较后层的神经元将会收到非零中心化的数据。这将会影响梯度下降的过程，因为如果某个神经元的数据数据总是正数（如![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/bebc09d7435173fc01dfcce9cfb3e5d8bb040b2e48f5c798eb107c00ec8b2e6a)中每个![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/40e168d862e6aa15209cdc2e0b5409e4acf20b182207eac81e8be90ad3db9347)）,那么权值![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/e08ed330c60c62a31f37cb5b346a9d780a6cb432f51afb0049cdaa587d3847f2)的梯度在反向传播的过程中，要么全部为正数，要么全部为负数（具体依整个表达式![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/2838d04adc4c010fbae98fe241ee501fd7a4606c49c4d9f62ebeaa20d8cd8aec)的梯度而定）。这样在权值梯度更新的时候就会出现“Z字形”锯齿。然而，当一个批大小（batch）里面数据的梯度叠加起来以后，一定程度上会缓解这个问题，因为一个批大小里面的梯度值有正有负。因此，这个缺点相比于上面的饱和梯度问题来说，只是个小麻烦，没有那么严重。

**tanh(x)**

![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/241941065f7227daea65b652604a7668ee2aec868fc5b53102efeaedfde25978)
|
**tanh**非线性函数将实数“压扁”在[-1,1]之间，和sigmoid函数一样，它也存在饱和梯度的问题，但不同的是它的输出是零中心化的。因此，在实际使用中，tanh非线性函数比sigmoid非线性函数要用得多一些。  
---|---  
  
**Rectified Linear Unit**

![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/5df676dd3728c049c3a460722e9236ea5221871ea7ea3d45acedc401b6a6bae4)
| **修正线性单元**（Rectified Linear
Unit,ReLU）近年来非常受欢迎。其函数公式：![](/image/yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/29be7f833bb9ceb75f1a4af51dacc25fbe58d1eb5acd266d5965ec35444fcd92)  
---|---  
  
ReLU有以下优缺点：

  1. （_优点_）相比于sigmoid/tanh包含复杂的运算（如指数运算），ReLU只需要对矩阵进行简单的阈值计算（与0比较）得到。此外，ReLU没有饱和梯度的问题。
  2. （_优点_）与sigmoid/tanh相比，ReLU极大加速了梯度下降的收敛过程（[[1]](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf)中指出有加速6倍之多）。可以认为这是得益于ReLU线性、非饱和的特点。
  3. （_缺点_）不过，ReLU在训练过程中比较脆弱并且可能“死掉”。举例来说，当一个很大的梯度值经过ReLU神经元，可能当权值更新后，神经元将再也无法被其他任何数据激活。若这种情况发生，那么从此所有经过这个神经元的梯度都将变成0。也就是说，这个ReLU单元将在训练过程中不可逆转地死亡，因为它减少了数据的多样性。如果学习速率设置过高，可能会发现网络中40%的神经元都会死掉（即对于整个训练集，这些神经元都不会被激活）。通过设置合适的学习速率，可以降低这种情况发生的概率。

* * *

### 马上会更新《【译】关于深度神经网络必须知道的一些技巧（下）》，请稍等下。

* * *

## 参考文献&链接

  1. A. Krizhevsky, I. Sutskever, and G. E. Hinton. [ImageNet Classification with Deep Convolutional Neural Networks](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf). In NIPS, 2012
  2. [A Brief Overview of Deep Learning](http://yyue.blogspot.com/2015/01/a-brief-overview-of-deep-learning.html/), which is a guest post by [Ilya Sutskever](http://www.cs.toronto.edu/%7Eilya/).
  3. [CS231n: Convolutional Neural Networks for Visual Recognition](http://cs231n.stanford.edu/index.html/) of Stanford University, held by [Prof. Fei-Fei Li](http://vision.stanford.edu/index.html) and [Andrej Karpathy](http://cs.stanford.edu/people/karpathy/).
  4. K. He, X. Zhang, S. Ren, and J. Sun. [Delving Deep into Rectifiers: Surpassing Human-Level Performance on ImageNet Classification](http://arxiv.org/abs/1502.01852). In ICCV, 2015.
  5. B. Xu, N. Wang, T. Chen, and M. Li. [Empirical Evaluation of Rectified Activations in Convolution Network](http://arxiv.org/abs/1505.00853). In ICML Deep Learning Workshop, 2015.
  6. N. Srivastava, G. E. Hinton, A. Krizhevsky, I. Sutskever, and R. Salakhutdinov. [Dropout: A Simple Way to Prevent Neural Networks from Overfitting](http://jmlr.org/papers/v15/srivastava14a.html). JMLR, 15(Jun):1929−1958, 2014.
  7. X.-S. Wei, B.-B. Gao, and J. Wu. [Deep Spatial Pyramid Ensemble for Cultural Event Recognition](http://lamda.nju.edu.cn/weixs/publication/iccvw15_CER.pdf). In ICCV ChaLearn Looking at People Workshop, 2015.
  8. Z.-H. Zhou. [Ensemble Methods: Foundations and Algorithms](https://www.crcpress.com/Ensemble-Methods-Foundations-and-Algorithms/Zhou/9781439830031). Boca Raton, FL: Chapman & HallCRC/, 2012. (ISBN 978-1-439-830031)
  9. M. Mohammadi, and S. Das. [S-NN: Stacked Neural Networks](http://cs231n.stanford.edu/reports/milad_final_report.pdf). Project in [Stanford CS231n Winter Quarter](http://cs231n.stanford.edu/reports.html), 2015.
  10. P. Hensman, and D. Masko. [The Impact of Imbalanced Training Data for Convolutional Neural Networks](http://www.diva-portal.org/smash/get/diva2:811111/FULLTEXT01.pdf). Degree Project in Computer Science, DD143X, 2015.

