---
layout: post
title: "一种下载管理方案的设计与实现"
date: 2017-06-21 10:13:00 +0800
categories: android
author: leoyxwang
tags: 下载 优先级
---

* content
{:toc}

| 导语
4G时代流量资费大幅下降，各种“WBQ”卡惊艳出世——在此背景下，下载对于移动端已不再是一种昂贵的高成本行为。同时EMMC、UFS等存储介质的发展也为移动端下载解决了一定的I/O瓶颈问题。本文主要描述一种Android端下载管理方案的设计和实现思路。重点在思路，实现方案并不一定十分完善^_^

# 前言

<!--more-->
观察几年前的移动应用可以发现，安装包体积非常小。原因很简单：呈现的内容简单，足够全量打包进安装包。如今业务繁杂、UI绚丽的需求由于安装包体积限制不可能再进行全量打包，必须通过后期的按需下载实现接入。因此，需要设计一个通用的下载组件管理App内所有资源的下载。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/8999e1db9ecda53d18b3e3c5268f31c9501f28853b1d308ce850e6fc267b4bff)

# 一、技术调研

## 1.1 DownloadManager

The download manager is a system service that handles long-running HTTP
downloads. Clients may request that a URI be downloaded to a particular
destination file. The download manager will conduct the download in the
background, taking care of HTTP interactions and retrying downloads after
failures or across connectivity changes and system reboots. Instances of this
class should be obtained through
`[getSystemService(String)](https://developer.android.com/reference/android/content/Context.html#getSystemService\(java.lang.String\))`
by passing
`[DOWNLOAD_SERVICE](https://developer.android.com/reference/android/content/Context.html#DOWNLOAD_SERVICE)`.
Apps that request downloads through this API should register a broadcast
receiver for
`[ACTION_NOTIFICATION_CLICKED](https://developer.android.com/reference/android/app/DownloadManager.html#ACTION_NOTIFICATION_CLICKED)`
to appropriately handle when the user clicks on a running download in a
notification or from the downloads UI. Note that the application must have the
`[INTERNET](https://developer.android.com/reference/android/Manifest.permission.html#INTERNET)`
permission to use this class.

        从Android 2.3（API level
9）开始，Android以Service的方式提供了全局的DownloadManager来系统级地优化处理长时间的下载操作。上述官方文档的描述中说明，DownloadManager支持失败重试、Notification通知等基本特性。特别是系统组件的特性能够支持完全的后台下载。

        **优点**

        （1）基于Broadcast的通信机制实现与特定App零耦合。

        （2）对于简单的单文件下载，可以满足使用需求。

        （3）支持IPC。

        （4）对网络环境（移动网络、Wi-Fi等）进行了特殊处理，适合不同网络环境的使用。

        **缺点**

        （1）需注册Broadcast监听下载完成事件，稍显复杂。

        （2）基于ContentProvider的任务查询机制，增加了使用复杂度。

        （3）需手动实现断点续传。

        （4）需手动实现单文件的多线程（分段）下载。

        （5）不支持下载任务的优先级调度。

## 1.2 第三方开源下载组件

Github上存量的具有相对完整功能的下载组件并不多，较为突出的有**FileDownloader**。支持在独立的下载进程进行下载保证健壮性，并支持替换网络请求框架。在项目中已有成熟应用。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/abe0034094aa4dc52e9c536022e2215fd0c76d188750532051ff6b8138214c9d)

        优点

        （1）功能完整，可配置性高。

        （2）对实际应用场景做出了一定优化。如任务管理、掉帧处理等。

        缺点

        （1）组件代码量大，使用门槛稍高。

<https://github.com/lingochamp/FileDownloader>

# 二、需求分析

        经过相关方案的技术调研，可以简单的归纳出一个下载管理组件应该具有的功能：

**文件下载断点续传多线程多任务****优先级调度**

        本文结合上述技术方案的思想，本着简化优化的思想，设计一个下载管理的组件。功能需求如下。

        1）以任务为单位完成单个的文件下载

        2）对每个任务使用多线程分段下载（对大文件有效）

        3）支持任务断点续传

        4）支持多任务管理和优先级调度

        5）在数据库中保存所有未完成的任务信息

        6）实现完善的异常保护机制

        对用户来说，下载文件和配置下载管理是两个可直接交互的功能。下载文件包括：

        1）添加下载任务（手动开始）。

        2）开始下载任务（新建或断点续传）。

        3）停止下载任务（单线程任务相当于取消，多线程任务暂停）。

        4）取消下载任务（停止并删除）。

        5）查询任务信息（从内存或数据库中查询）。

        配置下载管理目前可设置最多同时下载的任务数，超出则进入排队队列。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/d223561039d0c68bc0023da1be99e5d40800f9def23c35fd6562207f144c2a98)

