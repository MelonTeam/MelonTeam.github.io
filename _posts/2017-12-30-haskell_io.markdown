---
layout: post
title: "Haskell IO"
date: 2017-12-30 16:46:00 +0800
categories: android
author: siriushe
tags: haskell
---

* content
{:toc}



Haskell是一门纯函数式语言，所谓的纯函数式有一个非常重要的特征，那就是函数没有副作用。这里引用维基上面对于函数副作用的定义：

“在计算机科学中，**函数副作用**指当调用[函数](https://zh.wikipedia.org/wiki/%E5%87%BD%E6%95%B0
<!--more-->
"函数" )时，除了**返回函数值**之外，还**对主调用函数产生附加的影响**。例如修改全局变量（函数外的变量）或修改参数。”

之前了解的Haskell的函数输入和输出都对应着固定的映射规则，固定的输入会产生必然的输出，这种无副作用性保证了程序设计本身的稳健性。但是程序是用来描述事物的运行规则，因此描述事物的状态也是无可避免，纯函数无法用来修改状态，因为状态是一种全局的属性，对状态的读写会产生副作用。

这样说的比较抽象，举个例子。纯函数无法做到从文件（比如数据库）中读取一个字符串，然后把它输出出来。我们没法保证两次调用这个函数输出都是一样的，因为强哥可能趁你下班的时候偷偷改了你的文件，那输出就变了。

Haskell为了兼容这种需求，引入了IO action的概念，并且设置了相应的语法糖。因此Haskell将函数类型分割成两类，一类是IO
action，一类是纯函数。IO action负责做IO交互，他是不纯的，而纯函数是纯粹无副作用的，两者边界明确。

我们来看下一个例子

    
    
    main = do  
     putStrLn (showNum 2)  
      
    showNum::Int -> String  
    showNum a = "num -> " ++ (show a)

这个例子里面定义了两个函数main和showNum，其中showNum是纯函数，输入一个数字，输出一个字符串。而main函数因为涉及IO操作，所以是不纯的。

![](/image/haskell_io/54a0d6939dc5c3bb7a5a3533d4be44271457ad35c5e79170e33c27122c59b7d0)

我们来看下putStrLn这个函数的类型，输入一个String，输出一个IO()，这里面IO()既是IO
action，表示一次IO操作，在我们这个场景里面即“输出到屏幕”的操作。

这个例子里面还用了**do**的关键词，这个关键词将多个IO action打包在一起,形成一个大的IO action。

    
    
    main = do
    	str format::String -> String
    format str = "str -> " ++ str

 比如上面这个例子，就包含getLine和putStrLn两个IO操作，需要用do包含起来。

