---
layout: post
title: "Objc 中 “== YES”  的愚蠢行为有多可怕"
date: 2017-11-30 19:29:00 +0800
categories: ios
author: pikachuqiu
tags: BOOL
---

* content
{:toc}



**问题引出：**  
几个星期前，我遇到一个这样的bug，在我的机器上用 debug 环境编译出来的正常运行，但是 RDM 运行出来的总是出现错误。当时排查到的问题代码大致如下：

<!--more-->
    
    
    - (void)tableFootLoadingViewDidTriggerLoading:(MQZoneTableFootLoadingView *)footLoadingView
    {
        [self performSelector:@selector(loadMoreData:) withObject:@(YES) afterDelay:1];
    }
    
    - (void)loadMoreData:(BOOL)isRefresh
    {
        if (isRefresh == YES)
        {
            //...
        }
        else 
        {
            //...
        }
    }
    

大致的排查 bug 情况是我发现无论如何，从 `performSelector` 进入到的 `loadMoreData` 的时候，参数
`isRefresh` 永远是 NO。

**问题解决：**  
当时，我猜测，这里 @(YES) 发生了一次把 YES 转换为 `NSNumber` 的操作, 然后进入到 `loadMoreData`
的时候做了一层隐式转换，变成了 `BOOL` 类型，并且，这层转换对于我们来说是一个黑盒子。所以，这里出错的可能性极大。  
另外， `isRefresh` 参数和 `YES` 进行直接比较，这里的代码似乎有点问题。通过修改这两处地方，bug 得到了很好的解决，修改后的代码：

    
    
    - (void)tableFootLoadingViewDidTriggerLoading:(MQZoneTableFootLoadingView *)footLoadingView
    {
        [self performSelector:@selector(loadMoreData:) withObject:@(0) afterDelay:1];
    }
    
    - (void)loadMoreData:(NSNumber *)refreshNum
    {
        BOOL isRefresh = [refreshNum integerValue] != 0;
        if (isRefresh)
        {
        }
        else 
        {
        }
    }
    

这里，我修改了两个地方。  
1、参数由 `BOOL` 改为 `NSNumber`, 去除了那层对我们不可见的隐式转换  
2、取消了 `isRefresh == YES` 的代码，改为 `if (isRefresh)`

**问题分析：**

在 Objc 中，表示真假的有 `BOOL`、`bool`、`Boolean`, 其实 `bool` 与 `Boolean` 均是 `C` 与 `C++`
语言更为通用。

三者的区别：

类型 | 定义 | 头文件 | 真 | 假  
---|---|---|---|---  
bool | _Bool (int) | stdbool.h | true | false  
Boolean | unsigned char | MacTypes.h | TRUE | FALSE  
BOOL | signed char | objc.h | YES | NO  
  
其中，最大的区别在于 `BOOL` 被定义为了 `signed char`，`signed char` 的取值范围为 -127～128。

**一：`== YES` 导致问题**

  * 测试环境 Xcode 9.1:

下面代码输出了 NO：

    
    
    int main(int argc, char * argv[])
    {
        if (2 == YES)
        {
            NSLog(@"YES");
        }
        else
        {
            NSLog(@"NO");
        }
    }
    

下面的代码输出 YES

    
    
    int main(int argc, char * argv[])
    {
        if (2)
        {
            NSLog(@"YES");
        }
        else
        {
            NSLog(@"NO");
        }
    }
    

第二段代码输出 `YES` 是很显然的，但是第一段代码为何输出了 `NO`, 为此，我们可以输出 YES, 看结果是啥

    
    
    NSLog(@"%d", YES);  //结果输出了 1
    

所以，答案是显而易见的，2 怎么可能 == 1 呢，所以 这里的第一段代码输出了 1。

**二：不同机型上的问题**

  * 测试环境 Xcode 9.1, iPhone 5（注意 5s 为 64位） 与 iPhone 6 模拟器:

下面的代码在 32 位机器上 NO, 64 位机器上输出 YES

    
    
    int main(int argc, char * argv[])
    {
        BOOL result = 2;
        if (result == YES)
        {
            NSLog(@"YES");
        }
        else
        {
            NSLog(@"NO");
        }
    }
    

下面代码在 32 位与 64 位机器中，均输出 YES

    
    
    int main(int argc, char * argv[])
    {
        BOOL result = 2;
        if (result)
        {
            NSLog(@"YES");
        }
        else
        {
            NSLog(@"NO");
        }
    }
    

第二个结果明显是正确的，但是第一个又是为什么产生差异呢？  
让我们看看 YES 的定义：

    
    
    #define OBJC_BOOL_DEFINED
    
    #if __has_feature(objc_bool)
    #define YES __objc_yes
    #define NO  __objc_no
    #else
    #define YES ((BOOL)1)
    #define NO  ((BOOL)0)
    #endif
    

首先是宏 `__has_feature(objc_bool)`, 通过下面的代码

    
    
    #if __has_feature(objc_bool)
        NSLog(@"YES = __objc_yes");
    #else
        NSLog(@"YES = 1");
    #endif
    

我发现 32 位 和 64 位机器，都运行了 `NSLog(@"YES = __objc_yes");`，也就是说 32 位 和 64 位 YES
都被定义为了 `__objc_yes`

很遗憾，我没有找到 `__objc_yes` 的定义，但是我们可以简单的把它打印出来看看结果，

    
    
    NSLog(@"%d", __objc_yes);
    

输出结果均为 1

但是，我们通过编译器的警告，可以看到 `__objc_yes` 在 32 位和 64 位机器的不同：

32位机器：  

![](/image/objc_zhong___yes__de_yu_chun_xing_wei_you_duo_ke_pa/7621bdcb87f136f4a010659d0f9f31413aacb07a7f77a671b3fcb462dba9d67f)

  
64位机器：  

![](/image/objc_zhong___yes__de_yu_chun_xing_wei_you_duo_ke_pa/d24218bd5b777acf7052d8527c16a86507dc8b1333dffd561aacaa652bd68e3f)

这就解释了上面那段代码在两种不同机器上输出结果不一致的问题了：

在 64 位机器上， `__objc_yes` 就是 bool 类型的某一个值，那么在 C++ 中，任何非 0 的值就是 true，所以，在 64
位机器上，`result == YES` 的代码能够顺利执行。  
但是在 32 位机器上，`__objc_yes` 是一个 `signed char`，并且 = 1，2 == 1 这个逻辑显然过不去，所以这里会导致 32
位和 64 位代码的不同运行结果。

但是，到了这里，我好奇一点：在 64 位机器上，为何 `(2 == YES)` 无法通过 但是 `result = 2; result == YES`
却可以通过呢？

于是，我运行了下面代码

    
    
    BOOL result = 2;
    NSLog(@"%d", result);
    

上述代码在 32 位机器上输出了 2， 在 64 位机器上输出了 YES, 这也就解释了上面的问题，也就是说，真正起作用的其实是 BOOL = int
这一层隐式转换。这一层，对我们来说是黑盒子，而且在 64 位与 32 位机器的表现不一致。

