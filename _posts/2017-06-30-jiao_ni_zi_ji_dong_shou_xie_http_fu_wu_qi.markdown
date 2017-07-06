---
layout: post
title: "教你自己动手写HTTP服务器"
date: 2017-06-30 20:40:00
categories: android
author: vincanyang
tags: 轻量HTTP...
---

* content
{:toc}



谈到HTTP服务器，立马就能联想到Apache、Nginx等大名鼎鼎的开源组件。如果需要一个本地代理HTTP服务器，自己手写一个怎么样，会不会很难？！本文试着介绍如何在Android上手动编写一个轻量的HTTP服务器，通过阅读本文，笔者即将为你揭开HTTP服务器的面纱，收获一个五脏俱全的轻量HTTP服务器组件TinyHttpd。

## 网络IO模型选择
<!--more-->

HTTP是建立在TCP之上的一种协议，所以我们可以通过TCP协议来实现HTTP服务，而使用TCP编程首先面临的就是网络IO编程模型的选择。从JAVA的网络IO模型演进史上来看，主要有如下几种：

**BIO****编程模型**

BIO，Blocking I/O，即经典的传统服务器端同步阻塞I/O编程模型，如下图所示：

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/0980a6591b23c720a88253b9f052d832890e06c2ce26c7aa339fb5b2487a5a16)

其对应的伪代码如下：

    
    
    　　class DispatcherThread extends Thread{
    　　    ExecutorService executor = Executors.newCachedThreadPool();//线程池
    　　    ……
    　　    ServerSocket serverSocket = new ServerSocket();
    　　    serverSocket.bind(9000);
    　　
            public final void run() {
    　　 	while(!Thread.currentThread.isInturrupted()){//死循环等待新连接
    　　 		Socket socket = serverSocket.accept();
    　　 		executor.submit(new SocketProcessorThread(socket));//为新的连接创建一个线程
              }
            }
        }
    　　
    　　class SocketProcessorThread extends Thread{
    　　    private Socket socket;
    　　    public SocketProcessorThread(Socket socket){
    　　       this.socket = socket;
    　　    }  
    
    　　    public void run(){
    　　      while(!Thread.currentThread.isInturrupted()){//死循环处理读写事件
    　　          String data= socket.read()....//读取数据
    　　          if(!TextUtils.isEmpty(data)){
    　　             ......//处理数据
    　　             socket.write()....//写数据
    　　          }
    　　      }
    　　    }
       }

由于socket.accept()、socket.read()、socket.write()等函数都是同步阻塞的，所以必须放到子线程去处理，一个新的连接到来就要创建一个新的线程来保持。当面对成千上万的连接数时，传统的BIO模型很快就面临瓶颈，线程的创建和销毁成本高、线程本身占用较大内存、线程的切换成本高等原因很快就使得系统负载过大，导致系统趋于瘫痪状态而无法继续提供服务。这种模式优点是编程比较简单，但只适合请求数较少的应用场景。

**NIO****编程模型**

NIO，Non-blocking IO，非阻塞IO，是一个可以替代传统BIO的新一代IO编程模型，如下图所示：

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/03088dcafce5538c8e164429926b6072fbaa468a48e41b4a76bc62651aebbefe)

