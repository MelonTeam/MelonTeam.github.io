---
layout: post
title: " What's New in LLVM 9"
date: 2017-07-22 15:00:00 +0800
categories: ios
author: rebootyang
tags: LLVM 静态分析 编译 检查
---

* content
{:toc}

| 导语 这**绝不仅仅**是一篇 WWDC 2017 Session 411 学习笔记。除了有关 LLVM 9.0 的新特性之外，还有关于静态分析器和
Clang 5 Objective-C ARC 的一点看法和经验。

我觉得 LLVM 9 的亮点如下：

<!--more-->
  1. 支持 Objective-C API 可用性检查
  2. 新增一些对隐患代码的静态分析检查和 warning
  3. 更快的 LTO，使其可以真正使用

## API Availability Checking for Objective-C

在低版本系统上调用高版本 SDK 的 API 会引发 crash，所以在兼容多版本系统时需要谨慎判断系统版本，然后使用对应的
API。这些在运行时才能生效的代码很容易编写出错，而且需要测试人员付出很大工作量来覆盖到各个版本的系统。检查类、实例方法、类方法等是否可用时需要写的代码也不同，很蛋疼呦。

Swift 3 加入了 `#available` 语法来检查 API 是否可用，在编译阶段就可以发现哪里漏掉了 API
可用性检查。如今，Objective-C 也有这项功能啦。

### Objective-C

假设加入 App 支持的最低版本是 iOS 10，但是直接调用了 iOS 11 的 API，那么编译器会告警，提醒开发者某个 API
只能用于较新版本的系统上。这时需要通过 `[@available](https://github.com/available "@available" )`
语法来判断平台和版本：

    
    
    if(@available(iOS 11, *)) {
        // iOS 11 以上以及其他所有平台
    }
    

`*` 相当于通配符，代表所有其他平台都可用。

说完了如何检查 API 可用性后，再来谈谈声明 API 可用性的问题：

    
    
    - (void)foo API_AVAILABLE(ios(11.0));
    

上面的代码声明了调用 `foo` 方法需要 iOS 11 以上，而 `foo` 方法内部的实现中调用 iOS 11 的 API 时无需再用
`[@available](https://github.com/available "@available" )` 检查。

声明一个类的可用性也很简单，并且无需给类中的每个方法再次声明可用性，只需要用到 `API_AVAILABLE` 宏：

    
    
    API_AVAILABLE(ios(11.0))
    @interface MyClassForiOS11OrNewer : NSObject
    - (void)foo;
    @end
    

其实类似的有关 API 兼容版本的宏还有好几个：

    
    
    API_DEPRECATED()
    API_UNAVAILABLE()
    API_DEPRECATED_WITH_REPLACEMENT()
    

### C & C++

如果是想在 C 或 C++ 中查询 API 的可用性，可以使用 LLVM 新加的 `__builtin_available()` 函数：

    
    
    if (__builtin_available(iOS 11, macOS 10.13, *)) {
        // iOS 11 以上或 macOS 10.13 以上平台，以及其他所有平台
    }
    

在 C 或 C++ 中使用 `API_AVAILABLE` 宏之前需要引入头文件

    
    
    #include 
    class API_AVAILABLE(ios(11.0)) MyClassForiOS11OrNewer;
    

### 适用范围

对于旧工程，LLVM 只会对新的 API 进行告警(包含 iOS 11,tvOS 11,macOS 10.13,watchOS 4 以上)。旧的 API
不会被编译器告警，所以不用担心旧项目中已有的代码会产生一大片 warning，只需在采用新 API 的时候加上
`[@available](https://github.com/available "@available" )` 或
`API_AVAILABLE`。也可以选择在 Build Settings 中设置 `Unguarded availability` 为 `YES(All
Versions)` 来检查所有的 API。Xcode 9 新建工程 `Unguarded availability` 项默认为 `YES(All
Versions)`。

## Static Analyzer Checks

除了在 Xcode->Product->Analyze 中开启静态分析检查外，也可以在 Build 过程中进行静态分析检查。只需在编译设置中将
`Analyse During 'Build'` 设为 `YES`。

苹果补充了一些检查项，看了下还都是一不留神就容易犯或者根本没注意到的细节。

### 比较 NSNumber

