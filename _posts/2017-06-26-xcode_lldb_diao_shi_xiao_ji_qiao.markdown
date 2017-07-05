---
layout: post
title: "xcode lldb调试小技巧"
date: 2017-06-26 11:27:00
categories: android
author: chaodong
tags: 调试 小技巧
---

* content
{:toc}

| 导语 记录平时用到的xcode lldb调试小技巧

工欲善其事必先利其器，介绍一些lldb调试的命令和小技巧~

# 基础篇
<!--more-->

### 1.print命令

p 输出基本类型，例如double，int  
po 输出对象类型，例如nsobject  
当然po也是可以输出基本类型的  
p命令默认是按10进制输出的，如果想输出非十进制可以用以下方法

二进制

    
    
    (lldb) p/t 10
    (int) $2 = 0b00000000000000000000000000001010
    

八进制

    
    
    (lldb) p/o 10
    (int) $3 = 012
    

十六进制

    
    
    (lldb) p/x 10
    (int) $4 = 0x0000000a
    

更加详细的格式控制可以点击[这里](https://sourceware.org/gdb/onlinedocs/gdb/output-
formats.html)查看

### 2.expression命令

顾名思义这个是命令可以在控制台执行一条语句  
比如  
expr i = 5，把5赋值给i  
还有一种方式 po i = 5，也是有一样的效果的，都是让i的值变成5

### 3.设置断点

