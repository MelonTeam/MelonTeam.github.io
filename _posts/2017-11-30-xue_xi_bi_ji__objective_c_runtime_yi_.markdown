---
layout: post
title: "[学习笔记] Objective-C Runtime（一）"
date: 2017-11-30 20:57:00 +0800
categories: ios
author: doreencao
tags: runtime
---

* content
{:toc}



## Class

`id`是指向`objc_object`结构体的指针，表示指向类的实例对象，
<!--more-->

    
    
    struct objc_object {
        Class _Nonnull isa;
    };
    
    typedef struct objc_object *id;  
    

`isa`是一个`Class`类型的指针，可以利用`isa`指针获取对象所属的类。而类本身同时也是一个对象，因此可以看到`objc_class`结构体中也有一个`isa`指针。

    
    
    typedef struct objc_class *Class;
    
    struct objc_class {
        //指向metaclass
        Class isa;
    
    #if !__OBJC2__
    
        //指向父类
        Class super_class;
    
        //类名
        const char * name;
    
        //版本信息，用于对象序列化，识别不同类定义版本中实例变量布局的改变
        long version;
    
        //标识信息
        long info;
    
        //实例变量的大小
        long instance_size;
    
        //存放成员变量、属性信息，Ivar指针数组
        struct objc_ivar_list * ivars;
    
        //实例方法列表
        struct objc_method_list ** methodLists;
    
        //缓存调用过的方法，对象接受消息时先在cache中查找，提高效率
        struct objc_cache * cache;
    
        //类实现的协议列表
        struct objc_protocol_list * protocols;
    #endif
    
    };
    

`isa`指向元类(meta class)，类对象所属的类称为元类，存储着类方法即类对象的实例方法。元类同样也是对象，它是根元类(root meta
class)的实例，根元类的`isa`指针则指向自己。

由于类方法保存在元类中，为了保证父类的类方法可以在子类中被调用，类的元类会继承父类的元类，换而言之，类对象和元类对象有着同样的继承关系。

`super_class`指向父类，根类(如`NSObject`)的`super_class`指针为空。  

![](/image/xue_xi_bi_ji__objective_c_runtime_yi_/26483098fc25fb5a8eb0e170b598e8022ad0436065a2f9a49cc2683e913c7ed7)

`cache`用于缓存最近调用过的方法，在实际使用中，类的实例方法只有一部分是常用的，调用过一个方法后该方法会被缓存到`cache`列表中，作为一种提高效率的策略，每一次接收消息优先在`cache`中查询，避免了反复遍历`methodLists`。

##### objc_getClass和object_getclass

`objc_getClass`参数是类名的字符串，返回的就是这个类的类对象；`object_getClass`参数是`id`类型，它返回的是这个`id`的`isa`指针所指向的`Class`，如果传参是`Class`，则返回该`Class`的`metaClass`。

当`id`为实例对象时，`[id
class]`与`object_getClass(id)`等价，因为前者会调用后者。`object_getClass([id class])`得到元类。

当`id`为类对象时，`[id class]`返回值为自身，`object_getClass(id)`与`object_getClass([id
class])`等价，得到元类。

## Ivar

`Ivar`代表类中实例变量，

    
    
    typedef struct ivar_t *Ivar  
    

`class_copyIvarList`获取的不仅有实例变量，还有属性。但会在原本的属性名前加上一个下划线，且不包含父类中声明的变量。

    
    
    // 获取实例变量
    Ivar *class_copyIvarList(Class cls, unsigned int *outCount) 
    
    // 获取成员变量名,“_”前缀
    const char *ivar_getName(Ivar v) 
    
    // 获取成员变量类型编码
    const char *ivar_getTypeEncoding(Ivar v)
    
    // 获取指定名称的成员变量
    Ivar class_getInstanceVariable(Class cls, const char *name)
    
    // 获取某个对象成员变量的值
    id object_getIvar(id obj, Ivar ivar);
    
    // 设置某个对象成员变量的值
    void object_setIvar(id obj, Ivar ivar);
    
    // 添加成员变量    
    BOOL class_addIvar ( Class cls, const char *name, size_t size, uint8_t alignment, const char *types );  
    

