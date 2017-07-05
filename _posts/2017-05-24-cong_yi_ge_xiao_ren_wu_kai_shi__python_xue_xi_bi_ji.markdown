---
layout: post
title: "从一个小任务开始——python学习笔记"
date: 2017-05-24 00:21:00
categories: ios
author: jakchen
tags: python 拓展知识...
---

* content
{:toc}



### **前记 **

之前随着阿米尔·汗的电影《摔跤吧，爸爸》大热，本人对这部电影产生了浓厚兴趣。但网上关于这部电影的资源实在太少，于是我把目光转向了公司的smb服务器。对喜欢看电影的同学来说，这里有大量的“福利”，很多稀有资源都能在第一时间上传，对于伸手党而言简直是个天堂。但是，由于资源众多，在服务器上寻找到我们想要的资源并不是一件容易的事情，尤其是在mac上，搜索极为缓慢，经常十几二十分钟后仍一无所获，让人大为光火。但在window上该情况有所好转，大胆猜测，是否是由于文件系统的不同，在win上建有索引呢？换而言之，在mac上如果能把内网搜索改为本地搜索，那么搜索速度和准确率将直线提升，这个问题就能很好解决。
<!--more-->

说干就干，既然要把内网搜索变为本地搜索，首先要有数据，所谓巧妇难为无米之炊。遗憾的是，目前服务器似乎没有提供任何数据下载的渠道，或者提供可访问的接口。人工收集显然不现实，因而，我们需要借助网络爬虫，利用计算机的特性，来自动获取我们想要的数据。

当然，实现一个爬虫很多语言都能做到，但伟大的bruce eckel曾言："life is short, you need
python”。作为仅次于php的第二大语言，网络爬虫正是python的拿手好戏。由于存在许多优秀的轮子，python可以用最简洁的代码，实现其它语言繁琐的操作。而本次的任务正是学习python的一个绝佳机会。

### 关于python

虽然之前并没有接触过python，但这门语言本身并不复杂，任何有语言基础的人，只需花两个小时了解下基本语法，即可快速上手。鉴于网上有大把的学习资料，这里不对语言本身做过多描述。值得一提的是，和oc相比，python有两大有趣的特性：lambda和tuple，lambda表达式有点像匿名函数，而tuple作为返回值则省去了大量一次性类的创建，通过搭配使用，在一定程度上可以简化编程，十分灵活。

目前，python的最新版本是3.5，它和2.x版本相比，差别还是比较大的，而且不向下兼容。鉴于目前mac os
10.12自带的python版本是2.7.1，为了避免冲突，也为了代码可移植，这里暂时采用2.7版本进行编写。尽管python3解决了python2的许多坑，例如字符编码问题，本人就花了不少时间来处理。实际上，日常练习python时我们完全可以使用python3.x版本，通过安装pyenv，我们可以自由管理python的版本切换，而不会对系统产生干扰。另一种方案来自cirolong的推荐，安装virtualenv可以创建一个独立的python运行环境，这样不仅可以兼容版本，还可以在环境中自由地安装各种第三方包，但使用时需要手动切换环境。两种方案各有优劣，目前本人采用的是第一种，具体做法可以参考文章：<http://www.jianshu.com/p/1927349cb6a2>
；

### 关于爬虫

众所周知，爬虫的基本原理，正是绕过浏览器或其它客户端工具，直接向服务器发起请求，并对服务器返回的数据进行解析，提取我们需要的信息。但有时服务器为了安全，会对请求进行相关校检，判断是否合法，对于非法请求则拒绝返回数据。基于此原因，我们往往需要进行“伪装”，带上必要的header和cookie信息，模拟用户的正常操作，防止被打回。而有些严谨的服务器甚至会设置防爬措施，对ip访问进行限频，对于这种，我们就需要人为降低访问频率，或者通过设置代理服务器来变更ip地址。当然，访问smb服务器并没有访问网站那么复杂，且幸运的是，本人在测试时发现，公司的smb服务器目前还没有对访问频率做限制，这无疑大大降低了我们操作的难度。

在通过google搜索简单了解一些相关知识后，一个项目的雏形就建立了，基本流程如下：

  1.  学习python语法，编写一个网络爬虫； 

  2.  利用网络爬虫，连接smb服务器，爬取相关的数据； 

  3.  对数据进行处理，分词并建立索引库； 

  4.  利用本地索引库搜索关键词，获取想要的信息； 

### 数据的抓取

