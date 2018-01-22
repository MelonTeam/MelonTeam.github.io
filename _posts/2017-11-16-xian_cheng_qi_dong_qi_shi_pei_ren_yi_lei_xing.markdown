---
layout: post
title: "线程启动器适配任意类型"
date: 2017-11-16 11:41:00 +0800
categories: 后端
author: tangfutang
tags: yaaf 适配 sfinae
---

* content
{:toc}



框架的线程启动器start以前只能启动继承自common::Runnable的类（以一个线程去run这个任务类），这在绝大部分的业务代码中都是合理的；但有时候你需要写一个工具或者一个简单的任务处理（比如一个函数），再去继承一个Runnable就显得略微繁琐了些。基于次背景我们决定扩充下start的能力。_**  
  

<!--more-->

_**1\. 实现功能 - start_any**_  
c++11的thread支持传统C函数，C++成员函数，函数对象（实现了（）运算符的类的实例），lambda表达式（特殊函数对象）等作为参数传入，极大的简化了代码。  

    
    
    template <typename Callable, typename... Args> 
    start_any(Callable&& fn, Args&&... args) 
    { 
        std::thread *t = new std::thread(std::forward(func), std::forward(args)...); 
        std_threads_.push_back(t); 
    }



_**2\. 老接口融合 - SFINAE**_  
start_any的名字对开发来说比较陌生，如果能统一用start来启动会更加便利。函数名称相同的情况下问题就落在如何区分传入参数是Runnable的继承类这个问题上了，既然用了模板，那么就应该能使用“模板替换不是一个错误”原则来规避。  

    
    
    template <typename Callable, 
    typename... Args, 
    typename = typename std::enable_if < !std::is_base_of<:common::runnable class="hljs-keyword">typename std::remove_pointer::type>::value >::type > 
    start(Callable&& fn, Args&&... args)
    {
        std::thread *t = new std::thread(std::forward(func), std::forward(args)...); 
        std_threads_.push_back(t); 
    }



_**3\. 兼容所有形式 - std::decay**_  
上面的版本，发现在某些场景中is_base_of判断会失效，原因是模板类型没有“清洗”干净，比如const T& 跟
T不是一个类型，使用decay退化掉所有修饰验证通过。  

    
    
    typename = typename std::enable_if < !std::is_base_of<:common::runnable class="hljs-keyword">typename std::remove_pointer<typename std::decay::type>::type>::value >::type