## objc_property_t

`objc_property_t`是表示Objective-C声明的属性的类型，为一个指向`objc_property`结构体的指针，

    
    
    typedef struct property_t *objc_property_t
    
    // 获取指定的属性
    objc_property_t class_getProperty ( Class cls, const char *name );
    
    // 获取属性列表
    objc_property_t * class_copyPropertyList ( Class cls, unsigned int *outCount );
    
    // 为类添加属性
    BOOL class_addProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );
    
    // 替换类的属性
    void class_replaceProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount )
    
    // 获取属性名称
    const char *property_getName(objc_property_t property)
    
    // 获取属性描述信息
    const char *property_getAttributes(objc_property_t property);
    
    // 获取属性attribute数组
    objc_property_attribute_t * property_copyAttributeList ( objc_property_t property, unsignedint *outCount );
    

较之`class_copyIvarList`函数，使用`class_copyPropertyList`函数只能获取类的属性，而不包含成员变量，此时获取的属性名是不带下划线的。

## Method

`Method`表示类中定义的方法，是指向`objc_method`结构体的指针，

    
    
    typedef struct objc_method *Method;
    
    struct objc_method {
        SEL _Nonnull method_name;
        char * _Nullable method_types;
        IMP _Nonnull method_imp;
    };  
    

`SEL`是方法选择器，

    
    
    typedef struct objc_selector *SEL;
    

它代表方法的签名，在类对象的方法列表中存储着方法签名与方法代码的对应关系，每一个方法都有一个对应的`SEL`，同名方法具有相同的`SEL`。因此同一个类的继承体系中，不能存在两个及以上的同名而不同参数类型的方法，这会被视为编译错误。但不同的类可以具有同名方法，尽管方法的`SEL`相同，在实例对象需要执行方法时，会在自己的方法列表中根据`SEL`索引对应的`IMP`。

`IMP`是一个函数指针，指向方法的实现，

    
    
    #if !OBJC_OLD_DISPATCH_PROTOTYPES
    typedef void (*IMP)(void /* id, SEL, ... */ ); 
    #else
    typedef id _Nullable (*IMP)(id _Nonnull, SEL _Nonnull, ...); 
    #endif
    

`Method`相关函数：

    
    
    // 添加方法
    BOOL class_addMethod ( Class cls, SEL name, IMP imp, const char *types );
    
    // 获取实例方法，会搜索父类实现
    Method class_getInstanceMethod ( Class cls, SEL name );
    
    // 获取类方法，会搜索父类实现
    Method class_getClassMethod ( Class cls, SEL name );
    
    // 获取方法列表，不包含父类实现
    Method * class_copyMethodList ( Class cls, unsigned int *outCount );
    
    // 替换方法的实现
    // 若不存在name指定的方法，类似class_addMethod实现功能，反之类似method_setImplementation实现功能
    IMP class_replaceMethod ( Class cls, SEL name, IMP imp, const char *types );
    
    // 设置方法的具体实现
    IMP method_setImplementation(Method m, IMP imp)；
    
    // 返回方法的具体实现
    IMP class_getMethodImplementation ( Class cls, SEL name );
    IMP class_getMethodImplementation_stret ( Class cls, SEL name );
    
    // 类实例是否响应指定的selector
    BOOL class_respondsToSelector ( Class cls, SEL sel );  
    

向实例发消息时会调用`class_getMethodImplementation`，返回指向方法实现函数的指针。返回的函数指针可能是一个指向runtime内部的函数，而不一定是方法的实际实现。例如，如果类实例无法响应`selector`，则返回的函数指针将是运行时消息转发机制的一部分。