稍有经验的老司机都懂得 NSNumber 不能直接跟 raw value 直接比较，毕竟前者是类的实例对象，后者是基本类型。然而还是有人会弄错：

    
    
    NSNumber *count = @0;
    NSNumber *check = @YES;
    if (count > 0) {
      NSLog(@"肯定会进到这里，因为 count 不为 nil");
    }
    if (check) {
      NSLog(@"肯定会进到这里，因为 check 不为 nil");
    }
    

现在 LLVM 可以检查出这种情况，也可以关闭这项检查：在编译设置中将 `Suspicious Conversions of NSNumber and
CFNumberRef` 设为 `NO`。

### `dispatch_once()`

Xcode 的 code snippet 很好用，我觉得正常人不会把 `dispatch_once()` 写错吧。

    
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       foo();
    });
    

`onceToken` 只能是全局变量或静态变量，使得指针地址的唯一性保证了 `foo()` 只执行一次。但总有奇葩把 `onceToken`
声明成成员变量，使得指针地址可能会重复，无法保证线程安全地只执行一次。而现在 LLVM 可以检查出这种不规范的使用方式。

当然，想实现线程安全地只执行一次方法，也可以通过加锁和判断标志位的方式来实现。

### `NSMutable` 类型的属性使用 `copy` 内存管理语义

    
    
    @property (nonatomic, copy) NSMutableArray *array;
    

内存管理语义帮开发者自动合成了 `set` 方法的实现，但是当 `copy` 应用到了 `NSMutable`
系列的类上，就会产生问题。因为我们想要的是把新的值 `mutableCopy` 后赋值给属性，然而内存管理语义中只有 `copy` 却没有
`mutableCopy`。而现在 LLVM 可以检查出这种情况。

重写 `set` 方法可以解决此问题:

    
    
    - (void)setArray:(NSMutableArray *)array
    {
        _array = [array mutableCopy];
    }
    

### 一些建议

静态分析能做到在编译阶段发现一些程序员容易疏忽的地方，它只能检查特定场景下的一些被认为不符合规范的行为。也就是说它维护了一个
List，编译的时候一项一项检查是否合符规范，但是这个 List 之外的行为并不能被检查出来，这也就是为什么 LLVM 每年都在向这个 List
新增内容。这个 List 包含了程序员容易犯的代码问题，并且这些问题暗涵很严重的逻辑错误。

  1. 随着 Check List 的不断膨胀，静态分析耗时会增加，对于大中型项目，我并不建议开启每次编译时都进行静态分析检查。建议在每个版本测试阶段定期做静态分析检查。
  2. 不要过于相信静态分析检查。首先它会漏检，Check List 之外的情况根本检查不出来。如果将一些 API 包含在宏定义中或者封装在 C 函数中调用，导致语法复杂，静态分析甚至还会误报。（我曾经碰见过几次静态分析检查出 MRC 下一些内存泄露，但其实间接调用了 `autorelease` 的，根本不会泄露，改为直接调用 `autorelease` 就 OK 了）
  3. 程序员自身应该有一份 Check List，在平时变成变成过程中不断约束自己。比如判断 `NSString` 是否有内容时直接看 `length` 是否大于 0，而不是判断是否为 `nil` 或 `@""`。这跟打游戏是否有意识差不多，写代码也要有『意识流』。

## New Warnings

Xcode 9 的 LLVM 又新增了一百多个 error 和 warning，然而大多数程序员还不是照样忽视 warning 么？可以在编译设置中将
warning 升级成 error。如果是旧的工程，需要升级工程文件到 Xcode 9，然后才能看到这些新增的 warning
设置项。（点击工程->Editor->Validate Settings）

### ARC 中的 Block 捕获参数

    
    
    - (void)validateDictionary:(NSDictionary<NSString *, NSString *> *)dict error:(NSError **)error
    {
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.length > 0) {
                if (error) {
                    *error = [NSError errorWithDomain:@"FishDomain" code:0 userInfo:nil];
                }
            }
        }];
    }
    

