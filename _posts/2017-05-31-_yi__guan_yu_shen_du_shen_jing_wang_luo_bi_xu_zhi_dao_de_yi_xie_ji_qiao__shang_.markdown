---
layout: post
title: "【译】关于深度神经网络必须知道的一些技巧（上）"
date: 2017-05-31 22:50:00
categories: 其他
author: cirolong
tags: 深度学习 网络训练...
---

* content
{:toc}



> 翻译自[魏秀参](http://lamda.nju.edu.cn/weixs/)博士的文章：[must know tips/tricks in deep
neural
networks](http://lamda.nju.edu.cn/weixs/project/cnntricks/cnntricks.html)
<!--more-->

![tips/tricks](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/411a003722bb7c84518e53502af3c33bd930cf8c0e497b8d694e491f2d0040f9)
|
深度神经网络，特别是**卷积神经网络**（cnn），使得由许多处理层构成的计算模型能够完成对数据的多层抽象表示。它们已经非常显著地提高了计算机视觉诸多领域的现有水平，如物体识别，物体检测，文本识别等。并且还包括许多其他领域，如药物发现和基因研究。  
此外，在计算机视觉领域，目前已有许多优秀的论文发表，而且诞生了不少高质量的cnn开源软件和学习框架。同时也出现了许多不错的cnn教程和手册。然而，关于如何从零开始实现一个出色的深度卷积神经网络，目前可能还是缺少一个较新的、较全面的总结。因此，我们收集并总结了许多dcnns的实现细节。**这里我们将介绍大量关于如何构建和训练神经网络的实现细节，也可以说是_技巧或秘诀_。**  
---|---  
  
## 前言

我们假设你已经掌握了基本的深度学习知识，并且我们这里介绍的实现细节（技巧）是关于深度神经网络的，尤指用于**图像相关任务**的卷积神经网络（cnn），主要包括以下**8个部分**：**1）**_数据扩增_；**2）**_数据预处理_；**3）**_网络初始化_；**4）**_训练过程中的一些技巧和注意事项_；**5）**_激活函数的选择_；**6）**_多种正则化方法_；**7）**_深刻理解训练图_；**8）**_组合多个网络_。  
另外，与本文对应的ppt在这里[[slide]](http://lamda.nju.edu.cn/weixs/slide/cnntricks_slide.pdf)。如果关于这篇文章和ppt你有任何的疑问，或者发现了错误，或者还有其他重要的、有意思的东西你觉得应该加上，可以随时联系[我](http://lamda.nju.edu.cn/weixs/)。

## 1.数据扩增

因为深度网络需要使用大量的图片数据进行训练以达到满意的效果，如果原始的训练数据集数量较少，则应该对这些数据做一些扩增（augmentation）来提高训练效果。其实，数据扩充已经成为了训练深度网络一个必不可少的步骤。

  * 数据扩增有许多方法，目前常用的有**水平翻转**，**随机剪裁**，**颜色抖动**。而且也可以尝试多种方式组合，比如同时对图像进行旋转和缩放。此外，可以调整一张图像中所有像素的饱和度和明度（饱和度s和明度v是指hsv色彩空间），调整方法具体是：先对s（或v值）进行幂运算，幂值在0.25~4之间，然后乘上一个0.7~1.4的系数，最后再加上一个-0.1~0.1的常数。这种方法同样适用于一个批（**batch**）大小里面的所有图像。也可以给色相（hsv色彩空间的h分量）加上1个-0.1~0.1的常数。
  * _**fancy pca**_（krizhevsky等人[[1]](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf)在2012年训练注明的_alex-net_时提出）。fancy pca在训练过程中改变了图像rgb通道的值。在实际使用中，首先对训练图像rgb像素值做pca降维，然后对于每张训练图像的每一个像素点（即![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/508aae7f55324f09393ce98523db34b7f3b9656875faa3bf2aa85b21f190ca01)），叠加上：![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/536485d6ab85c939909bb2afea7a4d4cc73d56d13872e46031689765343cf742)，其中![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/38ac0109827830ba71805a43be21d2e89cf84e3cc9dbf6cbadc223e4e9b92e31)和![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/20f9c5a7558385839fde7914632f8497741176b5b0b67cb048d9f84743850425)分别是第i个特征向量和rgb像素值3x3协方差矩阵的特征值，![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/10c067044dea226ee45c7b3eb0ba6adfc37656d46e2744f9fae410a6a44738f4)是服从高斯分布（均值为0，标准差为0.1）的随机数。每个![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/10c067044dea226ee45c7b3eb0ba6adfc37656d46e2744f9fae410a6a44738f4)对于一张训练图像的所有像素点只初始化一次，直到这张图像再次用于训练。也就是说，当训练模型再次遇到同一张图像时，它会随机产生一个新的![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/10c067044dea226ee45c7b3eb0ba6adfc37656d46e2744f9fae410a6a44738f4)用于数据扩增。在[[1]](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf)中指出，fancy pca可以近似地提取出图像中的重要信息，也就是说对色彩饱和度变化以及光照具有不变性。在分类性能上，这种方法在imagenet 2012比赛中将top1错误降低了1%。

## 2.数据预处理

现在我们手上已经有了大量的训练数据了，不过可千万别着急！我们需要对这些数据做一下预处理。在这个章节我们将介绍几种预处理的方法。

第一种简单的处理方法就是对数据进行**零中心化**（zero-center），然后进行**归一化**（normalize）。使用python代码表示如下：

    
    
    >>> x -= np.mean(x, axis = 0) # zero-center
    
    >>> x /= np.std(x, axis = 0) # normalize

其中x是输入数据。另一种方式是对每一个维度的数据进行归一化，使得最小值和最大值分别为-
1和1。如果不同的输入特征具有不同的尺度，但它们对学习算法的影响效果大致相等，这样进行数据预处理才有意义。对于图像而言，像素的相对尺度是差不多相同的（在0~255之间），所以预处理操作也不是十分必须的。

另外一种方法跟第一种方法差不多，叫做**pca白化**（pca
whitening）。首先同样是对数据进行零中心化，然后计算协方差，它展示了数据中的相关性结构：

    
    
    >>> x -= np.mean(x, axis = 0) # zero-center
    
    >>> cov = np.dot(x.t, x) / x.shape[0] # compute the covariance matrix

之后，把原始数据（已经零中心化）投射（projecting）到特征向量上进行去相关操作：

    
    
    >>> u,s,v = np.linalg.svd(cov) # compute the svd factorization of the data covariance matrix
    
    >>> xrot = np.dot(x, u) # decorrelate the data

最后一步就是白化操作，将上一个步骤得到的结果除以特征值：

    
    
    >>> xwhite = xrot / np.sqrt(s + 1e-5) # divide by the eigenvalues (which are square roots of the singular values)

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
breaking）。在训练的开始阶段，所有神经元都是随机且唯一的，然后它们将进行不同的更新，成为整个网络不同的一部分。这种初始化方式很简单：![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/089e1e537c57071fb38fdb3d01e8efa731bfb01affbea1c1fee878fc1a545138)，其中![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/fa3581bb8c4f890a8fae85c6e516946c6b8c048361030ddee78c1d0754d55666)是均值为0，标准差为1的高斯分布。也可以使用服从均匀分布的较小值，但实际训练中发现其对最终训练结果的影响要小一些。

**校正方差**

上述随机初始化权值的方法存在一个问题，随着输入数据的增加，输出的方差也会增加。可以用随机初始化权值除以输入数据大小的开方，使得每个神经元输出的方差变为1，如下所示：

    
    
    >>> w = np.random.randn(n) / sqrt(n) # calibrating the variances with 1/sqrt(n)

其中“randn”是产生高斯分布的函数，“n”表示输入数据的大小。这样使得网络中所有神经元在训练开始的时候具有大致相同的输出分布，实验也证明这会提高收敛速度。详细的推导过程可见ppt的18~23页，要说明的是，这个推导并没有考虑relu（修正线性单元，见第5章节）的影响。

**推荐方法**

上述校正方差的方法并未考虑relu的影响。最近he等人[[4]](https://arxiv.org/abs/1502.01852)提出了一种专为relu设计的初始化权值方法，得出的结论是：网络中神经元的方差应为![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/cc56ff58e3c12caac9ca46119da66fec7283d08f540b085ee22948636e8ab77a)。

    
    
    >>> w = np.random.randn(n) * sqrt(2.0/n) # current recommendation

如[[4]](https://arxiv.org/abs/1502.01852)中的讨论，这也是当前推荐在实际中使用的方法。

## 4.训练过程

现在所有的准备工作都做好了，让我们开始训练网络吧！

  * **卷积核和池化的大小。**训练过程中，输入图像的大小最好为2的幂，比如32（cifar-10），64，244（通常在imagenet中使用），384或者512。另外采用较小的卷积核（比如3x3）和较小的滑动步长（比如1）并进行补0操作（zeros-padding）是比较重要的，这样不仅能够减少参数的个数，而且能够提高整个网络的准确率。同时，上面提到的3x3卷积核大小和滑动步长为1的组合用例，能够使得输入图像/输出特征保持大小一致（比如(32-3+2*1)/1+1=32）。对于池化层，池化大小通常为2x2。
  * **学习速率。**如ilya sutskever在其博客[[2]](http://yyue.blogspot.sg/2015/01/a-brief-overview-of-deep-learning.html/)中所述，他建议将梯度值除以mini批大小（mini-batch size）。因此，如果在训练过程中改变了批大小，就不必要一直改变学习速率（lr）。为了得到一个合适的lr，可以使用验证集。通常，在训练开始的时候采用的lr为0.1。在实际训练过程中，若发现当前使用的lr在验证集上损失（loss）不再下降，可以尝试将lr除以2（或者5），再继续进行训练，会有惊喜发生。
  * **预训练模型调优（fine-tune）。**目前，许多预训练好的模型被一些著名的研究团队公布，如[_caffe model zoo_](https://github.com/bvlc/caffe/wiki/model-zoo)和[_vgg group_](http://www.vlfeat.org/matconvnet/pretrained/)。得益于这些预训练模型良好的泛化能力，可以直接拿来使用到自己的应用中。为了进一步提高这些模型在自己的训练集上的分类效果，一个简单有效的方法便是在自己数据集上对这些预训练模型进行调优（fine-tuning）。如下表所示，两个重要的因素：新数据集的大小，以及它与原始数据集之间的相似度。不同的情况应采用不同的调优策略。举例说明，比如你的数据集与预训练模型采用的训练数据集非常相似，在此情况下，若自己的数据集较小，只要在预训练模型最顶层输出特征上再训练一个线性分类器即可；若自己的数据集较大，可以使用一个较小的学习速率对预训练模型的最后几个顶层进行调优。如果自己的数据集与预训练模型采用的训练数据集相差较大但拥有足够多的数据，在这种情况下则需要对网络的多个层进行调优，同样也要使用较小的学习速率。还有一种情况是，自己的数据集不仅较小，而且与原始数据集相差较大，那这个就比较麻烦了。因为数据集较小，所以最好只训练一个线性分类器；因为数据差异很大，所以只对网络的最后几个顶层调优并不是很好的方案，因为这几个层包含了更多数据相关（dataset-specific）的特征。针对此种情况，在网络较为靠前的特征层就使用svm分类器可能是相对而言较好的方案。

![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/2660250bb9575551acba3455d9d6f42b623b0c5fee6f97e125e3cc8fc620cf40)
| 在自己的数据集上调优（fine-tune）预训练模型。不同情况下采用不同的调优策略。对于数据集，_caltech-
101_与_imagenet_比较相似，都是关于物体的数据集；而_place database_就与_imagenet_不同，它是关于场景的数据集。  
---|---  
  
## 5.激活函数

激活函数（_activation
function_）是深度网络几个重要特点之一，它使得网络具有**非线性**表达能力。这里将介绍几种常用的激活函数，然后提出一些使用建议。

![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/b9c03653c146de861470aac202e8d7aa318be4fb2437e2856632e9d60869dad6)
| 图片来自[stanford cs231n](http://cs231n.stanford.edu/index.html)  
---|---  
  
**sigmoid**

![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/63e8b1647c5f4a145ae806d352fb68ca78186edf3913ee94e45a3af940588f02)
|
**sigmoid**非线性函数：![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/ce176f5684ed0006f6ec62ffd5a5d7c66a75ec960c3553c7f8ebafd6062d226f)  
它将实数“压扁”在0~1之间，正无穷趋向于1，负无穷趋向于0。sigmoid函数过去经常被使用，因为它很好地模拟了神经元的激活状态：从根本不被激活（0）到完全被激活（1）。  
---|---  
  
在实际使用中，已经很少采用sigmoid函数，因为它有两个主要的缺点：

  1. _sigmoid函数容易饱和梯度，并终止梯度传递。_sigmoid函数有个不太好的特性，就是当神经元的激活值饱和在0或1的“小尾巴”处时（见sigmoid函数图），这些区域的梯度值为0。在反向传播的过程中，这个（局部）梯度将会与整个损失函数关于该门单元（gate）输出的梯度相乘。因此，如果局部梯度的值非常小，它会“杀死”梯度，这样几乎就没有信号通过神经元传到权值并传到数据了。此外，为了防止梯度饱和，在初始化权值的时候需要特别注意。比如，若初始化权值过大，那么大多数神经元将会饱和，导致网络几乎失去学习能力。
  2. _sigmoid函数的输出不是零中心化的（zero-centered）。_这个特性也是不合需要的，因为网络中较后层的神经元将会收到非零中心化的数据。这将会影响梯度下降的过程，因为如果某个神经元的数据数据总是正数（如![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/bdc30ff83569a0a23e9adec0f95c57d01004687efed3013714485d1fe5fd63c9)中每个![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/8b0bb7e24fa92434e6b185ac0ef59afdb323d3b484b208cd97cbf324faf92408)）,那么权值![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/0647780ebe998775cd50e45e744e977d1be77658e2191a2c2ce6a175a8d70347)的梯度在反向传播的过程中，要么全部为正数，要么全部为负数（具体依整个表达式![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/5c9fdfd627db72b23613b4d6221b1e117632a11585c3e7d18e3bfc6f8248b37f)的梯度而定）。这样在权值梯度更新的时候就会出现“z字形”锯齿。然而，当一个批大小（batch）里面数据的梯度叠加起来以后，一定程度上会缓解这个问题，因为一个批大小里面的梯度值有正有负。因此，这个缺点相比于上面的饱和梯度问题来说，只是个小麻烦，没有那么严重。

**tanh(x)**

![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/3f3b27ec7c73239738a5cbcb92608d28052fc0e07b539b5cb129e6665ba8becd)
|
**tanh**非线性函数将实数“压扁”在[-1,1]之间，和sigmoid函数一样，它也存在饱和梯度的问题，但不同的是它的输出是零中心化的。因此，在实际使用中，tanh非线性函数比sigmoid非线性函数要用得多一些。  
---|---  
  
**rectified linear unit**

![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/4bd2c8afd96c4e7fbc0b50e6724f4181e3097e5e0eaeff2578cf23e4499e67b3)
| **修正线性单元**（rectified linear
unit,relu）近年来非常受欢迎。其函数公式：![](/image/_yi__guan_yu_shen_du_shen_jing_wang_luo_bi_xu_zhi_dao_de_yi_xie_ji_qiao__shang_/07aaed914dec8903047df720be81ec0e5406ba03ed39f94f013cbd07f19b9227)  
---|---  
  
relu有以下优缺点：

  1. （_优点_）相比于sigmoid/tanh包含复杂的运算（如指数运算），relu只需要对矩阵进行简单的阈值计算（与0比较）得到。此外，relu没有饱和梯度的问题。
  2. （_优点_）与sigmoid/tanh相比，relu极大加速了梯度下降的收敛过程（[[1]](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf)中指出有加速6倍之多）。可以认为这是得益于relu线性、非饱和的特点。
  3. （_缺点_）不过，relu在训练过程中比较脆弱并且可能“死掉”。举例来说，当一个很大的梯度值经过relu神经元，可能当权值更新后，神经元将再也无法被其他任何数据激活。若这种情况发生，那么从此所有经过这个神经元的梯度都将变成0。也就是说，这个relu单元将在训练过程中不可逆转地死亡，因为它减少了数据的多样性。如果学习速率设置过高，可能会发现网络中40%的神经元都会死掉（即对于整个训练集，这些神经元都不会被激活）。通过设置合适的学习速率，可以降低这种情况发生的概率。

* * *

### 马上会更新《【译】关于深度神经网络必须知道的一些技巧（下）》，请稍等下。

* * *

## 参考文献&链接

  1. a. krizhevsky, i. sutskever, and g. e. hinton. [imagenet classification with deep convolutional neural networks](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf). in nips, 2012
  2. [a brief overview of deep learning](http://yyue.blogspot.com/2015/01/a-brief-overview-of-deep-learning.html/), which is a guest post by [ilya sutskever](http://www.cs.toronto.edu/%7eilya/).
  3. [cs231n: convolutional neural networks for visual recognition](http://cs231n.stanford.edu/index.html/) of stanford university, held by [prof. fei-fei li](http://vision.stanford.edu/index.html) and [andrej karpathy](http://cs.stanford.edu/people/karpathy/).
  4. k. he, x. zhang, s. ren, and j. sun. [delving deep into rectifiers: surpassing human-level performance on imagenet classification](http://arxiv.org/abs/1502.01852). in iccv, 2015.
  5. b. xu, n. wang, t. chen, and m. li. [empirical evaluation of rectified activations in convolution network](http://arxiv.org/abs/1505.00853). in icml deep learning workshop, 2015.
  6. n. srivastava, g. e. hinton, a. krizhevsky, i. sutskever, and r. salakhutdinov. [dropout: a simple way to prevent neural networks from overfitting](http://jmlr.org/papers/v15/srivastava14a.html). jmlr, 15(jun):1929−1958, 2014.
  7. x.-s. wei, b.-b. gao, and j. wu. [deep spatial pyramid ensemble for cultural event recognition](http://lamda.nju.edu.cn/weixs/publication/iccvw15_cer.pdf). in iccv chalearn looking at people workshop, 2015.
  8. z.-h. zhou. [ensemble methods: foundations and algorithms](https://www.crcpress.com/ensemble-methods-foundations-and-algorithms/zhou/9781439830031). boca raton, fl: chapman & hallcrc/, 2012. (isbn 978-1-439-830031)
  9. m. mohammadi, and s. das. [s-nn: stacked neural networks](http://cs231n.stanford.edu/reports/milad_final_report.pdf). project in [stanford cs231n winter quarter](http://cs231n.stanford.edu/reports.html), 2015.
  10. p. hensman, and d. masko. [the impact of imbalanced training data for convolutional neural networks](http://www.diva-portal.org/smash/get/diva2:811111/fulltext01.pdf). degree project in computer science, dd143x, 2015.