## 一个动态创建类的例子

    
    
     //动态创建类
    Class newClass = objc_allocateClassPair([NSObject class], "NewClass", 0);
    NSLog(@"creat class named newClass");
    
    //类方法
    class_addMethod(object_getClass(newClass), @selector(newClassClassMethod),(IMP)class_method , "v@:");
    
    //实例方法
    class_addMethod(newClass, @selector(newClassInstanceMethod), (IMP)instance_method, "v@:");
    
    //成员变量
    class_addIvar(newClass, "_ivar1", sizeof(NSString *), log(sizeof(NSString *)), "i");
    
    //属性
    objc_property_attribute_t type = {"T", "@\"NSString\""};
    objc_property_attribute_t ownership = { "C", "" };
    objc_property_attribute_t backingivar = { "V", "_ivar1"};
    objc_property_attribute_t attrs[] = {type, ownership, backingivar};
    class_addProperty(newClass, "property2", attrs, 3);
    
    objc_registerClassPair(newClass);
    
    //调用
    [newClass performSelector:@selector(newClassClassMethod)];
    id instance = [[newClass alloc] init];
    [instance performSelector:@selector(newClassInstanceMethod)];  
    

方法实现如下，

    
    
     void class_method(id self , SEL _cmd) {
        NSLog(@"class_method called");
        NSLog(@"class name: %s", class_getName(self));
    }
    
    
    void instance_method(id self , SEL _cmd) {
        NSLog(@"instance_method called");
        Class cls = [self class];
        unsigned int outCount = 0;
        // 成员变量
           Ivar *ivars = class_copyIvarList(cls, &outCount);
        for (int i = 0; i < outCount; i++) {
            Ivar ivar = ivars[i];
            NSLog(@"instance variable name: %s ", ivar_getName(ivar));
        }
        free(ivars);
    
        // 属性操作
        objc_property_t * properties = class_copyPropertyList(cls, &outCount);
        for (int i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            NSLog(@"property name: %s , attribute: %s", property_getName(property), property_getAttributes(property));
        }
        free(properties);
    
        // 方法操作
        Method *methods = class_copyMethodList(cls, &outCount);
        for (int i = 0; i < outCount; i++) {
            Method method = methods[i];
            NSLog(@"instance method signature: %s", method_getName(method));
        }
        free(methods);
    }  
    

输出，  

![](/image/xue_xi_bi_ji__objective_c_runtime_yi_/8201365acbce994094ca3822b963eea502de8978aca26b4f7828a048547ca8ff)

## 方法的调用

runtime是OC区别于静态语言的一个重要特性，它实现了在运行时才将消息绑定到方法实现上的动态特性。编译器会将OC语法中的方法调用`[receiver
message]`表达式转化为消息函数`objc_msgSend`的调用。

    
    
    objc_msgSend(id self, SEL op, ...)
    

这个函数完成了动态绑定的工作：  
1，根据消息接收者的类和`SEL`索引到对应的方法实现  
2，将消息接收者和参数传递给方法实现  
3，返回该方法实现的返回值

当一个新对象被创建时，其`isa`指针也会被初始化，指向所属类的`objc_class`结构体，`objc_class`内有`isa`指针以及指向父类的指针，因而对象可以访问类以及类的继承体系。

当对象接收到消息时，通过对象的`isa`指针获取类的`objc_class`，在`cache`中查找`SEL`对应的`IMP`即方法实现，若查找不到，转至`methodLists`中查找。

若无查找结果，通过`objc_method`中指向父类的指针，在父类中重复查找过程，沿着类的继承体系一直查找到`NSObject`。

查找到方法实现的入口后，传入参数执行方法；若最终仍未查找到方法实现的入口，则进入消息转发流程。  

![](/image/xue_xi_bi_ji__objective_c_runtime_yi_/74eead62f518e3c1988e6aaa2d00ef09ed9c8d5d67f6adf134285deacf5f428c)

### 消息转发机制