其对应的伪代码如下：

    
    
    class DispatcherThread extends Thread{
    　　Selector mSelector;
    　　ServerSocketChannel mServer;
    　　ExecutorService mServerExecutorService = Executors.newCachedThreadPool();//线程池
    　　……
    　　
    　　@Override
    　　public final void run() {
    　　        while (mIsRunning) {
    　　            SelectionKey key = null;
    　　            try {
    　　                mSelector.select();//阻塞
    　　                Iterator<SelectionKey> keyIterator = mSelector.selectedKeys().iterator();
    　　                while (keyIterator.hasNext()) {
    　　                    key = keyIterator.next();
    　　                    keyIterator.remove();
    　　                    if (!key.isValid()) {
    　　                        continue;
    　　                    }
    　　                    if (key.isAcceptable()) {//可连接事件通知
    　　                        handleAccept(key);
    　　                    } else if (key.isReadable()) {//可读事件通知
    　　                        SocketChannel channel = (SocketChannel) key.channel();
    　　                        byte[] requestBytes = readRequestBytes(channel);//读取数据
    　　                        if (requestBytes != null) {
    　　                            //独立线程处理数据，防止阻塞
    　　                            mServerExecutorService.submit(new IOHandler(channel, requestBytes,));
    　　                        }
    　　                    }
    　　                }
    　　            } catch (IOException e) {
    　　                if (key != null) {
    　　                    key.cancel();
    　　                }
    　　            }
    　　        }
       }

NIO核心部分主要由Channel、Buffer、Selector组成。其中Selector尤为重要，它的底层实现实际上就是大名鼎鼎的epoll机制（在Linux下，内核版本大于2.6时使用epoll，小于2.6时使用poll），因此只要使用一个独立的IO线程就可不断轮询到连接、读、写等IO事件，当可读事件到达后，就可以开始读取数据，然后再将读取到的数据放到子线程中处理，防止处理过程阻塞。关于epoll机制由于篇幅关系这里不再赘述，可以自行搜索一下，简单地讲，它是一种借助操作系统的中断技术实现的异步回调，当网卡收到网络端的消息的时候会向系统发起请求，系统再通知epoll，epoll再通知程序。正是有了epoll机制，才使得单机负载能够突破传统的天花板，让千万长连接同时在线成为现实。

**AIO****编程模型**

JDK1.7版本之后，引入了Asynchronous I/O （NIO.2）
的支持，主要是在java.nio.channels包下新增了下面四个异步Socket Channel，异步Socket
Channel是被动执行对象，我们不需要像NIO编程那样创建一个独立的IO线程来处理读写操作：

    
    
    AsynchronousSocketChannel
    AsynchronousServerSocketChannel
    AsynchronousFileChannel
    AsynchronousDatagramChannel

由于AIO是JDK1.7之后才引入的，为了兼容Android低版本考虑，我们并不打算选择它，所以仅是简单介绍，有兴趣的自行研究。

以上，JAVA网络I/O编程模型从BIO演进到NIO，再到AIO，实现了从同步阻塞IO到同步非阻塞IO（JAVA目前还没有异步非阻塞的编程模型）。虽然BIO和NIO都适合我们的应用场景，但笔者更倾向于更新的NIO，它也是目前网络服务器端IO编程模型的首选。

## Http请求和响应

选择NIO作为服务器端的网络IO模型后，接着就要看协议实现了。我们通过一个简单的http请求和响应的例子来重温一下HTTP协议，相信大家对它们再熟悉不过了：

http请求：

    
    
    GET https://raw.githubusercontent.com/yangwencan2002/mediafile/mai1.mp3 HTTP/1.1
    Host: 127.0.0.1:42729

http响应：

    
    
    HTTP/1.1 200 OK
    Content-Length=4212011
    Content-Type=audio/mpeg  
    
    xxxx……

## Http请求解析

通过以上例子我们知道，http请求和响应中会包含各种分割标识符，我们把它们汇总如下，为了方便，后面的讨论统一使用标识符替代字符进行描述：

**标识符**

|

**描述**

|

**字符**  
  
---|---|---  
  
CR

|

Carriage return (回车)

|

\n  
  
LF

|

Line feed character(换行)

|

\r  
  
SP

|

Horizontal space(空格)

|

  
  
COLON

|

COLON(冒号)

|

:  
  


为了更加形象地理解http请求包格式，我们画了一张图如下：

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/2955e1d734d5d68d7c9c422964afce7d240ff49e1ff4464505ee5657e6c369a1)



如上图所示，http请求主要包含三部分：请求行(request line)，请求头(header)，请求正文(body) 。

**请求行(request Line)：**主要包含三部分：Method ，URI ，协议版本。 各部分之间使用空格(SP)分割。整个请求头使用CRLF分割。

**请求头(header)：** 格式为name：value，用于客户端请求信息的描述。header之间以CRLF进行分割，最后一个header需要以CRLF结束，也就是说header和body之间通过CRLF分割。