由于搜索python官网找不到关于连接smb文件服务器的相关api（如果有的话，麻烦大神指点一下），这里采用了一个第三方库pysmb，官网链接如下：<https://miketeo.net/wp/index.php/projects/pysmb>，上面有详细的wiki文档；

至于pysmb库的安装则十分简单，直接在terminal输入以下命令即可：

    
    
    sudo pip install pysmb

 当然，对于还没有安装pip的mac用户，我们可以通过以下命令快速安装：

    
    
    sudo easy_install pip

 在引入必要头文件后，我们就可以通过以下几行代码，轻松连接smb服务器：

    
    
    def _search_server() :
        conn = smbconnection(config.username, config.password, config.hostname, config.servername, domain = config.domain, use_ntlm_v2=true, is_direct_tcp=true)
        try :
            print 'start connecting...';
            result = conn.connect(config.serverip, 445);
            print 'connect result : '+ str(result);
        except exception :
            print 'connect fail.';
        else :
            print 'connect success.';
            _run_search(conn);
            conn.close();

这里涉及几个重要参数，这些参数目前都配置在config.py文件中：username和password，顾名思义，就是我们的outlook账号；hostname，这个也很好拿到，在terminal中输入hostname即可；但servername却实在不好获取；抱着试一试的心态，随便糊弄了一个，最终果然成功。。。被拒绝了。。

查看pysmb文档关于smbconnection方法的说明，该参数和remote
server的配置名称必须严格一致，否则会被拒绝，看起来这个点无法简单绕过；

![](/image/cong_yi_ge_xiao_ren_wu_kai_shi__python_xue_xi_bi_ji/ca74fc2d0e1ce6af9dc9c2e6d70af8a58e2287763d50edf7f524cbb2a9d182cd)

解决这个问题花了我一些时间，通过查询资料可知，腾讯的文件系统tfs是一个分布式的文件系统，采用dfs技术，虽然访问时并无明显差别，但不同的目录很可能存在于不同的主机上；在mac上尝试获取无果后，偶然发现了一个取巧的方法，可以进行“曲线救国”：在window上，对于共享文件，我们可以通过右键属性，查看其dfs选项，这里可以获取该目录所在的服务器路径，如下所示：

举个栗子，我们关心的目录“腾讯电影协会-影音博物馆”，右键其属性可以看到服务器路径为：\\\fs-gk27a\腾讯电影协会-影音博物馆$，如预想的一样
，其中的fs-gk27a，正是我们所需要的服务器域名；而有了服务器域名，获取其ip则很简单了，在cmd中ping一下，便可得到服务器真实域名为 fs-
gk27a.tencent.com，ip地址为10.14.37.68；

![](/image/cong_yi_ge_xiao_ren_wu_kai_shi__python_xue_xi_bi_ji/05d882dc50020347a8a9c3db1df8690aded4c9009586f21b0bab085f678f0773)

![](/image/cong_yi_ge_xiao_ren_wu_kai_shi__python_xue_xi_bi_ji/5acc0f805fafda8a88e31167ba3e0be6a3ebf3f35e1269eff8f7c84ab907d81d)

有了这些参数，便可顺利连接服务器；"腾讯电影协会-
影音博物馆”目录下有四个文件夹，其中“★书籍”和“★游戏”不是我们所需要的，可以直接过滤，剩下的可以通过一个递归的方法，循环获取文件信息，精简后的代码如下：

    
    
    def _searchpath(conn, path, foldername) :
        for subpath in conn.listpath(config.rootpath.decode('utf-8'), path.decode('utf-8')) :
            # process
            if subpath.filename.startswith('.') :
                print 'hidden file, pass.';
            elif subpath.filename == 'dfsrprivate' :
                pass;
            elif subpath.isdirectory :
                print '[directory] : ' + subpath.filename;
                subdicpath = path + subpath.filename.encode('utf-8') + '/';
                _searchpath(conn, subdicpath, subpath.filename.encode('utf-8'));
            else :
                print '[file] name = : ' + subpath.filename + ' foldername = ' + foldername.decode('utf-8') + ' path = ' + path.decode('utf-8');
                _record(subpath.filename, foldername.decode('utf-8'), path.decode('utf-8'));

 抓包大约会持续10分钟，最后我们可以得到一份全量数据；从日志上看，共有26万多个文件，我的天，终于明白为何在mac上搜索如此缓慢了；

![](/image/cong_yi_ge_xiao_ren_wu_kai_shi__python_xue_xi_bi_ji/6175a27d51c2eda5f51c99bef3ff6927456d09994ea3064dd99d86f0a45ba635)

### 分词器的选型

