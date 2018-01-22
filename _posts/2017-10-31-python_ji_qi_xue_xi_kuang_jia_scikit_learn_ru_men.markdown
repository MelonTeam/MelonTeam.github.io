---
layout: post
title: "python机器学习框架Scikit-learn入门"
date: 2017-10-31 23:17:00 +0800
categories: deep learning
author: yellowye
tags: 机器学习 Python
---

* content
{:toc}



**Scikit-learn是什么，它能做什么**

[Scikit-learn](http://scikit-
<!--more-->
learn.org/stable/index.html)简称sklearn，是一种机器学习的python框架，[安装](http://scikit-
learn.org/stable/install.html)非常简单，并且其文档支持和例子感人。基本功能主要被分为六大部分：分类，回归，聚类，数据降维，模型选择和数据预处理，但并**不适用于强化学习和多层神经网络深度学习**。

**Scikit-learn怎么用**

  1. 这是一张官网的函数库的说明图：

![](/image/python_ji_qi_xue_xi_kuang_jia_scikit_learn_ru_men/de648cde1edf7b3ad62a49b4c116d2069c5c1b10ca3ee66e3b1226895b58d938)

这张图很清晰的说明了sklearn能做什么，并且告诉开发者该怎么根据数据集和目标来选取对应的库：

  * 算法库分为四类：分类，回归，聚类和降维，其中分类和回归是监督式学习，聚类是非监督式学习；降维是指当数据集有很多属性的场景时，归纳为少量特征输入的方法；
  * 判断完问题属于哪一类问题后，看数据集大小来选取对应的模型方法。

2.强大的[数据集](http://scikit-learn.org/stable/modules/classes.html#module-
sklearn.datasets)

sklearn不仅提供了多样的数据集loaders，还提供接口自定义数据集generator,我们可以通过以下方法来定义不同量级和维度数据集：

    
    
    sklearn.datasets.make_regression(n_samples=100, n_features=100, n_informative=10, n_targets=1, bias=0.0, effective_rank=None, tail_strength=0.5, noise=0.0, shuffle=True, coef=False, random_state=None)

 虽然sklearn本身不支持深度学习，但它的数据集是可以为深度学习训练所用的。

![](/image/python_ji_qi_xue_xi_kuang_jia_scikit_learn_ru_men/e903df6b60f6140a832d082252bb2b52a0fa36539f5108b5aff84de687ea1b97)

3.为模型打分校验和参数调整

**打分举例：**

例子出自[莫烦机器学习](https://morvanzhou.github.io/tutorials/machine-
learning/)，这个博文讲的很好，推荐大家也去看下。

    
    
    from sklearn.datasets import load_iris # iris数据集
    from sklearn.model_selection import train_test_split # 分割数据模块
    from sklearn.neighbors import KNeighborsClassifier # K最近邻(kNN，k-NearestNeighbor)分类算法
    
    #加载iris数据集
    iris = load_iris()
    X = iris.data
    y = iris.target
    
    #分割数据并
    X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=4)
    
    #建立模型
    knn = KNeighborsClassifier()
    
    #训练模型
    knn.fit(X_train, y_train)
    
    #将准确率打印出
    print(knn.score(X_test, y_test))
    # 0.973684210526

**sklearn中的交叉验证的使用举例：**

对于判定我们选择的模型和模型的参数是否是合理的的方法有很多种，其中Sklearn中的Cross Validation
(交叉验证)有着很好的评定作用，也提供了良好的api和可视化库的支持。

什么是[交叉验证](https://baike.baidu.com/item/%E4%BA%A4%E5%8F%89%E9%AA%8C%E8%AF%81)

交叉验证（Cross validation)，交叉验证用于防止模型过于复杂而引起的过拟合，有时亦称循环估计，
是一种统计学上将数据样本切割成较小子集的实用方法。于是可以先在一个子集上做分析， 而其它子集则用来做后续对此分析的确认及验证。
一开始的子集被称为训练集。而其它的子集则被称为验证集或测试集。交叉验证是一种评估统计分析、机器学习算法对独立于训练数据的数据集的泛化能力（generalize）

一般要满足：

  * 训练集的比例要足够多，一般大于一半
  * 训练集和测试集要均匀抽样

![](/image/python_ji_qi_xue_xi_kuang_jia_scikit_learn_ru_men/c6477049d80e1786332c6e9c1638e51f4fd57efc8832c1171237deeb1b34486d)

**交叉验证对k近邻分类算法的k值的验证：**
    
    
    import matplotlib.pyplot as plt #可视化模块
    
    #建立测试参数集
    k_range = range(1, 31)
    
    k_scores = []
    
    #藉由迭代的方式来计算不同参数对模型的影响，并返回交叉验证后的平均准确率
    for k in k_range:
        knn = KNeighborsClassifier(n_neighbors=k)
        scores = cross_val_score(knn, X, y, cv=10, scoring='accuracy')
        k_scores.append(scores.mean())
    
    #可视化数据
    plt.plot(k_range, k_scores)
    plt.xlabel('Value of K for KNN')
    plt.ylabel('Cross-Validated Accuracy')
    plt.show()

 ![交叉验证 1 Cross-
validation-0](/image/python_ji_qi_xue_xi_kuang_jia_scikit_learn_ru_men/0098329eaec8213f4166d702f3ba75197c7db289a240683599726d9027eb7cc8)

从结论可知，选择12~18的k值最好，18之后，准确率开始下降则是因为过拟合(Over fitting)的问题。