# 三、详细设计

文件下载的主要功能是以任务为单位完整地完成一个文件的下载，包括下载任务配置、合法性验证、任务优先级和排队处理、线程数配置、下载控制、回调通知、异常处理和任务信息存储等一系列流程。

## 3.1 下载任务状态

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/b0b8566fc31c61ceab281d7f2c28ae7c3f0c1159fe568138f452778630f988f0)

  
        下载的任务包括4种状态：就绪、下载中、排队中和已停止。  
（1）就绪（Ready）。任务创建时默认为就绪状态，具有不可逆性，即不能从任何其他状态转化为就绪态。就绪态的任务未执行，已写入数据库。就绪任务可直接被取消（删除，下同）。  
（2）下载中（Downloading）。任务在下载队列中正在下载，下载队列的大小由文件下载的最大任务数配置确定。若下载中的任务被优先级更高的任务插队，则转化为排队中状态。若下载中的任务被停止或产生异常（如网络中断），则转入已停止状态（数据库中同步任务信息）。任务下载完成后自动销毁（删除）。  
（3）排队中（Queueing）。任务在排队队列中等待，直到下载队列中有任务被删除后根据排队队列中的优先级继续一个任务的下载。排队中的任务可被直接停止或取消。  
        （4）已停止（Stopped）。任务执行过（可能经历过下载中或排队中状态），由于异常或被停止转入已停止状态。已停止的任务可被直接取消。

## 3.2 下载任务控制

        下载管理组件需要对外开放部分API使外部能够对下载过程进行控制，主要包括新增任务、启动下载、停止下载和取消下载。  
        （1）新增任务（dlAdd）  