给某个类的某个oc方法下断点  
br set -n “方法描述”

    
    
    (lldb) br set -n "[nsstring stringwithformat:]"
    breakpoint 2: where = foundation`+[nsstring stringwithformat:], address = 0x000000010e292832
    

给所有类的某一selector下断点  
br set -s **selector**

    
    
    (lldb) br set -s initwithframe:
    breakpoint 4: 260 locations.
    

断点列表查看  
br list

    
    
    (lldb) br list
    current breakpoints:
    5: name = 'initwithframe:', locations = 260, resolved = 260, hit count = 0
      5.1: where = uikit`-[_uipickerviewtopframe initwithframe:], address = x000000010ec60584, resolved, hit count = 0 
      5.2: where = uikit`-[_uionepartimageview initwithframe:], address = x000000010ec60a53, resolved, hit count = 0 
      5.3: where = uikit`-[_uipickerviewselectionbar initwithframe:], address = x000000010ec60c6c, resolved, hit count = 0 
      5.4: where = uikit`-[_uipickerwheelview initwithframe:], address = x000000010ec60e3a, resolved, hit count = 0 
      5.5: where = uikit`-[uipickerview initwithframe:], address = x000000010ec61bdf, resolved, hit count = 0 
      5.6: where = uikit`-[_uiparallaxdimmingview initwithframe:], address = x000000010ec70137, resolved, hit count = 0
    

删除全部断点  
br del

    
    
    (lldb) br del
    about to delete all breakpoints, do you want to do that?: [y/n] y
    all breakpoints removed. (4 breakpoints)
    

删除某个断点  
br del 断点index（断点list里前面的x.x，例如6.1）

    
    
    (lldb) br delete 6.1
    0 breakpoints deleted; 1 breakpoint locations disabled.
    

也可以按组删除，直接输入组号就可以

    
    
    (lldb) br delete 6
    1 breakpoints deleted; 0 breakpoint locations disabled.
    

### 4.设置观察点

我们有时候想知道某个变量是否发生改变了，可以通过设置观察点的方式监控

    
    
    (lldb) watchpoint set var self->_testa
    watchpoint created: watchpoint 1: addr = 0x7fda62504708 size = 4 state = enabled type = w
        watchpoint spec = 'self->_testa'
        new value: 0
    

这样当有变化的时候便会断下来，控制台会输出如下

    
    
    watchpoint 1 hit:
    old value: 0
    new value: 5
    

默认的命令只监测write，如果读也想监测的话可以这样

    
    
    (lldb) watchpoint set var -w read_write self->_testa
    watchpoint created: watchpoint 1: addr = 0x7fc181c04238 size = 4 state = enabled type = rw
        watchpoint spec = 'self->_testa'
        new value: 0
    

当然也可以管理watchpoint  
watchpoint list //列出所有的watchpoint  
watchpoint del //删除所有的watchpoint

### 5.打印当前显示的viewcontroller

po [[[uiapplication sharedapplication] keywindow] recursivedescription]

### 6.打印当前屏幕上的view

po [[[[uiapplication sharedapplication] keywindow] rootviewcontroller]
_printhierarchy]

### 7.沙盒路径

po nshomedirectory()

### 8.某些时候无法print frame

p (cgrect)[self.view frame]

### 9.thread命令

有时候我们想让某个函数在调试的时候直接返回yes  
可以断点到函数开头，然后执行以下语句  
thread return yes

# 提高篇

### 1.image命令使用

平常我们出现crash的时候总会有如下输出

    
    
    2017-06-24 18:21:49.053 test[2419:11812168] *** terminating app due to uncaught exception 'nsinvalidargumentexception', reason: '-[nsobject xxx:]: unrecognized selector sent to instance 0x61000000c130'
    *** first throw call stack:
    (
        0   corefoundation                      0x000000010c870b0b __exceptionpreprocess + 171
        1   libobjc.a.dylib                     0x000000010a40b141 objc_exception_throw + 48
        2   corefoundation                      0x000000010c8e0134 -[nsobject(nsobject) doesnotrecognizeselector:] + 132
        3   corefoundation                      0x000000010c7f7840 ___forwarding___ + 1024
        4   corefoundation                      0x000000010c7f73b8 _cf_forwarding_prep_0 + 120
        5   test                                0x0000000109e3d74c -[viewcontroller viewdidload] + 108
        6   uikit                               0x000000010aa8001a -[uiviewcontroller loadviewifrequired] + 1235
        7   uikit                               0x000000010aa8045a -[uiviewcontroller view] + 27
        8   uikit                               0x000000010a94898a -[uiwindow addrootviewcontrollerviewifpossible] + 65
        9   uikit                               0x000000010a949070 -[uiwindow _sethidden:forced:] + 294
        10  uikit                               0x000000010a95bebe -[uiwindow makekeyandvisible] + 42
        11  uikit                               0x000000010a8d537f -[uiapplication _callinitializationdelegatesformainscene:transitioncontext:] + 4346
        12  uikit                               0x000000010a8db5e4 -[uiapplication _runwithmainscene:transitioncontext:completion:] + 1709
        13  uikit                               0x000000010a8d87f3 -[uiapplication workspacedidendtransaction:] + 182
        14  frontboardservices                  0x000000010df805f6 __fbsserialqueue_is_calling_out_to_a_block__ + 24
        15  frontboardservices                  0x000000010df8046d -[fbsserialqueue _performnext] + 186
        16  frontboardservices                  0x000000010df807f6 -[fbsserialqueue _performnextfromrunloopsource] + 45
        17  corefoundation                      0x000000010c816c01 __cfrunloop_is_calling_out_to_a_source0_perform_function__ + 17
        18  corefoundation                      0x000000010c7fc0cf __cfrunloopdosources0 + 527
        19  corefoundation                      0x000000010c7fb5ff __cfrunlooprun + 911
        20  corefoundation                      0x000000010c7fb016 cfrunlooprunspecific + 406
        21  uikit                               0x000000010a8d708f -[uiapplication _run] + 468
        22  uikit                               0x000000010a8dd134 uiapplicationmain + 159
        23  test                                0x0000000109e3da7f main + 111
        24  libdyld.dylib                       0x000000010d81065d start + 1
        25  ???                                 0x0000000000000001 0x0 + 1
    )
    libc++abi.dylib: terminating with uncaught exception of type nsexception
    

我们可能一眼看不出是-[viewcontroller viewdidload]的第几行crash了，这个时候我们可以使用image lookup命令

    
    
    (lldb) image lookup -a 0x0000000109e3d74c
          address: test[0x000000010000174c] (test.__text.__text + 108)
          summary: test`-[viewcontroller viewdidload] + 108 at viewcontroller.m:22
    