既然有了原始数据，剩下的便是分词并建立索引库了；对于英文，分词比较简单，我们往往以空格作为分词标志，对字符串做简单处理即可；但服务器上大多数的电影名称都是中文，中文的分词可要复杂得多，即使同一个单词，是否需要拆分也要视语境而定。而中文分词的策略，在我看来又可简单分为两种，基于词典的分词，以及暴力分词；根据我们的场景，我搜索比较了几种常见的分词器，最终选定了jieba分词器。

jieba分词器是一个开源的基于词典的中文分词库，优点是搜索速度快，且自带中文词库，可以提高中文搜索的成功率；但缺点也有，jieba分词器在初始化时需要加载这些数据，因而启动较慢；鉴于我们对单次搜索的时间要求并没有严格的要求，相比于优点，其不足之处是可以接受的；

此外，在测试时发现，对于有些剧集，其文件夹的名称才具有实际意义，子文件则往往以01、02等无意义的下标作为名称，用户搜索时根本不会输入这些关键字。这就导致，如果不做处理，这类电影会被间接过滤，如搜索"神探夏洛克”，基本难以找到匹配的结果。为了较大程度地规避此问题，对于keyword的选取，不再简单地使用文件名，而是绑定其文件夹，将foldername_filename作为一个整体的方式进行分词处理，提高匹配的成功率；至于英文，原本计划对字母做统一的小写化处理，但jieba本身做了这部分工作，所以这个步骤可以跳过；

### fts方案的选择

目前市面上主流的fts方案很多，这里主要对比了下pylucene和whoosh。作为鼎鼎大名的lucene的python实现，我对pylucene一开始是充满向往的，然而实际使用起来却不尽人意，过程略显繁琐，最终不得不放弃。相比之下，纯python实现的whoosh则简洁有效得多。由于whoosh使用并不复杂，且fts不是本次学习的重点，这里就不做过多赘述，有兴趣的同学可以到官网学习一下，上面有许多详细的demo：<https://pypi.python.org/pypi/whoosh>；

### 本地搜索

利用whoosh+jieba，我们轻松完成了分词和索引库建立的工作，至此，我们离成功仅有一步之遥了；搜索依旧采用whoosh的api，这里补充下前面关于这两个库的安装，打开我们的terminal，输入以下命令即可：

    
    
    sudo pip install whoosh
    sudo pip install jieba

至于代码比较简单，这里就不列出来了，有兴趣的可以看下源码；

我们直接进入体验环节，通过运行search.py，搜索”摔跤吧“，结果如下：

![](/image/cong_yi_ge_xiao_ren_wu_kai_shi__python_xue_xi_bi_ji/b9b20cc4b7bfde2966c2c44161fe5dafdc4c53c2d7236f38cf045efcf7f713c9)

perfect，成功获得了我们想要的结果；在finder中用cmd+k快捷键，输入上面的smb链接，即可跳到对应的文件夹；而更重要的是，有了本地的索引库，以后终于不用忍受龟速般的搜索了，简直是我等伸手党的福音啊；虽然目前由于时间缘故，还未做到对索引库进行增量更新乃至自动更新，但从技术上分析是可行的，这里留待以后完成。

### 后记

关于这个小项目，从萌生这一想法，到学习python、抓取数据以及建立本地索引库，总共花了1天多的时间，代码总行数不超过300，不得不说这正是python的魅力所在。当然，由于时间有限，这只是一个简单的雏形版本，勉强算得上v1.0，很多方案和实现并未达到最优，需要后续进行调试改进。此外，由于对python不熟悉，在编写过程中，自然免不了踩坑，一边查阅文档以了解其语法和使用，一边google原理，最终磕磕绊绊地写完。但我始终认为，学习一门语言，最好的方式还是写一个小demo，这样理解起来才会更加深刻。由于某些不可描述的原因，最近恰好需要写一篇文章，这里我将python入门的经历简单记录下来，希望能对那些有感于此的同事有所帮助和启发，毕竟原理是相通的。

最后，文章的末尾附上源码，有兴趣的朋友可以根据 readme.md
中的说明，配置参数后，自己抓包尝试一下，或者修改源码实现，以贴合自己的需求；当然，如果你对python没有兴趣，也没关系，可以直接下载抓包后的index库，按照
readme.md 的说明简单安装几个python库，即可以开始使用，很惭愧，只是做了一些微小的工作。。。

**[ p.s. 如果该行为违反了相关规定，麻烦8000知会一声，本人会立即停止一切行为，并删除相关文章和代码 ！！！ ] **