新增任务是指创建一个任务对象，设置下载URL、保存路径（非必须，有默认值）、优先级、回调监听等必须的参数后把任务信息写入数据库进行持久化。此时任务未执行，各任务队列中还没有保存该任务。此API可用于添加一个手动执行的任务。  
        （2）启动下载（dlStart）  
        启动下载是一个比较复杂的过程，包括**创建任务**和**加入任务队列**两大过程。  
        **创建任务**首先检查任务参数合法性，然后检查该任务（URL）是否为下载队列中的重复任务。接着处理历史任务恢复，先从内存中已停止队列查找URL，再从数据库中查找URL，恢复断点续传信息。最后完善任务信息、设置新的优先级、复位标志位后保存至数据库。  
        **加入任务队列**根据下载队列的大小和任务的优先级进行排队调度，决定将该任务加入排队队列或下载队列。
    
    
        /**
         * 开始一个下载任务
         *
         * @param url      文件下载地址
         * @param dir      文件下载后保存的目录地址，该值为空时会默认使用应用的文件缓存目录作为保存目录地址
         * @param name     文件名，文件名需要包括文件扩展名。该值可为空，为空时将由程序决定文件名。  
         * @param headers  请求头参数
         * @param priority 任务优先级
         * @param listener 下载监听器
         */
        public synchronized void dlStart(String url, String dir, String name, List headers, int priority,
                                         IDListener listener) {
            // 验证优先级合法
            if (priority != PRIORITY_LOW && priority != PRIORITY_NORMAL && priority != PRIORITY_HIGH && priority !=
                    PRIORITY_UNSPECIFIED) {
                throw new IllegalArgumentException("Priority illegal. Please set a correct priority between PRIORITY_LOW," +
                        " " +
                        "PRIORITY_NORMAL, PRIORITY_HIGH and PRIORITY_UNSPECIFIED.");
            }
            boolean hasListener = listener != null;
            if (TextUtils.isEmpty(url)) {
                if (hasListener) {
                    listener.onError(ERROR_INVALID_URL, "Url can not be null.", url);
                }
                return;
            }
            if (!NetworkUtil.isNetworkAvailable(mContext)) {
                if (hasListener) {
                    listener.onError(ERROR_NOT_NETWORK, "Network is not available.", url);
                }
                return;
            }
            // 是正在下载或排队的任务
            if (TASK_DLING.containsKey(url) || isQueueing(url)) {
                if (hasListener) {
                    listener.onError(ERROR_REPEAT_URL, "Url is downloading.", url);
                }
                return;
            }
            // 不是正在下载或排队的任务
            LogUtil.logD(TAG, "不是正在下载的任务");
            DLTaskInfo info;
            // 是否是就绪任务或上次未执行过的排队任务
            boolean isReadyTask = false;
            // 是运行/排队过的已暂停的任务
            if (TASK_STOPPED.containsKey(url)) {
                LogUtil.logD(TAG, "是运行/排队过的已暂停的任务，恢复下载.");
                info = TASK_STOPPED.remove(url);
            }
            // 内存任务列表中不存在该任务，从数据库中读取任务信息（本次运行未启动过该任务的下载）
            else {
                LogUtil.logD(TAG, "不是运行过的已暂停任务，从数据库中恢复");
                info = DLDBManager.getInstance().queryTaskInfo(url);
                if (null != info) {
                    LogUtil.logD(TAG, "数据库中查到信息");
                    // directly add task case
                    List threadInfo = DLDBManager.getInstance().queryAllThreadInfo(url);
                    if (threadInfo == null) {
                        LogUtil.logD(TAG, "是就绪任务或上次未执行过的排队任务");
                        isReadyTask = true;
                    } else {
                        LogUtil.logD(TAG, "是已暂停的任务");
                        info.threads.clear();
                        info.threads.addAll(threadInfo);
                    }
                }
            }
            // 新建任务
            if (!isReadyTask && null == info) {
                LogUtil.logD(TAG, "新建任务");
                info = new DLTaskInfo();
                info.baseUrl = url;
                info.realUrl = url;
                dir = TextUtils.isEmpty(dir) ? mContext.getCacheDir().getAbsolutePath() : dir;
                info.dirPath = dir;
                info.fileName = name;
            }
            // 断点续传任务（不是单线程任务）
            else if (!info.isSingleThread) {
                LogUtil.logD(TAG, "断点续传任务（不是单线程任务）");
                info.isResume = !isReadyTask;
                for (DLThreadInfo threadInfo : info.threads) {
                    threadInfo.isStop = false;
                }
            }
            info.redirect = 0;
            info.requestHeaders = DLUtil.initRequestHeaders(headers, info);
            info.listener = listener;
            info.hasListener = hasListener;
            // 未指定优先级
            if (priority == PRIORITY_UNSPECIFIED) {
                if (info.priority == PRIORITY_UNSPECIFIED) {
                    // 任务未指定优先级，使用中优先级
                    info.priority = PRIORITY_NORMAL;
                }
            }
            // 使用外部指定的优先级
            else {
                info.priority = priority;
            }
            // 任务插入数据库
            if (DLDBManager.getInstance().queryTaskInfo(url) == null) {
                DLDBManager.getInstance().insertTaskInfo(info);
            }
            if (hasListener) {
                listener.onCreate(info);
            }
            resetQueue(info); // 强制isQueue复位
            // 检查当前下载任务数和优先级
            if (TASK_DLING.size() >= mMaxTask) {
                DLTaskInfo lowestPriorityDLTask = TASK_DLING_PRIO.get(TASK_DLING_PRIO.size() - 1);
                LogUtil.logD(TAG, "TASK_DLING_PRIO中最低优先级为" + lowestPriorityDLTask.priority);
                LogUtil.logD(TAG, "调用dlStart的任务优先级为" + info.priority);
                // 若当前下载队列中存在更低优先级的任务
                if (lowestPriorityDLTask.priority > info.priority) {
                    LogUtil.logD(TAG, "当前下载队列中存在更低优先级的任务，正在下载队列中最低优先级任务进入排队");
                    dlQueue(lowestPriorityDLTask.baseUrl);
                }
                // 若当前下载队列中不存在更低优先级的任务
                else {
                    LogUtil.logD(TAG, "当前下载队列中不存在更低优先级的任务");
                    addQueueTask(info);
                    return;
                }
            }
            addDLTaskPriority(info);
            TASK_DLING.put(url, info);
            info.status = STATUS_DOWNLOADING;
            if (hasListener) {
                listener.onPrepare(info.baseUrl);
            }
            LogUtil.logD(TAG, "准备运行任务URL：" + url);
            POOL_TASK.execute(new DLTask(info));
        }

        （3）停止下载（dlStop）  