这样子就很容易看出是第22行crash了

### 2.野指针调试

一般野指针调试大家可能都是用zombie objects，但autoreleasepool里面的crash用zombie可能看不出来问题  
这里我们介绍另外一种野指针调试方法malloc history  
malloc
history可以输出某一地址的malloc和free记录，从中我们可以得到一些有用信息帮助我们定位问题，比如mrc下赋值的时候没有retain导致用的时候野指针了。

首先要打开malloc stack选项  
![](/image/xcode_lldb_diao_shi_xiao_ji_qiao/543f52df5a0c5ca1aa6a8a72a7da82ab108b815a335c3dafe5bb91f9fc3bb86e)

然后我们写个简单的程序

    
    
    - (void)viewdidload {
        [super viewdidload];
        nsdate *date = [[nsdate new] autorelease];
        [date release];
    }
    

执行一下  
![](/image/xcode_lldb_diao_shi_xiao_ji_qiao/bf5d97711fda59ef58c90bffd06861a3e0b89ef742e00a5216ea5794bd6f1fa0)  
如我们所料crash了，但看堆栈和错误log好像没什么线索

我们查看左边crash栈的第0帧

    
    
    #0    0x00000001034abd5b in objc_release ()
    

在控制台输入  
p/x $rdi（$rdi在x64模拟器上是第一个寄存器，也就是指向oc方法中的self）

    
    
    (lldb) p/x $rdi
    (unsigned long) $1 = 0x0000600000005750
    

现在我们拿到self指针了，然后就可以用malloc history来追查了

在控制台中输入  
command script import lldb.macosx.heap，开启相关命令

    
    
    (lldb) command script import lldb.macosx.heap
    "malloc_info", "ptr_refs", "cstr_refs", "find_variable", and "objc_refs" commands have been installed, use the "--help" options on these commands for detailed help.
    

