---
layout: post
title: "聊聊kotlin中的run, let, with, apply, also ..."
date: 2017-08-31 18:02:00 +0800
categories: android
author: vashzhong
tags: block kotlin extension 解读
---

* content
{:toc}

| 导语 kotlin 标准库中, run, let, with, apply, also 实现解读

在看kotlin代码时, 可能会看到let, run这样的函数调用, 最早接触的时候, 我也弄不清楚其中差异, 觉得用法这么像, 为什么弄出多个名字,
不过仔细看看嘛, 还是略有不同的, 待我慢慢道来.

<!--more-->
> kotlin中, `run`, `let`, `with`, `apply`, `also`, 都是标准库的函数, 它的实现可以直接在IDE上跳转看到,
也可以在这里看:
[Standard.kt](https://github.com/JetBrains/kotlin/blob/master/libraries/stdlib/src/kotlin/util/Standard.kt)

看这些函数的实现, 会发现它们非常短, 最多不超过两行.. 我们一个一个看过去吧

# 方法解读

## run函数(两个定义):

    
    
    - public inline fun  run(block: () -> R): R = block()
    - public inline fun  T.run(block: T.() -> R): R = block()
    

第一个函数run, 接受一个参数, 参数类型是签名”() -> R”的函数, 这里也被称为block. 执行的结果就是执行这个block,
并返回R类型的对象. 这里的上下文this和run()方法被调用时候的this一致.

第二个函数, 看起来和第一个函数非常像, 但是多了一个泛型参数T.., 它是kotlin的extension的一个用法:

确切说, 这个run是一个generic extension函数, 对于任何类型T, 扩展了run这个方法, 参数类型是签名”T.() ->
R”的函数..  
这个函数的上下文this和第一个run不同, 上下文对应T这个类型的实例this. 关于kotlin extension的更详细介绍, 可以查看官网文档

this上下文差异是这两个run用法最大的不同

## let函数

    
    
    - public inline fun  T.let(block: (T) -> R): R = block(this)
    

let extension函数看起来是不是有点像是两个run函数的混合?  
为什么说是混合:

  1. let的函数参数block中, 对应的上下文this和第一个run函数是一致的
  2. let和第二个run函数一样是一个extension函数, 但是它的block参数支持一个参数, 就是任意类型T的实例, 在extension函数定义时候, “this”就对应扩展类型实例.

所以使用let函数时, block可以同时访问两个this上下文差异

## with函数

    
    
    - public inline fun  with(receiver: T, block: T.() -> R): R = receiver.block()
    

with函数不是一个extension函数, 它第二个参数是一个函数类型, 所以可以用with(x) { BLOCK } 的写法.
这个BLOCK和run函数的extension函数版本的block参数, 是等价的.

## apply函数, also函数

    
    
    - public inline fun  T.apply(block: T.() -> Unit): T { block(); return this }
    - public inline fun  T.also(block: (T) -> Unit): T { block(this); return this }
    

剩下apply和also两个函数, 他们和run, let的实现又非常相似  
apply和T.run的block参数的上下文一致  
also和T.let的block参数的上下文一致  
只是返回值和run/let有所区别.

# 示例代码

解读完了, 来一段示例代码

    
    
    import org.junit.Test
    
    /**
     * Created by vashzhong on 2017/7/27.
     */
    class TestDemo {
        val str: String = "str(class val)"
    
        @Test fun playWithStandard() {
            val str = "str(function val)"
            var number = 0
            var ret = 0
    
            println("run:")
            ret = run {
                number++
                println("str = $str")
                println("this = $this")
                println("this.str = ${this.str}")
                0
            }
            println("ret = $ret, number = $number")
    
            println("T.run:")
            ret = number.run {
                number++
                println("str = $str")
                println("this = $this")
                1
            }
            println("ret = $ret, number = $number")
    
            println("T.let:")
            ret = number.let {
                println("str = $str")
                println("it = $it")
                println("this = $this")
                println("this.str = ${this.str}")
                2
            }
            println("ret = $ret, number = $number")
    
            println("with(T):")
            ret = with(number) {
                number++
                println("str = $str")
                println("this = $this")
                3
            }
            println("ret = $ret, number = $number")
    
            println("apply:")
            ret = number.apply {
                number++
                println("str = $str")
                println("this = $this")
                4
            }
            println("ret = $ret, number = $number")
    
            println("also:")
            ret = number.also {
                number++
                println("str = $str")
                println("it = $it")
                println("this = $this")
                println("this.str = ${this.str}")
                5
            }
            println("ret = $ret, number = $number")
        }
    }
    

理解它的输出, 应该就对run, let, with, apply, also的差异完全明了

# 思考

  1. 在上边的实例代码中, T.run, T.apply, with(T)对应的block中, 怎么拿到TestDemo实例里边的str这个String? “str(class val)”
  2. 为什么T.run对应的block中, number++了, 但是println(“this = $this”)输出结果没有增加?
  3. 有什么办法看到和kotlin代码等价的java代码?

# 参考链接

  * The difference between Kotlin’s functions, KM的md语法链接解析有bug, 不支持url里边带`@`,直接提出来不链接了  "@tpolansk" )/the-difference-between-kotlins-functions-let-apply-with-run-and-else-ca51a4c696b8`
  * [Kotlin Basics: Standard Extension Functions](https://lmller.github.io/kotlin-standard-extensions)

