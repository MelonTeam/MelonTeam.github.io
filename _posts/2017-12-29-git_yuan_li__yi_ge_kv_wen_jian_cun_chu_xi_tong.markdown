---
layout: post
title: "GIT原理-一个KV文件存储系统"
date: 2017-12-29 15:06:00 +0800
categories: 其他
author: simonhao
tags: Git
---

* content
{:toc}

| 导语 Git作为一个常用版本控制系统，我们仅仅是熟悉使用肯定是不够，还需要深究一下其原理，本文是我阅读《Pro Git Book》写的一篇引导向的文章。

### 一、为什么说Git是一个KV文件存储系统？

在开始之前，我们先准备一个空的仓库。后面的文档会基于这个仓库做一些操作。
<!--more-->

    
    
    # git init test
    # cd test

 既然说Git是一个KV文件存储系统，那么他就应该像其他KV系统一样，至少有Get和Set两个方法。下面两个命令就是Git的Get和Set方法。

    
    
    # git hash-object
    # git cat-file

hash-object命令用来向Git增加文件。cat-file命令用来从Git读取文件。下面我们操作一下。

    
    
    # echo 'test content' | git hash-object -w --stdin
    > d670460b4b4aece5915caf5c68d12f560a9fe3e4  
    # git cat-file -p d670460b4b4aece5915caf5c68d12f560a9fe3e4  
    > test content

先看hash-
object操作，-w参数指的是保存，不然只会计算文件的SHA1而不保存，--stdin指的是从标准输入读内容。最后返回的SHA1就是文件在该KV系统内的KEY。

再看cat-file操作，-p参数表示返回文件的详细信息。加上前面得到的KEY，从GIT中读取文件内容。

现在你应该可以理解Git是一个什么样的KV文件系统了吧！接下来我们进入仓库的.git目录，看下都有哪些内容。

    
    
    # cd .git
    # ls -la
    -rw-r--r--   1 simonhao  staff   23 12 29 11:18 HEAD
    drwxr-xr-x   2 simonhao  staff   68 12 29 11:18 branches
    -rw-r--r--   1 simonhao  staff  137 12 29 11:18 config
    -rw-r--r--   1 simonhao  staff   73 12 29 11:18 description
    drwxr-xr-x  12 simonhao  staff  408 12 29 11:18 hooks
    drwxr-xr-x   3 simonhao  staff  102 12 29 11:18 info
    drwxr-xr-x   5 simonhao  staff  170 12 29 11:24 objects
    drwxr-xr-x   4 simonhao  staff  136 12 29 11:18 refs

objects目录就是整个KV系统的存储目录，我们所有的文件都会存储到objects目录里。

    
    
    # cd objects  
    > d6
    
    # cd d6  
    > 70460b4b4aece5915caf5c68d12f560a9fe3e4

在objects目录下只包含一个名为d6的文件夹，d6文件夹下有一个名字很长的文件。可能你已经发现了，目录名加上文件名就是前面我们添加的那个文件的SHA1。是的，GIT就是用SHA1前两位做文件夹名，剩余的做文件名的方式来存储文件。现在我们已经知道了GIT是如何存储文件的了。是时候来点高级的了。我们使用
add和commit的命令来操作一下，然后看看GIT是不是这么做的呢。

    
    
    # echo fitst_lint > fitst_file
    # git add .
    # git commit -m 'first_commit'
    
    
    # cd objects  
    > 08  
    > 66  
    > 96  
    > d6 [使用hash-object写入的]

 喵了个咪的！我就提交一个文件，怎么变四个了！莫慌，我们使用前面学到的cat-file命令来看看这些文档都是设么鬼！

    
    
    # git cat-file -p 96f8dc00bdda6b464a82f5b5f73d95465fa7da20
    > tree 08f86d54525fa50c4a1625699338abf440105880  
    > author SimonHao  1514519431 +0800
    > committer SimonHao  1514519431 +0800  
    >  
    > first_commit  
    
    # git cat-file -p 08f86d54525fa50c4a1625699338abf440105880
    > 100644 blob 66075654c600b895c037c3f84556f8f410df2445 fitst_file  
    
    # git cat-file -p 66075654c600b895c037c3f84556f8f410df2445  
    > fitst_lint