然后输入  
malloc_info —stack-history xxxxxxx（xxxx是地址）  
来查看相应地址的分配记录  
这里我们输入malloc_info —stack-history 0x0000600000005750

    
    
    (lldb) malloc_info --stack-history 0x0000600000005750
    0x0000600000005750: malloc(    16) -> 0x600000005750
    stack[0]: addr = 0x600000005750, type=malloc, frames:
         [0] 0x0000000106a7844a libsystem_malloc.dylib`malloc + 24
         [1] 0x0000000103967ef2 corefoundation`-[__nsarraym insertobject:atindex:] + 242
         [2] 0x0000000102f823c3 foundation`setprotocolmetadatawithsignature + 1051
         [3] 0x0000000102f82323 foundation`setprotocolmetadatawithsignature + 891
         [4] 0x0000000102f81f47 foundation`setprotocolmetdatawithmethods + 370
         [5] 0x0000000102f81d87 foundation`setprotocolmetadata + 194
         [6] 0x0000000102f81cb8 foundation`-[nsxpcinterface setprotocol:] + 87
         [7] 0x0000000102f81be7 foundation`+[nsxpcinterface interfacewithprotocol:] + 56
         [8] 0x000000010fc5dd56 libmobilegestaltextensions.dylib`___lldb_unnamed_symbol104$$libmobilegestaltextensions.dylib + 144
         [9] 0x000000010fc5df4f libmobilegestaltextensions.dylib`___lldb_unnamed_symbol110$$libmobilegestaltextensions.dylib + 34
         [10] 0x000000010fc5e41b libmobilegestaltextensions.dylib`___lldb_unnamed_symbol125$$libmobilegestaltextensions.dylib + 121
         [11] 0x000000010659ca9d libmobilegestalt.dylib`___lldb_unnamed_symbol61$$libmobilegestalt.dylib + 445
         [12] 0x00000001065a5847 libmobilegestalt.dylib`___lldb_unnamed_symbol688$$libmobilegestalt.dylib + 97
         [13] 0x000000010659ca16 libmobilegestalt.dylib`___lldb_unnamed_symbol61$$libmobilegestalt.dylib + 310
         [14] 0x000000010659fbd9 libmobilegestalt.dylib`___lldb_unnamed_symbol302$$libmobilegestalt.dylib + 66
         [15] 0x000000010659ca16 libmobilegestalt.dylib`___lldb_unnamed_symbol61$$libmobilegestalt.dylib + 310
         [16] 0x000000010709795f baseboard`__18-[bsplatform init]_block_invoke + 29
         [17] 0x000000010685105c libdispatch.dylib`_dispatch_client_callout + 8
         [18] 0x00000001068369a1 libdispatch.dylib`dispatch_once_f + 503
         [19] 0x0000000107097940 baseboard`-[bsplatform init] + 89
         [20] 0x00000001070978d9 baseboard`__28+[bsplatform sharedinstance]_block_invoke + 41
         [21] 0x000000010685105c libdispatch.dylib`_dispatch_client_callout + 8
         [22] 0x00000001068369a1 libdispatch.dylib`dispatch_once_f + 503
         [23] 0x00000001070978ad baseboard`+[bsplatform sharedinstance] + 41
         [24] 0x0000000103e665d1 uikit`-[uiapplication _setclassicmode:] + 122
         [25] 0x0000000103e66bc5 uikit`-[uiapplication _fetchinfoplistflags] + 328
         [26] 0x0000000103e4ad5a uikit`-[uiapplication init] + 997
         [27] 0x0000000103e56f80 uikit`uiapplicationinstantiatesingleton + 321
         [28] 0x0000000103e574af uikit`_uiapplicationmainpreparations + 833
         [29] 0x0000000103e57104 uikit`uiapplicationmain + 111
         [30] 0x0000000102ecaac3 test`main + 99 at main.m:14:9
         [31] 0x000000010689d65d libdyld.dylib`start + 1
    
    ......
    
    stack[12]: addr = 0x600000005750, type=malloc, frames:
         [0] 0x0000000106a78485 libsystem_malloc.dylib`calloc + 30
         [1] 0x00000001034a2ba1 libobjc.a.dylib`class_createinstance + 85
         [2] 0x000000010397ddd1 corefoundation`__cfallocateobject + 17
         [3] 0x000000010397dda2 corefoundation`+[__nsdate __new:] + 18
         [4] 0x0000000102eca8cc test`-[viewcontroller viewdidload] + 76 at viewcontroller.m:21:20
         [5] 0x0000000103ffa01a uikit`-[uiviewcontroller loadviewifrequired] + 1235
         [6] 0x0000000103ffa45a uikit`-[uiviewcontroller view] + 27
         [7] 0x0000000103ec298a uikit`-[uiwindow addrootviewcontrollerviewifpossible] + 65
         [8] 0x0000000103ec3070 uikit`-[uiwindow _sethidden:forced:] + 294
         [9] 0x0000000103ed5ebe uikit`-[uiwindow makekeyandvisible] + 42
         [10] 0x0000000103e4f37f uikit`-[uiapplication _callinitializationdelegatesformainscene:transitioncontext:] + 4346
         [11] 0x0000000103e555e4 uikit`-[uiapplication _runwithmainscene:transitioncontext:completion:] + 1709
         [12] 0x0000000103e527f3 uikit`-[uiapplication workspacedidendtransaction:] + 182
         [13] 0x000000010700d5f6 frontboardservices`__fbsserialqueue_is_calling_out_to_a_block__ + 24
         [14] 0x000000010700d46d frontboardservices`-[fbsserialqueue _performnext] + 186
         [15] 0x000000010700d7f6 frontboardservices`-[fbsserialqueue _performnextfromrunloopsource] + 45
         [16] 0x00000001039d9c01 corefoundation`__cfrunloop_is_calling_out_to_a_source0_perform_function__ + 17
         [17] 0x00000001039bf0cf corefoundation`__cfrunloopdosources0 + 527
         [18] 0x00000001039be5ff corefoundation`__cfrunlooprun + 911
         [19] 0x00000001039be016 corefoundation`cfrunlooprunspecific + 406
         [20] 0x0000000103e5108f uikit`-[uiapplication _run] + 468
         [21] 0x0000000103e57134 uikit`uiapplicationmain + 159
         [22] 0x0000000102ecaac3 test`main + 99 at main.m:14:9
         [23] 0x000000010689d65d libdyld.dylib`start + 1
    
    stack[13]: addr = 0x600000005750, type=free, frames:
         [0] 0x00000001034a2d6e libobjc.a.dylib`object_dispose + 30
         [1] 0x000000010399c4a7 corefoundation`-[__nsdate dealloc] + 39
         [2] 0x00000001034acb8e libobjc.a.dylib`objc_object::sidetable_release(bool) + 202
         [3] 0x0000000102eca8f2 test`-[viewcontroller viewdidload] + 114 at viewcontroller.m:23:1
         [4] 0x0000000103ffa01a uikit`-[uiviewcontroller loadviewifrequired] + 1235
         [5] 0x0000000103ffa45a uikit`-[uiviewcontroller view] + 27
         [6] 0x0000000103ec298a uikit`-[uiwindow addrootviewcontrollerviewifpossible] + 65
         [7] 0x0000000103ec3070 uikit`-[uiwindow _sethidden:forced:] + 294
         [8] 0x0000000103ed5ebe uikit`-[uiwindow makekeyandvisible] + 42
         [9] 0x0000000103e4f37f uikit`-[uiapplication _callinitializationdelegatesformainscene:transitioncontext:] + 4346
         [10] 0x0000000103e555e4 uikit`-[uiapplication _runwithmainscene:transitioncontext:completion:] + 1709
         [11] 0x0000000103e527f3 uikit`-[uiapplication workspacedidendtransaction:] + 182
         [12] 0x000000010700d5f6 frontboardservices`__fbsserialqueue_is_calling_out_to_a_block__ + 24
         [13] 0x000000010700d46d frontboardservices`-[fbsserialqueue _performnext] + 186
         [14] 0x000000010700d7f6 frontboardservices`-[fbsserialqueue _performnextfromrunloopsource] + 45
         [15] 0x00000001039d9c01 corefoundation`__cfrunloop_is_calling_out_to_a_source0_perform_function__ + 17
         [16] 0x00000001039bf0cf corefoundation`__cfrunloopdosources0 + 527
         [17] 0x00000001039be5ff corefoundation`__cfrunlooprun + 911
         [18] 0x00000001039be016 corefoundation`cfrunlooprunspecific + 406
         [19] 0x0000000103e5108f uikit`-[uiapplication _run] + 468
         [20] 0x0000000103e57134 uikit`uiapplicationmain + 159
         [21] 0x0000000102ecaac3 test`main + 99 at main.m:14:9
         [22] 0x000000010689d65d libdyld.dylib`start + 1
    
    stack[14]: addr = 0x600000005750, type=malloc, frames:
         [0] 0x0000000106a7844a libsystem_malloc.dylib`malloc + 24
         [1] 0x0000000103961f45 corefoundation`__cfdatainit + 613
         [2] 0x0000000102fba6c9 foundation`-[nsisobjectivelinearexpression init] + 154
         [3] 0x0000000102fba2f0 foundation`-[nsisengine init] + 419
         [4] 0x000000010481a8db uikit`-[uiview(additionallayoutsupport) _initializehostedlayoutengine] + 359
         [5] 0x000000010480d499 uikit`-[uiview(uiconstraintbasedlayout) _layoutengine_windowdidchange] + 130
         [6] 0x0000000103f13909 uikit`-[uiview(internal) _didmovefromwindow:towindow:] + 209
         [7] 0x0000000103f06b96 uikit`__45-[uiview(hierarchy) _postmovedfromsuperview:]_block_invoke + 151
         [8] 0x0000000103f06a7d uikit`-[uiview(hierarchy) _postmovedfromsuperview:] + 828
         [9] 0x0000000103f16a0a uikit`-[uiview(internal) _addsubview:positioned:relativeto:] + 1927
         [10] 0x0000000103f04cf8 uikit`-[uiview(hierarchy) addsubview:] + 838
         [11] 0x0000000103ec2c6f uikit`-[uiwindow addrootviewcontrollerviewifpossible] + 806
         [12] 0x0000000103ec3070 uikit`-[uiwindow _sethidden:forced:] + 294
         [13] 0x0000000103ed5ebe uikit`-[uiwindow makekeyandvisible] + 42
         [14] 0x0000000103e4f37f uikit`-[uiapplication _callinitializationdelegatesformainscene:transitioncontext:] + 4346
         [15] 0x0000000103e555e4 uikit`-[uiapplication _runwithmainscene:transitioncontext:completion:] + 1709
         [16] 0x0000000103e527f3 uikit`-[uiapplication workspacedidendtransaction:] + 182
         [17] 0x000000010700d5f6 frontboardservices`__fbsserialqueue_is_calling_out_to_a_block__ + 24
         [18] 0x000000010700d46d frontboardservices`-[fbsserialqueue _performnext] + 186
         [19] 0x000000010700d7f6 frontboardservices`-[fbsserialqueue _performnextfromrunloopsource] + 45
         [20] 0x00000001039d9c01 corefoundation`__cfrunloop_is_calling_out_to_a_source0_perform_function__ + 17
         [21] 0x00000001039bf0cf corefoundation`__cfrunloopdosources0 + 527
         [22] 0x00000001039be5ff corefoundation`__cfrunlooprun + 911
         [23] 0x00000001039be016 corefoundation`cfrunlooprunspecific + 406
         [24] 0x0000000103e5108f uikit`-[uiapplication _run] + 468
         [25] 0x0000000103e57134 uikit`uiapplicationmain + 159
         [26] 0x0000000102ecaac3 test`main + 99 at main.m:14:9
         [27] 0x000000010689d65d libdyld.dylib`start + 1
    

我们会发现这个地址的分配记录很多，但我主要关心我们自己程序的

    
    
    stack[12]: addr = 0x600000005750, type=malloc, frames:
         [0] 0x0000000106a78485 libsystem_malloc.dylib`calloc + 30
         [1] 0x00000001034a2ba1 libobjc.a.dylib`class_createinstance + 85
         [2] 0x000000010397ddd1 corefoundation`__cfallocateobject + 17
         [3] 0x000000010397dda2 corefoundation`+[__nsdate __new:] + 18
         [4] 0x0000000102eca8cc test`-[viewcontroller viewdidload] + 76 at viewcontroller.m:21:20
         [5] 0x0000000103ffa01a uikit`-[uiviewcontroller loadviewifrequired] + 1235
         [6] 0x0000000103ffa45a uikit`-[uiviewcontroller view] + 27
         [7] 0x0000000103ec298a uikit`-[uiwindow addrootviewcontrollerviewifpossible] + 65
         [8] 0x0000000103ec3070 uikit`-[uiwindow _sethidden:forced:] + 294
         [9] 0x0000000103ed5ebe uikit`-[uiwindow makekeyandvisible] + 42
         [10] 0x0000000103e4f37f uikit`-[uiapplication _callinitializationdelegatesformainscene:transitioncontext:] + 4346
         [11] 0x0000000103e555e4 uikit`-[uiapplication _runwithmainscene:transitioncontext:completion:] + 1709
         [12] 0x0000000103e527f3 uikit`-[uiapplication workspacedidendtransaction:] + 182
         [13] 0x000000010700d5f6 frontboardservices`__fbsserialqueue_is_calling_out_to_a_block__ + 24
         [14] 0x000000010700d46d frontboardservices`-[fbsserialqueue _performnext] + 186
         [15] 0x000000010700d7f6 frontboardservices`-[fbsserialqueue _performnextfromrunloopsource] + 45
         [16] 0x00000001039d9c01 corefoundation`__cfrunloop_is_calling_out_to_a_source0_perform_function__ + 17
         [17] 0x00000001039bf0cf corefoundation`__cfrunloopdosources0 + 527
         [18] 0x00000001039be5ff corefoundation`__cfrunlooprun + 911
         [19] 0x00000001039be016 corefoundation`cfrunlooprunspecific + 406
         [20] 0x0000000103e5108f uikit`-[uiapplication _run] + 468
         [21] 0x0000000103e57134 uikit`uiapplicationmain + 159
         [22] 0x0000000102ecaac3 test`main + 99 at main.m:14:9
         [23] 0x000000010689d65d libdyld.dylib`start + 1
    

看[4]可以发现在-[viewcontroller viewdidload]的第21行malloc了一个对象

    
    
    stack[13]: addr = 0x600000005750, type=free, frames:
         [0] 0x00000001034a2d6e libobjc.a.dylib`object_dispose + 30
         [1] 0x000000010399c4a7 corefoundation`-[__nsdate dealloc] + 39
         [2] 0x00000001034acb8e libobjc.a.dylib`objc_object::sidetable_release(bool) + 202
         [3] 0x0000000102eca8f2 test`-[viewcontroller viewdidload] + 114 at viewcontroller.m:23:1
         [4] 0x0000000103ffa01a uikit`-[uiviewcontroller loadviewifrequired] + 1235
         [5] 0x0000000103ffa45a uikit`-[uiviewcontroller view] + 27
         [6] 0x0000000103ec298a uikit`-[uiwindow addrootviewcontrollerviewifpossible] + 65
         [7] 0x0000000103ec3070 uikit`-[uiwindow _sethidden:forced:] + 294
         [8] 0x0000000103ed5ebe uikit`-[uiwindow makekeyandvisible] + 42
         [9] 0x0000000103e4f37f uikit`-[uiapplication _callinitializationdelegatesformainscene:transitioncontext:] + 4346
         [10] 0x0000000103e555e4 uikit`-[uiapplication _runwithmainscene:transitioncontext:completion:] + 1709
         [11] 0x0000000103e527f3 uikit`-[uiapplication workspacedidendtransaction:] + 182
         [12] 0x000000010700d5f6 frontboardservices`__fbsserialqueue_is_calling_out_to_a_block__ + 24
         [13] 0x000000010700d46d frontboardservices`-[fbsserialqueue _performnext] + 186
         [14] 0x000000010700d7f6 frontboardservices`-[fbsserialqueue _performnextfromrunloopsource] + 45
         [15] 0x00000001039d9c01 corefoundation`__cfrunloop_is_calling_out_to_a_source0_perform_function__ + 17
         [16] 0x00000001039bf0cf corefoundation`__cfrunloopdosources0 + 527
         [17] 0x00000001039be5ff corefoundation`__cfrunlooprun + 911
         [18] 0x00000001039be016 corefoundation`cfrunlooprunspecific + 406
         [19] 0x0000000103e5108f uikit`-[uiapplication _run] + 468
         [20] 0x0000000103e57134 uikit`uiapplicationmain + 159
         [21] 0x0000000102ecaac3 test`main + 99 at main.m:14:9
         [22] 0x000000010689d65d libdyld.dylib`start + 1
    

