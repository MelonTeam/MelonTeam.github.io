---
layout: post
title: "C++搬砖民工学习Go语言"
date: 2017-11-29 16:40:00 +0800
categories: 其他
author: xiaomao
tags: C++ go语言
---

* content
{:toc}

| 导语 go语言

由于项目需要，最近开始接触Go语言。从C++程序员的角度来看看go语言的新特性，谈谈自己的感触。


<!--more-->

【1】语法后置，为啥这么搞？

刚接触Go语言，常常会很疑惑为什么这门语言的声明语法会和传统的C家族语言不同。Go的语法，如变量、函数的声明和定义，和我们常见的语言语法相比，都是类型后置，这点着实有些不习惯。为啥要这么搞？

    Rob Pike 曾经在 Go
官方博客解释过这个问题：不是为了与众不同，而是为了更加清晰易懂。特别是当类型比较复杂时，Go的类型语法要比C的容易懂。



【2】多重赋值和多返回值

多重赋值的典型用法，交换2个变量的值：

x,y := 1,2

x,y = y,x //交换x,y



对c++来说，要实现函数返回多个数据，要么封装一个结构体，要不就只能通过函数传参实现。但再Go语言里，直接返回，多直接。举个例子来说明多返回值的用法：

func swapAndAdd(x, y int) (int, int, int) {

    if x > y {

        x,y = y,x

    }

    return x,y, x+y

}



【3】错误处理

GO语言引入了内置的错误（error）类型以及defer关键字来编写异常安全代码。多返回值应用最多的场景就是第二个参数传回函数的错误状态，比如以下用法：

if inFile, err := os.Open(filename); err != nil {

    /* 错误处理 */

}

defer inFile.Close()



C/C++对错误的处理一般都是通过错误码来确定一个函数是否正确调用，因此相比C/C++而言，go的错误处理代码更简洁，看上去也美观。

Go引入了3个关键字（defer、panic和
recover）用于标准的错误处理流程；defer关键字的引入，保证错误处理的代码在发现错误时一定能够被调用，不会因为业务分支逻辑上的修改而漏调。



【4】接口

Go语言的接口，并不是我们在Java中看到的接口。在Go语言中，接口是一个自定义类型，它声明了一个或多个方法签名。接口是完全抽象的，不能将其实例化。如果某个具体类型实现了某个接口所有的方法，那么这个类型就被认为实现了该接口。下面给一个测试用例：

package main



import (

    "fmt"

)



type Exchanger interface {

    Exchange()

}



type StringPair struct {

    first, second string

}



func (pair *StringPair) Exchange() {

    pair.first, pair.second = pair.second, pair.first

}



func exchangeFunc(exchagers...Exchanger) {

    for _, exchanger := range exchagers {

        exchanger.Exchange();

    }

}



func main() {

    str := StringPair{"A", "B"}

    fmt.Println("[1]", str) //{A B}



    str.Exchange();

    fmt.Println("[2]", str) //{B A}



    exchangeFunc(&str)

    fmt.Println("[3]", str) //{A B}

}



【5】并发编程

Go语言层面支持协程，将并发业务逻辑从异步转为同步，大幅提高开发效率。在C++中，做并发编程目前主流的方案是事件驱动（单线程/多线程/多进程模型等)，而事件驱动就需要一个IO多路复用的分发器（select/epoll）。这样，就造成了业务逻辑的断开，在代码层面为异步模型，比如：

1).先是一段业务代码；

2).调用IO；

3).IO完成后的后续处理逻辑；

而go中的协程的支持让这样的开发工作就轻松多了，按照同步的方式顺序写业务逻辑，遇到IO也没关系，一个线程中可以创建成上百万个协程，这个协程阻塞了就跑下一个，不需要应用代码层面来负责IO后续调度的处理。

比起自己用C/C++去封装底层或调用libevent之类的库，Go的优势是将事件机制封装成了CSP模式，编程变得方便了，但是需要付出goroutine调度的开销。



【6】垃圾回收

Go有了垃圾回收机制，不需要开发者自行控制内存的释放，这样可避免一堆问题（重复释放、忘记释放内存、访问已释放的内存等）。当然，C++11引入的智能指针（unique_ptr等）如果在程序中应用的普遍，也可以达到类似垃圾回收的目的。