当一个对象无法接收指定消息时，会启动消息转发机制(message
forwarding),用于告知对象如何处理未知消息。默认情况下，如果对象收到位置消息，会收到由`NSObject`的`doesNotRecognizeSelector`抛出的异常。借助于消息转发机制，可以采取一些处理方法使程序执行特定的逻辑。

消息转发机制分为三步：  
1，动态方法解析 - `resolveInstanceMethod:`  
2，备用接收者 - `forwardingTargetForSelector:`  
3，完整转发 - `forwardInvocation:`  

![](/image/xue_xi_bi_ji__objective_c_runtime_yi_/0fda076baf5fbc5b29aed3de173ca6b32be4e46315bac0843065fc6dd29d9e9f)

#### 动态方法解析

在对象收到未知消息时，系统会首先会调用`resolveInstanceMethod:`或`resolveClassMethod:`方法来添加实例方法或类方法的实现，使用`class_addMethod`添加某种方法实现。

举例：

    
    
    classModel *model = [[classModel alloc] init];
    NSLog(@"instance perform selector InstanceMethod");
    [model performSelector:@selector(InstanceMethod)];  
    

m文件

    
    
    void functionInstanceMethod (id self , SEL _cmd) {
    NSLog(@"functionInstanceMethod called for %@ instance" , [self class]);
    }
    
    @implementation classModel
    
    + (BOOL)resolveInstanceMethod:(SEL)sel
    {
        if ([NSStringFromSelector(sel) isEqualToString:@"InstanceMethod"]) {
            class_addMethod([self class], @selector(InstanceMethod), (IMP)functionInstanceMethod, "@:");
            return YES;
        }
        return [super resolveInstanceMethod:sel];
    }
    
    @end  
    

输出：  

![](/image/xue_xi_bi_ji__objective_c_runtime_yi_/eda624774198ce5c800d44c423734cbcd6f6178e235d0952d91fadb54e579d5f)

#### 备用接收者

如果动态方法解析无法解决问题，在进入完整消息转发流程前还有一个机制，可以将消息接收者替换为其他对象。调用’forwardingTargetForSelector:’方法，返回期待其接收消息的另一个对象，如果返回`nil`或者`self`，则会进入消息转发机制。
这种机制通常在对象内部实现，在调用方看来仍是由对象亲自处理消息。

举例：

    
    
    classModel *model = [[classModel alloc] init];
    NSLog(@"instance perform selector backupModelInstanceMethod");
    [model performSelector:@selector(backupModelInstanceMethod)]; 
    

m文件：

    
    
    @implementation backupModel
    
    - (void)backupModelInstanceMethod
    {
        NSLog(@"backupModelInstanceMethod called by %@ instance" , [self class]);
    }
    @end
    
    
    @interface classModel() {
        backupModel *_backupModel;
    }
    @end
    
    @implementation classModel
    
    - (instancetype)init {
        if (self = [super init]) {
            _backupModel = [backupModel new];
        }
        return self;
    }
    
    - (id)forwardingTargetForSelector:(SEL)sel
    {
        if([NSStringFromSelector(sel) isEqualToString:@"backupModelInstanceMethod"]){
            return _backupModel;
        }
        return [super forwardingTargetForSelector:sel];
    }
    
    @end
    

输出：  

![](/image/xue_xi_bi_ji__objective_c_runtime_yi_/bed8bc3c4ce01565c27b02b19a1a185ef3ac96f2881694c0bc4b12fd6f995082)

本文参考链接：

[Objective-C Runtime Programming
Guide](  
[Objective-C
Runtime](http://yulingtianxia.com/blog/2014/11/05/objective-c-runtime/#objc-
property-t)  
[Objective-C对象模型及应用](http://blog.devtang.com/2013/10/15/objective-c-object-
model/)  
[Objective-C Runtime
运行时之三：方法与消息](http://southpeak.github.io/2014/11/03/objective-c-runtime-3/)