ARC 会将 `(NSError **)error` 这种 “out-parameter” 隐式修饰为
`__autoreleasing`，也就是其实会被转化成 `(NSError * __autoreleasing *)error`。（PS：相关知识参考
[Indirect
parameters](http://clang.llvm.org/docs/AutomaticReferenceCounting.html
#indirect-parameters)）

给 `*error` 赋值时，因为它被 `__autoreleasing` 修饰，所以 ARC 下的 Clang 会隐式调用 `retain` 和
`autorelease`。 PS: 相关知识参考
[Semantics](http://clang.llvm.org/docs/AutomaticReferenceCounting.html#semantics)

而 `enumerateKeysAndObjectsUsingBlock:` 方法会在
`[@autoreleasepool](https://github.com/autoreleasepool "@autoreleasepool" )`
里面执行 Block，在迭代逻辑中这样做有助于减少内存峰值。

于是 `*error` 就在 Block 里提前被释放了。Xcode 9 会针对这种情况发出 warning：”Block captures an
autoreleasing out-parameter, which may result in use-after-free
bugs”。解决方案：”Declare the parameter **strong or capture a **block __strong
variable to keep values alive across autorelease pools”

第一个解决方案简单地把参数 `(NSError **)error` 改成 `(NSError *__strong *)error`，这要求调用方也使用
ARC。第二个解决方案是利用 `__block` 让 Block 捕获外部变量，默认是强引用：

    
    
    - (void)validateDictionary:(NSDictionary<NSString *, NSString *> *)dict error:(NSError **)error
    {
        __block NSError *strongError = nil;
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.length > 0) {
                strongError = [NSError errorWithDomain:@"FishDomain" code:0 userInfo:nil];
            }
        }];
        if (error) {
            *error = strongError;
        }
    }
    

关于 Clang 隐式调用 `retain` 和 `autorelease` 更深入的细节如下：

#### Clang 5 中的 Objective-C ARC 方法家族

Objective-C
中有[五大方法家族](http://clang.llvm.org/docs/AutomaticReferenceCounting.html#arc-
method-families)，每个家族都有自己的规矩：`alloc/new/copy/mutableCopy` 四个家族的方法返回的是 “a
retainable object pointer”，而 `init` 家族方法要求必须是实例方法，必须返回 Objective-C 对象。

把一个方法划归到某个方法家族有两种方式：

  1. 按照命名惯例划分方法家族
  2. 使用 `__attribute__((objc_method_family( somefamily )))` 直接指定

如果某个方法不遵循所在家族的规矩，会影响到内存管理，造成内存泄露等后果。（PS：如果是使用第二种方式把不守规矩的方法划归到家族，Clang 会报错。）

ARC 下遵循一套内存管理原则：

  1. `alloc/new/copy/mutableCopy` 家族的方法创建的对象是自己持有的，会被 Clang 隐式标记为 `__attribute__((ns_returns_retained))`。等效于 Foundation 中的宏 `NS_RETURNS_RETAINED`
  2. `init` 家族会被 Clang 隐式标记为 `__attribute__((ns_consumes_self))` 和 `__attribute__((ns_returns_retained))`，用 `NS_REPLACES_RECEIVER` 宏也是等效的。
  3. 不属于任何方法家族的方法会被 Clang 隐式标记为 `__attribute__((ns_returns_not_retained))`，等效于 Foundation 中的宏 `NS_RETURNS_NOT_RETAINED`。

一般情况下 Clang 会帮我们做这些事情，不必给方法声明手动标记这些属性。而且 Clang 会对最终生成的汇编指令进行优化，去掉多余的 `retain`
和 `autorelease`。

ARC 会**视情况**在调用方法时**可能会**添加 `retain`，在方法内部返回时**可能会**添加
`autorelease`，经过优化后很可能会抵消。