**请求正文(body) ：**主要是post提交的数据，格式由Content-Type定义，长度由Content-Length定义。

通过以上分析，我们对http请求进行OOP设计，可以抽象出上图红色字体部分的对象，包括HttpMethod、HttpVersion、HttpHeaders、HttpBody、HttpRequest。



## Http响应解析

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/ecda6638ace5d4b84ce609af9ba92fbb04c801637152e03f33dab30d1828e156)

如上图所示，主要包含三部分：状态行(response line),响应头(header),响应正文(body)。

**状态行(response line)：**包含三部分：http版本，服务器返回状态码，描述信息。以CRLF进行分割。

**响应头(header) ：** 格式为(name：value)，用于服务器返回信息的描述。header之间以CRLF进行分割，最后一个header会以CRLF为结束。

**响应正文(body)：**服务器返回的数据，格式由Content-Type定义，长度由Content-Length定义。

通过以上分析，我们对http响应进行OOP设计，可以抽象出上图红色字体部分的对象，包括HttpMethod、HttpStatus、HttpHeaders、HttpBody、HttpResponse。

## Http请求解码

Server接收到的Client请求数据是字节数组byte[]，基于OOP编程，显然我们更希望得到的是HttpRequest对象，所以需要一个将byte[]封装成HttpRequest对象的过程，于是我们抽象了一个叫HttpRequestDecoder的类来完成该过程。当然你也可以使用一个方法就能完成这个编码过程，但独立一个HttpRequestDecoder类显然更加符合OOP设计，有利于代码理解和扩展。

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/2db5bb9476cd6056899615695216a5a956ac18c2a59d8137d0dd4b717ce7303d)



## Http响应编码

Server返回给Client的结果会通过HttpResponse对象来包装，所以我们需要将HttpResponse转换成byte[]，于是我们同样也抽象了一个叫HttpResponseDecoder的类，其主要职责就是将HttpResponse编码成byte[]，如下图所示。和上述的HttpRequestDecoder一样，这样的设计更加更加符合OOP思维，有利于代码理解和扩展。

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/5765ea8983156ffccbff060b7a092af80f1eee61d1f4807c26702947cf668849)

## 拦截器Interceptor

一个http请求过程往往会伴随着这样的需求：

l  在HttpRequest 到达 TinyHttp Core之前，拦截Client的HttpRequest。根据需要检查
HttpRequest，或者修改HttpRequest头和数据。

l
在HttpResponse到达客户端之前，拦截HttpResponse。根据需要检查HttpResponse，或者修改HttpResponse头和数据。

于是我们实现了拦截器来满足这种需求，拦截器其实就是责任链模式的实现，利用切面的方式无侵入式地修改HttpRequest和HttpResponse，譬如我们可以使用拦截器来实现打印请求和响应的日志等。

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/4a48e13c22d69e197a5078697d2bf6d4068d306575081c08bff7e05e00ea3186)