停止下载的操作对象是下载中或排队中的任务。首先处理内存中已停止队列和下载队列的添加和删除，然后通过标志位在下载线程中处理关闭网络连接、在数据库中保存任务信息、在内存中加入已停止队列和调度排队队列中的下一个任务。其中单线程（不支持多线程）任务的停止（暂停）等同于取消。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/aa3735bc91c363fa0720c58ab672ce23b64fd6a3c36571b8382c3b650e509dd0)

        （4）取消下载（dlCancel）  
取消下载的操作对象是所有状态的任务。该方法需要特别区分已停止任务和就绪任务。下载中的任务从下载队列中删除后，在下载线程中关闭网络连接、清理数据（删除数据库信息和已下载文件）、调度下一个排队任务。对于排队中的任务，从排队队列中删除后，清理数据即可。已停止任务需从已停止队列中删除任务。而就绪任务不在内存的任务队列中，只需清理数据。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/65d87fcda292f3c8c79261c321811570593671f391d29e8f262593b1fb036810)

## 3.3 关键技术的实现

### 3.3.1 任务队列

        下载管理一共包含4个支持线程并发的任务队列。  
        1）下载队列（**ConcurrentHashMap**）。用于保存正在下载的任务信息（DLTaskInfo）。  
2）下载优先级队列（**SynchronizedList**）。考虑到ConcurrentHashMap插入Entry的无序性，故设置一个保存正在下载任务优先级的队列用于快速查找。  
        3）已停止队列（**ConcurrentHashMap**）。用于保存执行过的已停止任务信息。  
        4）排队队列（**SynchronizedList
**）。用于保存排队中的任务信息，按任务优先级从高到底排列，高优先级任务位于队首，便于取出。

### 3.3.2 任务调度

任务调度以任务的优先级为依据。优先级越高，优先级的正值越小。对未指定优先级的处理在启动下载的dlStart方法中的“设置任务优先级”部分，设计此项可为多次执行的下载任务改变优先级。

优先级(int)

|

说明  
  
---|---  
  
PRIO_LOW(3)

|

文件下载任务低优先级（默认）  
  
PRIO_NORMAL(2)

|

文件下载任务中优先级  
  
PRIO_HIGH(1)

|

文件下载任务高优先级  
  
PRIO_UNSPECIFIED(0)

|

使用原有优先级，未指定时使用默认低优先级  
  
下载队列中保存的任务数是有上限的，超出上限的任务需保存至排队队列中。因此，当有任务结束（完成/停止/取消）时需要通过任务调度执行排队队列中的其他任务。基于优先级的任务调度从排队队列中取出第一个排队任务（优先级最高），加入下载队列开始下载。

    
    
        /**
         * 调度排队任务
         *
         * @return
         */
        synchronized DLManager scheduleDLTask() {
            if (!TASK_QUEUE.isEmpty()) {
                if (TASK_DLING.size() >= mMaxTask) {
                    LogUtil.logD(TAG, "TASK_DLING_PRIO中最低优先级为" + TASK_DLING_PRIO.get(TASK_DLING_PRIO.size() - 1).priority);
                    LogUtil.logD(TAG, "TASK_PREPARE中最高优先级为" + TASK_QUEUE.get(0).priority);
                    if (TASK_DLING_PRIO.get(TASK_DLING_PRIO.size() - 1).priority < TASK_QUEUE.get(0).priority) {
                        LogUtil.logD(TAG, "排序队列中没有可替换调度的任务");
                    }
                } else {
                    DLTaskInfo info = popPrepareTask();
                    addDLTaskPriority(info);
                    TASK_DLING.put(info.baseUrl, info);
                    info.status = STATUS_DOWNLOADING;
                    if (info.hasListener) {
                        info.listener.onPrepare(info.baseUrl);
                    }
                    POOL_TASK.execute(new DLTask(info));
                }
            }
            return sManager;
        }

### 3.3.3 任务/线程模型（DLTask/DLThread）

由于一些原因，本下载组件设计之初加入了单文件多线程分段下载的支持（实际上移动端通常采用的做法是单文件单线程，因为这样足够用），增强了一定的健壮性。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/d2855b1d9e8f863efededcd70b975267bb738961d4eb01256010b516818dd6ed)