`__attribute__` 其实并不是 Objective-C 的语法，而是 Clang 的属性。有关 Clang 的各种属性定义，请查看
[Attributes in Clang](http://clang.llvm.org/docs/AttributeReference.html)

#### 探索方法返回值内存管理的奥秘

先做两种情况的实验，查看汇编代码，并总结：

##### 方法为 `alloc/new/copy/mutableCopy` 家族或方法声明使用 `NS_RETURNS_RETAINED`

    
    
    - (id)newFoo;
    - (id)foo NS_RETURNS_RETAINED;
    
    - (id)newFoo
    {
        return [NSObject new];
    }
    - (id)foo
    {
        return [NSObject new];
    }
    

debug
时从汇编中可以看出：调用方无操作，方法返回时无操作。这显然是优化后的结果。虽然两种方式都能达到优化效果，但更推荐采用让方法加入方法家族，而不是直接使用
`NS_RETURNS_RETAINED` 宏。

##### 普通方法

    
    
    - (id)foo;
    
    - (id)foo
    {
        return [NSObject new];
    }
    

debug 时从汇编中可以看出：调用方调用 `objc_retainAutoreleasedReturnValue()`，方法返回时调用
`objc_autoreleaseReturnValue()`（如果返回值没有赋值给变量，会调用
`objc_unsafeClaimAutoreleasedReturnValue()`）。

##### 优化过程及原理

`objc_retainAutoreleasedReturnValue(value)` 会尝试将之前调用
`objc_autoreleaseReturnValue(value)` 时传入参数 `value` 的所有权（retain
count）传递过来。如果没有在 `value` 上调用过 `objc_autoreleaseReturnValue(value)`，那就调用
`retain`。具体原理通过查看 Objective-C 源码可以得出(我列举的是 objc-709)：

`objc_autoreleaseReturnValue()` 试图优化流程，如果上一层调用方会调用
`objc_retainAutoreleasedReturnValue()` 则直接返回参数，否则调用 `autorelease`:

    
    
    id 
    objc_autoreleaseReturnValue(id obj)
    {
        // ReturnAtPlus1 表示倾向直接把对象返回，这样就不需要调用 objc_autorelease()，优化性能
        if (prepareOptimizedReturn(ReturnAtPlus1)) return obj;
    
        return objc_autorelease(obj);
    }
    
    static ALWAYS_INLINE bool 
    prepareOptimizedReturn(ReturnDisposition disposition)
    {
        assert(getReturnDisposition() == ReturnAtPlus0);
        // __builtin_return_address(0) 获取当前函数返回地址，传入 callerAcceptsOptimizedReturn 判断调用方是否紧接着调用了 objc_retainAutoreleasedReturnValue 或者 objc_unsafeClaimAutoreleasedReturnValue
        if (callerAcceptsOptimizedReturn(__builtin_return_address(0))) {
            // 将标志位 disposition 写入 TLS
            if (disposition) setReturnDisposition(disposition);
            return true;
        }
    
        return false;
    }
    
    static ALWAYS_INLINE void 
    setReturnDisposition(ReturnDisposition disposition)
    {// 向 TLS 中写入 Disposition
        tls_set_direct(RETURN_DISPOSITION_KEY, (void*)(uintptr_t)disposition);
    }
    
    static ALWAYS_INLINE ReturnDisposition 
    getReturnDisposition()
    {// 从 TLS 中读取 Disposition
        return (ReturnDisposition)(uintptr_t)tls_get_direct(RETURN_DISPOSITION_KEY);
    }
    

`callerAcceptsOptimizedReturn()` 函数在不同架构的 CPU 上实现也是不一样的，这是因为不同架构 CPU
的对齐方式不同，偏移量也不同。比如在 arm64 上由于指令对齐方式较好，只需判断函数返回的地址指向的值是不是 `0xaa1d03fd` 即可；而在
x86_64 平台上则要用一大坨代码来判断。有兴趣的可以查看 objc-object.h 文件。

`objc_retainAutoreleasedReturnValue()` 试图查看是否已优化过并直接返回参数，否则 `retain`:

    
    
    id
    objc_retainAutoreleasedReturnValue(id obj)
    {   // 如果之前 objc_autoreleaseReturnValue() 存入的标志位为 ReturnAtPlus1，则直接返回对象，无需调用 objc_retain()，优化性能
        if (acceptOptimizedReturn() == ReturnAtPlus1) return obj;
    
        return objc_retain(obj);
    }
    
    // 负责从 TLS 中取标志位 ReturnDisposition，然后将其重置
    static ALWAYS_INLINE ReturnDisposition 
    acceptOptimizedReturn()
    {
        ReturnDisposition disposition = getReturnDisposition();
        setReturnDisposition(ReturnAtPlus0);  // reset to the unoptimized state
        return disposition;
    }
    

TLS 全称为 Thread Local Storage，是每个线程专有的键值存储。在某个线程上的函数调用栈上相邻两个函数对 TLS
进行了存取，这中间肯定不会有别的程序『插手』。所以 `getReturnDisposition()` 和 `setReturnDisposition()`
的实现比较简单，不需要判断考虑是针对哪个对象的 Disposition 进行存取，因为当前线程上下文中只处理唯一的对象，保证不会乱掉。

### 无参数函数的声明

如果函数没有参数，需要用 `void` 显式声明。否则可能调用方会传入其他类型和数量的参数，在运行时引发 crash。如果用 `void`
显式声明，在编译阶段就会产生 error。

    
    
    int foo() // warning:This function declaration is not a prototype
    int foo(void) // OK
    

## C++ Refactoring

对于一个带有 C++ 或 Objective-C++ 代码的工程来说，想重命名某个类名真的是艰难，Xcode 会提示不支持 C++！现在，各种操作也支持
C++ 咯：

![](/image/what_s_new_in_llvm_9/30b9003b2861fc1e7df1895f5ae263daa3071f7fd8e5161d9e68002b6e8b84f1)

LLVM 的重构代码功能极大节省了开发者的时间。

## Features from C++17

其实这些都是 C++17 的新特性罢了，LLVM 9.0 积极响应支持。可以在编译选项 C++ Language Dialect 中选择使用的 C++
标准库。GNU++17 比 C++17 多了语言扩展。

### Structured Binding

解析 Tuple 可以一句搞定了：

    
    
    std::tuple<int, double, char> compute();
    void run() {
        auto [a, b, c] = compute();
    }
    

甚至也可以解析类似 tuple 的类型：

    
    
    struct Point { double x; double y; double z; };
    Point computeMidPoint(Point p1, Point p2);
    ...
    auto [x, y, z] = computeMidPoint(src, dest);
    

更多内容详见 C++17 的 [Stuctured Binding](http://www.open-
std.org/jtc1/sc22/wg21/docs/papers/2016/p0217r3.html)。

### 在条件判断语句中声明初始化变量

在判断某个条件之前，可能会产生一些中间变量，如果变量名与外界的有冲突，还会造成一些影响。所以需要一种只在条件判断语句范围内生效的局部变量，避免与无关逻辑代码有冲突：

    
    
    if (auto a = getNumber(); a > 0) 
        foo();
    
    ...
    
    a = 5; // error! a 只在上面的 if 作用域中有效。
    

### constexpr if

以 `if constexpr` 开始的语句被称为 `constexpr if` 语句。—
[cppreference.com](http://zh.cppreference.com/w/cpp/language/if)

举个栗子：`advance` 函数可以向前或向后迭代指定步数，但对于字符串和数组来说有更快的方式：无需一步步迭代，可以直接访问。但 `advance`
的参数是通用的，编译不通过：

![](/image/what_s_new_in_llvm_9/fff453d1c2d1dfee5f46d607c415285c4c01341b786186c8484dd4af6b9b339b)

传统解决方法是 Compile Time Dispatch：

![](/image/what_s_new_in_llvm_9/f221e33d84ba447b1543a97024fd07f5fa81bcd8a7cd1c9d5b241e8162a4057c)

C++17 的 `constexpr if` 可以一行搞定：

![](/image/what_s_new_in_llvm_9/fe356a4a80101e208f69d1b80194284865745b0b799bbc4e240f34b842909923)

详见 [constexpr if](http://www.open-
std.org/jtc1/sc22/wg21/docs/papers/2016/p0292r2.html)。

### string_view

简单来说它是指向字符串的指针，但不会拷贝一份字符串。一旦指向的字符串被修改或者被释放了，`string_view`
的内容也会跟跟着变，毕竟是同一份内存。所以，虽然会优化性能，慎用。就像 OC 中的字符串和数组传递赋值时一般都 `copy`，string_view
相当于是 `assign`，搞不好野指针呢。

详见 [string_view](http://www.open-
std.org/jtc1/sc22/wg21/docs/papers/2015/n4480.html#string.view)。

## Link-Time Optimization

去年搞了个 LTO 和 增量 LTO，今年优化得编译速度更快了，于是建议我们打开 增量 LTO 啊：在编译选项中 Code Generation-&gt
;Link-Time Optimization

其实我看了 [2016 年的 What’s New in
LLVM](https://developer.apple.com/videos/play/wwdc2016/405/), LTO
确实占了很大篇幅，不过当时还不建议开启。经过一年的优化后算是修成正果了。

