---
layout: post
title: "初探kotlin异步 async/await"
date: 2017-12-31 21:15:00 +0800
categories: android
author: yellowye
tags: kotlin入门
---

* content
{:toc}



  * 在接触kotlin之前，常用的Android异步实现有asynctask，thread handler兄弟；除了写法繁琐外，他们一般的坑： 

  1. 写法不当，容易产生匿名内部类持有外部类实例引起的内存泄露；
<!--more-->
  2. 工作线程回到主线程更新UI时activity有可能已经销毁，没有加isfinishing判断的话，仍进行没有必要的处理导致badtoken等异常。

举个asynctask翻译为kotlin异步写法的栗子：

    
    
    private class DownloadFilesTask extends AsyncTask {
         protected Long doInBackground(URL... urls) {
             int count = urls.length;
             long totalSize = 0;
             for (int i = 0; i < count; i++) {
                 totalSize += Downloader.downloadFile(urls[i]);
                 publishProgress((int) ((i / (float) count) * 100));
                 if (isCancelled()) break;
             }
             return totalSize;
         }
    
         protected void onProgressUpdate(Integer... progress) {
             setProgressPercent(progress[0]);
         }
    
         protected void onPostExecute(Long result) {
             showDialog("Downloaded " + result + " bytes");
         }



    
    
    //kotlin的异步写法
     fun main(args: Array) { 
            val future = async {  
                (1..5).map {  
                            await(startLongAsyncOperation(it))  
                           }.joinToString("\n")    
             }    
     println(future.get())   
    }



  * kotlin异步的一般步骤

  1. async关键字创建协程；
  2. await 挂起函数，启动协程,至少要有一个挂起函数。挂起函数只能在协程/挂起函数中被调用，不能在普通函数里调用。

  * 协程与线程的区别

  1.  协程是通过编译技术实现(不需要虚拟机VM/操作系统OS的支持)，通过插入相关代码来生效。与之相反，线程/进程是需要虚拟机VM/操作系统OS的支持，通过调度CPU执行生效。
  2. 线程阻塞的代价昂贵，尤其在高负载时的可用线程很少，阻塞线程会导致一些重要任务缺少可用线程而被延迟。协程挂起几乎无代价，无需上下文切换或涉及OS。

  * [kotlin实现协程的工作原理](https://github.com/Kotlin/kotlin-coroutines/blob/master/kotlin-coroutines-informal.md)