文件下载初始化时创建了线程池**POOL_TASK**负责执行下载任务和线程池**POOL_THREAD**负责执行下载线程，线程池大小和阻塞队列长度根据设备运行时的CPU核心数确定。

    
    
        private final ExecutorService POOL_TASK = new ThreadPoolExecutor(POOL_SIZE,
                POOL_SIZE_MAX, 3, TimeUnit.SECONDS, POOL_QUEUE_TASK, TASK_FACTORY);
        private final ExecutorService POOL_Thread = new ThreadPoolExecutor(POOL_SIZE * 5,
                POOL_SIZE_MAX * 5, 1, TimeUnit.SECONDS, POOL_QUEUE_THREAD, THREAD_FACTORY);

        启动下载后，线程池**POOL_TASK**开始执行下载任务：  
1）使用**HttpURLConnection**建立网络连接获取响应码和头信息（文件长度、文件名等），确定是否使用多线程（响应码为200或响应码为206且文件长度为0时使用单线程，**_注：此处可能有别的判断方法，需根据服务器的实际情况判断_**）。  
        2）校验本地文件（包括临时文件）是否存在和完整，决定是否继续下载。可根据MD5进行文件完整性校验。  
        3）初始化和同步数据库中的任务信息和线程信息。历史任务直接恢复线程信息。如使用多线程，线程数根据每个线程最大长度的配置值计算得出。

    
    
        /**
         * 设置线程信息
         */
        private void dlDispatch() {
            int threadSize;
            int threadLength;
            // 线程数下限: 小于LENGTH_PER_THREAD开单线程
            if (info.totalBytes <= LENGTH_PER_THREAD) {
                threadSize = 1;
            }
            // 线程数上限: 大于LENGTH_PER_THREAD * 2开2个线程
            else if (info.totalBytes > LENGTH_PER_THREAD * 2) {
                threadSize = 2;
            }
            // 根据文件大小分配线程
            else {
                threadSize = info.totalBytes / LENGTH_PER_THREAD;
            }
            threadLength = info.totalBytes / threadSize;
            int remainder = info.totalBytes % threadLength;
            LogUtil.logD(TAG, "thread calc finished:" + info.baseUrl + ", threadSize=" + threadSize);
            for (int i = 0; i < threadSize; i++) {
                int start = i * threadLength;
                int end = start + threadLength - 1;
                if (i == threadSize - 1) {
                    end = start + threadLength + remainder;
                }
                DLThreadInfo threadInfo =
                        new DLThreadInfo(UUID.randomUUID().toString(), info.baseUrl, start, end);
                info.addDLThread(threadInfo);
                DLDBManager.getInstance().insertThreadInfo(threadInfo);
                DLManager.getInstance().addDLThread(new DLThread(threadInfo, info, this));
                LogUtil.logD(TAG, "not resume task thread added:" + info.baseUrl);
            }
        }

        线程初始化完成后，线程池**POOL_THREAD**开始执行下载线程：  
        1）设置请求头的Range参数为线程的起始位置和结束位置，使用**HttpURLConnection**用GET方式建立网络连接。

    
    
        /**
         * 添加请求头参数
         *
         * @param conn
         */
        private void addRequestHeaders(HttpURLConnection conn) {
            for (DLHeader header : dlInfo.requestHeaders) {
                conn.addRequestProperty(header.key, header.value);
            }
            conn.setRequestProperty("Range", "bytes=" + dlThreadInfo.start + "-" + dlThreadInfo.end);
        }

        2）根据线程的起始和结束位置使用**RandomAccessFile**实现文件的随机读写。

    
    
                raf = new RandomAccessFile(dlInfo.file, "rw");
                fd = raf.getFD();
                // 定位到开始写文件位置
                raf.seek(dlThreadInfo.start);
    
                byte[] b = new byte[RAF_BUFFER_SIZE];
                int len;
                while (!dlThreadInfo.isStop && !dlThreadInfo.isCancel && !dlThreadInfo.isQueue && !dlInfo.isQueue && (len
                        = bis.read(b)) != -1) {
                    dlThreadInfo.start += len;
                    raf.write(b, 0, len);
                    listener.onProgress(len, fd, dlThreadInfo);
                }