那么要如何实现呢？简单地讲，就是在客户端发起请求后，将所有的拦截器进行链式调用，最后再发起真正的请求。我们来看一下具体实现，首先拦截器会有各种各样的逻辑实现，所以我们得定义一个接口Interceptor，接着需要再定义一个拦截器链Chain接口，除了为Interceptor提供HttpRequest和HttpResponse外，还需要实现一个proceed方法用来递归遍历所有拦截器。直接看源码：

    
    
    public interface Interceptor {
        void intercept(Chain chain) throws ResponseException, IOException;
    
        /**
         * 拦截器链
         */
        interface Chain {
            /**
             * 获取request
             */
            HttpRequest request();
    
            /**
             * 获取response
             */
            HttpResponse response();
    
            /**
             * 链式处理请求
             */
            void proceed(HttpRequest request, HttpResponse response) throws ResponseException, IOException;
        }
    }

  Chain的实现如下，可以看到proceed使用循环+递归的方式，借助函数调用栈，将拦截器串联起来：

    
    
    public class InterceptorChainImpl implements Interceptor.Chain {
        ……
        @Override
        public void proceed(HttpRequest request, HttpResponse response) throws ResponseException, IOException {
            ……
            InterceptorChainImpl next = new InterceptorChainImpl(
                    mInterceptors, mIndex + 1, request, response);
            Interceptor interceptor = mInterceptors.get(mIndex);//获取下一个拦截器
            interceptor.intercept(next);//调用拦截器
        }
    }

 客户端发起一个请求时，会将所有拦截器收集起来并交给拦截器链处理，开始调用第一个拦截器：

    
    
        private void serviceWithInterceptorChain(HttpRequest originalRequest, HttpResponse originalResponse) throws ResponseException, IOException {
            List interceptors = new ArrayList<>();
            interceptors.addAll(mInterceptors);
            Interceptor.Chain chain = new InterceptorChainImpl(interceptors, 0, originalRequest, originalResponse);
            chain.proceed(originalRequest, originalResponse);//开始调用第一个拦截器
        }

 某拦截器实现，在interceptor()中对request和response修改后，再递归调用下一个拦截器：

    
    
    public class XXXInterceptor implements Interceptor {
        ……
        @Override
        public void intercept(Chain chain) throws ResponseException, IOException {
            HttpRequest request = chain.request();  
            HttpResponse response = chain.response();
            chain.proceed(request, response);//递归调用下一个拦截器
        }
    }

 最后一个拦截器不要再调用chain.proceed()才能结束链式调用：

    
    
        public class LastInterceptor implements Interceptor {
    
            @Override
            public void intercept(Chain chain) throws ResponseException, IOException {
                HttpRequest request = chain.request();
                HttpResponse response = chain.response();
                //这里不要再调用chain.proceed(request, response);
            }
        }

 可能看代码还是有点复杂，简要画了张图如下：

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/adea5f906c9ad24e84ca9f770b7ea04f8c35c287b6a35b32942bff1730e2b3d6)

## 端口开放风险

手机移动网络实际上是一个大型的“局域网”，HTTP服务器会对外随机开放一个端口，如此一来，就相当于将本地服务端口暴露给整个手机网络。臭名昭著的“WormHole虫洞漏洞”就是该漏洞的典型，其根本原因就是没有对请求进行限制和验证，而本身又提供了敏感服务，让黑客有机可乘。明白了攻击原理，我们就知道如何预防，措施如下：

1、对请求url进行规则限制，只接受特定的url请求；

2、对请求者进行身份验证，只接受播放器发起的请求，这里使用了消息摘要算法HMAC-MD5或HMAC-SHA1，并对其稍作改造：

1).播放器请求时，生成一个随机数random_key；

2).将random_key作为密钥，url和timestamp作为输入，使用HMAC-
MD5/SHA1生成一个hash值sign，然后将该字符串追加到url后面，向server发起请求，如下图所示：

![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/073bdddb9773ad8c9d47df293fe029e71093506df2afeef68a06ac8df27dcc17)

3).server收到请求后，先验证timestamp是否超过时间限制，防止重放攻击，接着根据random_key（本地获取）、url、timestamp使用同样的签名算法也生成一个签名字符串sign，然后和请求的sign比对，如果一致，则认为是授权的，否则就拒绝请求，如下图所示：



![](/image/jiao_ni_zi_ji_dong_shou_xie_http_fu_wu_qi/02324d6d67a257c62450654722e68a7d56b4cea94ae3f6865f56ad9160097e4a)

由于身份鉴权本质上是修改了URL，所以可以使用拦截器进行实现，具体可参见AuthInterceptor类。

**总结**

以上就是轻量HTTP服务器组件TinyHttpd的架构设计要点的全部介绍。

TinyHttpd是一个运行于Android上的轻量Http服务器组件，可用于代理服务器等使用场景。具有如下特性：  
1、OOP设计，易于理解、维护、扩展；  
2、具有拦截器功能，可对http请求和响应进行动态修改；  
3、安全，对http请求进行身份鉴权，无端口开放风险。

如果想要直接获取源码和sample，请移步<http://pub.code.oa.com/project/home?projectName=TinyHttpd>。