看[3]发现我们在-[viewcontroller viewdidload]的第23行free了

我们看看对应代码  
![](/image/xcode_lldb_diao_shi_xiao_ji_qiao/58233b5529054bdc766d633797a698e09b43c2f8f30eece3620ccd55bb7c4880)  
可以明显看出是21行加了一个autorelease，22行又release了导致出问题的

当然这是个简单的demo，实际情况会复杂的多，使用malloc history也只是能提供更多信息来追查相应问题，不能保证一定能找出导致野指针的地方。

# 汇编篇

### 1.寄存器

在我们在调试的时候有时候查看寄存器会有很多有用的信息，我们先介绍下函数调用约定  
x64模拟器：

  * %rax 作为函数返回值使用。
  * %rsp 栈指针寄存器，指向栈顶
  * %rdi，%rsi，%rdx，%rcx，%r8，%r9 用作函数参数，依次对应第1参数，第2参数。。。
  * %rbx，%rbp，%r12，%r13，%14，%15 用作数据存储，遵循被调用者使用规则，简单说就是随便用，调用子函数之前要备份它，以防他被修改
  * %r10，%r11 用作数据存储，遵循调用者使用规则，简单说就是使用之前要先保存原值

arm64：  
arm64有32个64bit长度的通用寄存器x0～x30还有一个sp寄存器，因为arm64兼容32位所以可以只使用其中的低32bit别名w0～w30

  * r0-r7：参数/结果寄存器，r0存储返回值
  * r8：indirect result location寄存器(直接结果位置寄存器;)
  * r9-r15：临时寄存器，存储函数的局部变量。
  * r16：ip0 第1个intra-procedure-call scratch寄存器(第1个内部过程调用寄存器或临时寄存器ip0;)
  * r17：ip1 第2个intra-procedure-call 临时寄存器 (可能被调用者 和 plt代码是用）;
  * r18：平台寄存器（如果需要的话）;否则，就是一个临时寄存器
  * r19-r28：由被调用者 保存的寄存器
  * r29：fp栈帧指针
  * r30：lr链接寄存器
  * sp：栈寄存器

我们常用的一般都是传递前几个参数的寄存器，在oc方法里，一般第一个参数是self，第二个参数是selector，所以我们最常见的寄存器是rdi，rsi，x0，x1。  
上面我们在查找野指针的时候po $rdi，也就是查看第一个寄存器也就是self的值。

### 2.x命令

x命令是直接输出内存内容，非常好使

命令格式  
x/nfu

参数解释：  
n，表示要显示的内存单元的个数  
f，表示显示方式, 可取如下值：

参数 | 含义  
---|---  
x | 按十六进制格式显示变量  
d | 按十进制格式显示变量  
u | 按十进制格式显示无符号整型  
o | 按八进制格式显示变量  
t | 按二进制格式显示变量  
a | 按十六进制格式显示变量  
i | 指令地址格式  
c | 按字符格式显示变量  
f | 按浮点数格式显示变量  
  
u，表示一个地址单元的长度：

参数 | 含义  
---|---  
b | 按单字节分段输出  
h | 按双字节分段输出  
w | 按四字节分段输出  
g | 按八字节分段输出  
  
，表示内存地址，可以是变量名，也可以是内存地址。  
更加详细的说明可以看[这里](http://visualgdb.com/gdbreference/commands/x)

一些常用的组合：  
x/16xb self  
会显示 self 指针地址内容，16 个字节，16 进制。  
x/16cb chararray  
会显示地址 chararray 地址的内容，16 个字节，按字符格式显示。

比如我们定义  
char *chararray = “0123456789abcdef”;  
分别试下两种输出

    
    
    (lldb) x/16xb chararray
    0x10b16155a: 0x30 0x31 0x32 0x33 0x34 0x35 0x36 0x37
    0x10b161562: 0x38 0x39 0x41 0x42 0x43 0x44 0x45 0x46
    (lldb) x/16cb chararray
    0x10b16155a: 0123456789abcdef
    

可以看出第一种输出的是ascii码，第二种直接输出字符了。输出查看的时候有一点要注意，arm是小端存储，低地址存放的是低位~

ps：有时候crash的时候输出下x/16a $rsp，会看到一些额外信息~