3）下载进度回调（onProgress）在下载过程中不断被调用，完成文件写入和进度保存（内存和数据库）。结合最短间隔和最小已下载文件长度增量控制回调频率，防止UI刷新过快（掉帧处理）。并配合
**FileDescriptor**实现延迟写入存储设备，解决RandomAccessFile无缓冲的问题，最大程度地提升下载效率。**_注：此处也可采用NIO方式解决RandomAccessFile无缓冲的问题。_**

    
    
       @Override
        public synchronized void onProgress(int progress, FileDescriptor fd, DLThreadInfo threadInfo) {
            info.currentBytes += progress;
            LogUtil.logD(TAG, info.currentBytes + "");
    
            long timeNow = SystemClock.elapsedRealtime();
            long timeDelta = timeNow - lastTime;
            int bytesDelta = info.currentBytes - lastTotalBytes;
    
            if (timeDelta > MIN_PROGRESS_INTERVAL && bytesDelta > MIN_PROGRESS_STEP) {
                // 同步文件
                if (fd != null) {
                    try {
                        fd.sync();
                    } catch (SyncFailedException e) {
                        e.printStackTrace();
                    }
                }
                // 更新数据库
                if (threadInfo != null) {
                    DLDBManager.getInstance().updateThreadInfo(threadInfo);
                    DLDBManager.getInstance().updateTaskInfo(info);
                }
                // 保存本次进度
                lastTime = timeNow;
                lastTotalBytes = info.currentBytes;
                // 通知UI
                if (info.hasListener) {
                    info.listener.onProgress(info.currentBytes, info.totalBytes, info.baseUrl);
                }
            }
        }

        4）下载完成回调（onFinish）在下载完成时被调用，删除下载任务和数据库中的任务信息后进行任务调度。

### 3.3.4 数据表设计

文件下载需要在下载过程中对下载任务和下载线程信息进行持久化，以保证文件下载线程或App被结束后能够实现断点续传，减少重复的下载量。与**DownloadManager**思路相同，但只使用数据库存储供App内部使用。  
两张表以baseUrl建立关联。线程表只保存本线程的起始位置和结束位置，UUID方便线程完成后删除线程。任务表保存除线程表中以外的所有任务相关信息。

下载任务数据表

**字段******

|

**类型******

|

**说明******

|

**约束******  
  
---|---|---|---  
  
_id

|

Integer

|

唯一标识符

|

自增主键，不可为空  
  
baseUrl

|

Varchar(255)

|

文件原始URL

|

不可为空  
  
realUrl

|

Varchar(255)

|

文件真实URL

|

不可为空  
  
dirPath

|

Varchar(127)

|

文件保存路径

|

不可为空  
  
fileName

|

Varchar(30)

|

文件保存名称

|

不可为空  
  
currentBytes

|

Integer

|

文件已下载大小

|

非负  
  
totalBytes

|

Integer

|

文件总大小

|

非负  
  
priority

|

Integer

|

任务优先级

|

无  
  


下载线程数据表

**字段******

|

**类型******

|

**说明******

|

**约束******  
  
---|---|---|---  
  
_id

|

Integer

|

唯一标识符

|

自增主键，不可为空  
  
baseUrl

|

Varchar(255)

|

文件原始URL

|

外键，不可为空  
  
id

|

Varchar(127)

|

线程UUID，唯一标识线程

|

不可为空  
  
startPos

|

Integer

|

线程开始下载位置（Bytes）

|

非负  
  
endPos

|

Integer

|

线程结束下载位置（Bytes）

|

非负  
  
### 3.3.5 消息通知

文件下载内部的任务/线程模型基本上是异步操作，因此需要通过回调实现相互通知。外部调用者也需要知道下载执行的过程，因此提供了两种消息通知机制，即回调和事件总线。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/38c0ffce784a2d5ddaea60640110de13becaff1d4d94a69072d6d2bccbef5117)

上图描述了线程（**DLThread**）通知任务（**DLTask**）的流程。外部改变线程中不同状态的标记位结束线程的下载过程，线程通过线程监听（**IDLThreadListener**）的onXXX的回调方法通知任务进行处理。  
最重要的是对外部调用者的消息通知。和内部通知类似，文件下载提供了一种任务监听（**IDListener**），包含了9种回调方法，如下表所示。

**方法名******