这下你是不是发现了什么！第一个96开头的文件包含了我们提交的日志，并用一个tree字段指向了另一个08开头的文件，而08开头的文件则包含了一个列表，其中一项是指向66开头的文件，66开头的文件则包含我们文件的实际内容。我隐隐觉得这三个文件可能作用不一样，在GIT中承担的职责也不一样
。还是用cat-file命令看一下。

    
    
    # git cat-file -t 96f8dc00bdda6b464a82f5b5f73d95465fa7da20  
    > commit  
    
    # git cat-file -t 08f86d54525fa50c4a1625699338abf440105880  
    > tree  
    
    # git cat-file -t 66075654c600b895c037c3f84556f8f410df2445  
    > blob

到现在我们可以用一个更高级的定义了！我们存储到GIT中的文件可以称之为“对象”，对象包含commit对象，tree对象，blob对象。blob对象包含的包含文件的内容，tree对象包含的目录的信息，commit对象包含每次提交记录的信息。有了对象的基本概念之后，我们接下来看Git是如何实现版本管理的。

### 二、如何实现版本管理？

我们修改下刚才的那个文件再提交一次。这样这个文件就有了两个版本。

    
    
    # echo second_line > fitst_file
    # git add .
    # git commit -m 'second commit'

我们再看一下objects目录，发现又多了三个以61，68和d1开头的对象。

    
    
    # cd objects  
    > 08  
    > 61  
    > 66  
    > 68  
    > 96  
    > d1  
    > d6 [使用hash-object写入的]

 我们查看一下这三个对象。

    
    
    # git cat-file -p 61edbc644569e291a02c9c30f2125fcd622d8fad
    > tree 68469fa51f07b7d370e8a61d0d9bded8bf7ea5f6  
    > parent 96f8dc00bdda6b464a82f5b5f73d95465fa7da20  
    > author SimonHao  1514528154 +0800  
    > committer SimonHao  1514528154 +0800  
    >  
    > second commit   
    # git cat-file -p 68469fa51f07b7d370e8a61d0d9bded8bf7ea5f6   
    > 100644 blob d11fb9fc76917bde506646efc6c1825d459ee020 fitst_file  
      
    # git cat-file -p d11fb9fc76917bde506646efc6c1825d459ee020   
    >second_line

和第一个commit对象不同之处在于，这个commit对象多了一个parent，而这个paren正好指向上一个commit对象。而且也生成了一个新的tree对象，其实，在Git中tree对象也可以再包含tree对象。至此，我们脑海中可以形成这样一幅图：通过commit对象来形成一个个版本记录，每个commit指向一个tree对象(根目录)，然后每个tree对象包含一系列的blob对象和文件对象。这样就形成了一个版本记录。


![](/image/git_yuan_li__yi_ge_kv_wen_jian_cun_chu_xi_tong/71c6500942336de604d23685967f503c0f4ec16cd4f659a4ddaa16803949d041)



### 三、在文件KV系统上如何构建分支

在日常开发中，我们最常用的分支是怎么实现的呢？其实，分支在Git中很简单，仅仅是指向一个commit对象的指针。所有的分支都存储在refs目录下。我们看看这个目录下的内容：

    
    
    # cd refs  
    > heads  
    > tags

里面两个文件夹，一个heads，一个tags。所有的分支记录在heads目录中。这里还有一个tags文件夹，可以想到，Git的tag也和分支一样仅仅是指向commit对象的一个指针。我们看一下默认分支master的内容。

    
    
    # cat heads/master  
    > 61edbc644569e291a02c9c30f2125fcd622d8fad

 可以看到，事实就是如此，一个分支仅仅只是一个指向commit对象的指针。我们创建一个test分支。然后看一下他的内容。

    
    
    # git branch test
    # cat heads/test  
    > 61edbc644569e291a02c9c30f2125fcd622d8fad

可以看到，test分支是和master分支一样的指针。其情形大概如下图：

![](/image/git_yuan_li__yi_ge_kv_wen_jian_cun_chu_xi_tong/b8ddf174a69a8f3b3b6183bfce13380ae15b56c0ceb80339131a67be1ce5c7c6)

在Git中创建一个分支，仅仅是创建一个指向commit对象的指针，所以Git创建分支很快，应该多开分支。在Git中这种指向对象的指针被定义为“引用”。最终我们可以想象一下Git整个内部的指向结构，大概如下图：

![](/image/git_yuan_li__yi_ge_kv_wen_jian_cun_chu_xi_tong/03cc71b3da7ca6dedf8dd911b80c91055843e1bb2fe3c5a0233af6037636c9f3)