|

**参数******

|

**调用时机******

|

**调用线程******  
  
---|---|---|---  
  
onCreate

|

dLTaskInfo

|

任务创建完成并入库

|

主线程  
  
onPrepare

|

baseUrl

|

任务入队，即将开始下载

|

主/后台线程  
  
onError

|

status, msg, baseUrl

|

产生异常情况

|

主/后台线程  
  
onStart

|

fileName, baseUrl, fileLength

|

任务初始化完成

|

后台线程  
  
onProgress

|

progress, totalBytes, baseUrl

|

下载进度更新

|

后台线程  
  
onStop

|

progress, baseUrl

|

停止下载任务

|

主/后台线程  
  
onFinish

|

file, baseUrl

|

任务下载完成

|

主/后台线程  
  
onCancel

|

baseUrl

|

取消下载任务

|

主/后台线程  
  
onQueue

|

baseUrl

|

任务进入排队

|

主/后台线程  
  
从表中注意到不同回调方法的调用线程不同。为方便使用，提供了两种回调监听实现类。一种是**SimpleDListener**，默认所有回调方法的实现为空，通知方和接收方一对一耦合；另一种为**EventBusDListener**，每个回调方法的实现类均为发送**EventBus**事件，方便事件接收方完成线程切换和全局监听。

    
    
    /**
     * 使用EventBus的Download Listener
     */
    public class EventBusDLListener implements IDListener {
    
        @Override
        public void onCreate(DLTaskInfo info) {
            EventBus.getDefault().post(new DLCreateEvent(info));
        }
    
        @Override
        public void onPrepare(String baseUrl) {
            EventBus.getDefault().post(new DLPrepareEvent(baseUrl));
        }
    
    
        @Override
        public void onStart(String fileName, String baseUrl, int fileLength) {
            EventBus.getDefault().post(new DLStartEvent(fileName, baseUrl, fileLength));
        }
    
    
        @Override
        public void onProgress(int progress, int total, String baseUrl) {
            EventBus.getDefault().post(new DLProgressEvent(progress, total, baseUrl));
        }
    
    
        @Override
        public void onStop(int progress, String baseUrl) {
            EventBus.getDefault().post(new DLStopEvent(progress, baseUrl));
        }
    
    
        @Override
        public void onFinish(File file, String baseUrl) {
            EventBus.getDefault().post(new DLFinishEvent(file, baseUrl));
        }
    
    
        @Override
        public void onError(int status, String error, String baseUrl) {
            EventBus.getDefault().post(new DLErrorEvent(status, error, baseUrl));
        }
    
    
        @Override
        public void onCancel(String baseUrl) {
            EventBus.getDefault().post(new DLCancelEvent(baseUrl));
        }
    
    
        @Override
        public void onQueue(String baseUrl) {
            EventBus.getDefault().post(new DLQueueEvent(baseUrl));
        }
    }



## 3.4 设计总结

        下载管理主要类图如下。

![](/image/yi_zhong_xia_zai_guan_li_fang_an_de_she_ji_yu_shi_xian/e2ee46cab3de2a96e58d0ecf343e868ebbd40d1bdca95090135827c98e311fae)

  
        **DLManager**负责与外部的交互和下载过程的控制。**DLDBManager**负责数据库的读写。**DLTask**和**DLThread**负责完成下载逻辑，其中**DLTaskInfo**和**DLThreadInfo**分别为任务和线程信息的实体类，**IDLThreadListener**负责线程和任务间的通信。**IDListener**以及它的两个实现类负责文件下载与外部的通信。

# 四、优化和总结

        针对部分低端机型下载过程中可能遇到的下载速度偏低、系统响应迟钝的情况，做了一定的优化。  
1）对**DLTask**和**DLThread**等后台线程，降低线程优先级。调用代码Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)即可。  
2）对**HttpURLConnection**使用**BufferedInputStream**包装输入流，并将读取数据的缓冲区适当增大为8KB（8*1024），减少存储设备I/O次数。  
        结合上文叙述的**掉帧处理**，优化后卡顿现象明显改善，下载速度能够达到最大带宽。

* * *

另外，本文描述的下载管理方案可能存在如主进程下载的不稳定性、不支持跨进程通信等一些问题，实际应用中仍需做进一步的改进。但总体思路仍具有一定的参考意义。

        Thanks~~~

