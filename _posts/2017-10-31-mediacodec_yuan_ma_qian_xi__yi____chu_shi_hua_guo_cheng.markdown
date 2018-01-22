---
layout: post
title: "MediaCodec源码浅析(一)-----初始化过程"
date: 2017-10-31 21:26:00 +0800
categories: android
author: fredguo
tags: mediacodec Android
---

* content
{:toc}

| 导语 本文会结合源码简单分析一下Android中编解码相关的核心类MediaCodec的初始化过程，以及Android对于硬件编码所设计的OMX规范。

# MediaCodec对象初始化过程

我们从一段基本的代码出发，来看下每个方法背后的代码执行路径
<!--more-->

    
    
    MediaCodec codec = MediaCodec.createEncoderByType("video/avc");
    MediaFormat format = MediaFormat.createVideoFormat("video/avc", 320, 480);
    // format配置的代码...
    codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
    codec.start()
    

那我们先来看下`MediaCodec#createEncoderByType()`方法，这个方法事实上包装一些参数后来到`MediaCodec(String
name, boolean nameIsType, boolean encoder)`

    
    
    private MediaCodec(
                @NonNull String name, boolean nameIsType, boolean encoder) {
            Looper looper;
            if ((looper = Looper.myLooper()) != null) {
                mEventHandler = new EventHandler(this, looper);
            } else if ((looper = Looper.getMainLooper()) != null) {
                mEventHandler = new EventHandler(this, looper);
            } else {
                mEventHandler = null;
            }
            mCallbackHandler = mEventHandler;
            mOnFrameRenderedHandler = mEventHandler;
    
            mBufferLock = new Object();
    
            native_setup(name, nameIsType, encoder);
        }
    

这里我们看到我们初始化了一个Handler和一个缓冲对象的对象锁。我们接着来看native_setup()方法

    
    
    static void android_media_MediaCodec_native_setup(
            JNIEnv *env, jobject thiz,
            jstring name, jboolean nameIsType, jboolean encoder) {
        // ... 省略部分代码
    
        const char *tmp = env->GetStringUTFChars(name, NULL);
    
        if (tmp == NULL) {
            return;
        }
    
        sp codec = new JMediaCodec(env, thiz, tmp, nameIsType, encoder);
    
        const status_t err = codec->initCheck();
        // ... 省略部分代码
        codec->registerSelf();
    
        setMediaCodec(env,thiz, codec);
    }
    

### JMediaCodec初始化过程

看到JMediaCodec的构造方法

    
    
    JMediaCodec::JMediaCodec(
            JNIEnv *env, jobject thiz,
            const char *name, bool nameIsType, bool encoder)
        : mClass(NULL),
          mObject(NULL) {
        jclass clazz = env->GetObjectClass(thiz);
        CHECK(clazz != NULL);
    
        mClass = (jclass)env->NewGlobalRef(clazz);
        mObject = env->NewWeakGlobalRef(thiz);
    
        cacheJavaObjects(env);
    
        mLooper = new ALooper;
        mLooper->setName("MediaCodec_looper");
    
        mLooper->start(
                false,      // runOnCallingThread
                true,       // canCallJava
                PRIORITY_FOREGROUND);
    
        if (nameIsType) {
            mCodec = MediaCodec::CreateByType(mLooper, name, encoder, &mInitStatus);
        } else {
            mCodec = MediaCodec::CreateByComponentName(mLooper, name, &mInitStatus);
        }
        CHECK((mCodec != NULL) != (mInitStatus != OK));
    }
    

这里我们看到JMediaCodec同样有一个mLooper成员变量，这个变量是一个ALooper对象，初始化mLooper后开始start()，start()方法内部会开启一个线程并run。nameIsType此时为true，来到`MediaCodec::CreateByType()`方法

    
    
    sp MediaCodec::CreateByType(
            const sp &looper, const AString &mime, bool encoder, status_t *err, pid_t pid) {
        sp codec = new MediaCodec(looper, pid);
    
        const status_t ret = codec->init(mime, true /* nameIsType */, encoder);
        if (err != NULL) {
            *err = ret;
        }
        return ret == OK ? codec : NULL; // NULL deallocates codec.
    }
    

请记住此时传入的Looper对象是android_media_MediaCodec中JMediaCodec对象的mLooper成员变量，我们知道在Android消息队列机制中**一个线程只能和一个Looper实例对应**。好，我们接着看MediaCodec的构造函数

### MediaCodec native初始化过程

    
    
    MediaCodec::MediaCodec(const sp &looper, pid_t pid)
        : mState(UNINITIALIZED),
          mReleasedByResourceManager(false),
          mLooper(looper),
          mCodec(NULL),
          mReplyID(0),
          mFlags(0),
          mStickyError(OK),
          mSoftRenderer(NULL),
          mResourceManagerClient(new ResourceManagerClient(this)),
          mResourceManagerService(new ResourceManagerServiceProxy(pid)),
          mBatteryStatNotified(false),
          mIsVideo(false),
          mVideoWidth(0),
          mVideoHeight(0),
          mRotationDegrees(0),
          mDequeueInputTimeoutGeneration(0),
          mDequeueInputReplyID(0),
          mDequeueOutputTimeoutGeneration(0),
          mDequeueOutputReplyID(0),
          mHaveInputSurface(false),
          mHavePendingInputBuffers(false) {
    }
    

就是参数列表，先不急着一个个看，来到代码逻辑后面看`MediaCodec:init()`方法

    
    
    status_t MediaCodec::init(const AString &name, bool nameIsType, bool encoder) {
        mResourceManagerService->init();
    
        // save init parameters for reset
        mInitName = name;
        mInitNameIsType = nameIsType;
        mInitIsEncoder = encoder;
    
        // Current video decoders do not return from OMX_FillThisBuffer
        // quickly, violating the OpenMAX specs, until that is remedied
        // we need to invest in an extra looper to free the main event
        // queue.
    
        mCodec = GetCodecBase(name, nameIsType);
        if (mCodec == NULL) {
            return NAME_NOT_FOUND;
        }
    
        bool secureCodec = false;
        if (nameIsType && !strncasecmp(name.c_str(), "video/", 6)) {
            mIsVideo = true;
        } else {
            AString tmp = name;
            if (tmp.endsWith(".secure")) {
                secureCodec = true;
                tmp.erase(tmp.size() - 7, 7);
            }
            const sp mcl = MediaCodecList::getInstance();
            if (mcl == NULL) {
                mCodec = NULL;  // remove the codec.
                return NO_INIT; // if called from Java should raise IOException
            }
            ssize_t codecIdx = mcl->findCodecByName(tmp.c_str());
            if (codecIdx >= 0) {
                const sp info = mcl->getCodecInfo(codecIdx);
                Vector mimes;
                info->getSupportedMimes(&mimes);
                for (size_t i = 0; i < mimes.size(); i++) {
                    if (mimes[i].startsWith("video/")) {
                        mIsVideo = true;
                        break;
                    }
                }
            }
        }
    
        if (mIsVideo) {
            // video codec needs dedicated looper
            if (mCodecLooper == NULL) {
                mCodecLooper = new ALooper;
                mCodecLooper->setName("CodecLooper");
                mCodecLooper->start(false, false, ANDROID_PRIORITY_AUDIO);
            }
    
            mCodecLooper->registerHandler(mCodec);
        } else {
            mLooper->registerHandler(mCodec);
        }
    
        mLooper->registerHandler(this);
    
        mCodec->setNotificationMessage(new AMessage(kWhatCodecNotify, this));
    
        sp msg = new AMessage(kWhatInit, this);
        msg->setString("name", name);
        msg->setInt32("nameIsType", nameIsType);
    
        if (nameIsType) {
            msg->setInt32("encoder", encoder);
        }
    
        status_t err;
        Vector resources;
        MediaResource::Type type =
                secureCodec ? MediaResource::kSecureCodec : MediaResource::kNonSecureCodec;
        MediaResource::SubType subtype =
                mIsVideo ? MediaResource::kVideoCodec : MediaResource::kAudioCodec;
        resources.push_back(MediaResource(type, subtype, 1));
        for (int i = 0; i <= kMaxRetry; ++i) {
            if (i > 0) {
                // Don't try to reclaim resource for the first time.
                if (!mResourceManagerService->reclaimResource(resources)) {
                    break;
                }
            }
    
            sp response;
            err = PostAndAwaitResponse(msg, &response);
            if (!isResourceError(err)) {
                break;
            }
        }
        return err;
    }
    

我们看到这里用`getCodecBase()`方法初始化了mCodec成员变量

    
    
    sp MediaCodec::GetCodecBase(const AString &name, bool nameIsType) {
        // at this time only ACodec specifies a mime type.
        if (nameIsType || name.startsWithIgnoreCase("omx.")) {
            return new ACodec;
        } else if (name.startsWithIgnoreCase("android.filter.")) {
            return new MediaFilter;
        } else {
            return NULL;
        }
    }
    

这里`nameIsType`为true，于是我们就会构建一个`ACodec`实例

    
    
    ACodec::ACodec()
        : mQuirks(0),
          mNode(0),
          mUsingNativeWindow(false),
          mNativeWindowUsageBits(0),
          mLastNativeWindowDataSpace(HAL_DATASPACE_UNKNOWN),
          mIsVideo(false),
          mIsEncoder(false),
          mFatalError(false),
          mShutdownInProgress(false),
          mExplicitShutdown(false),
          mIsLegacyVP9Decoder(false),
          mEncoderDelay(0),
          mEncoderPadding(0),
          mRotationDegrees(0),
          mChannelMaskPresent(false),
          mChannelMask(0),
          mDequeueCounter(0),
          mInputMetadataType(kMetadataBufferTypeInvalid),
          mOutputMetadataType(kMetadataBufferTypeInvalid),
          mLegacyAdaptiveExperiment(false),
          mMetadataBuffersToSubmit(0),
          mNumUndequeuedBuffers(0),
          mRepeatFrameDelayUs(-1ll),
          mMaxPtsGapUs(-1ll),
          mMaxFps(-1),
          mTimePerFrameUs(-1ll),
          mTimePerCaptureUs(-1ll),
          mCreateInputBuffersSuspended(false),
          mTunneled(false),
          mDescribeColorAspectsIndex((OMX_INDEXTYPE)0),
          mDescribeHDRStaticInfoIndex((OMX_INDEXTYPE)0) {
        mUninitializedState = new UninitializedState(this);
        mLoadedState = new LoadedState(this);
        mLoadedToIdleState = new LoadedToIdleState(this);
        mIdleToExecutingState = new IdleToExecutingState(this);
        mExecutingState = new ExecutingState(this);
    
        mOutputPortSettingsChangedState =
            new OutputPortSettingsChangedState(this);
    
        mExecutingToIdleState = new ExecutingToIdleState(this);
        mIdleToLoadedState = new IdleToLoadedState(this);
        mFlushingState = new FlushingState(this);
    
        mPortEOS[kPortIndexInput] = mPortEOS[kPortIndexOutput] = false;
        mInputEOSResult = OK;
    
        memset(&mLastNativeWindowCrop, 0, sizeof(mLastNativeWindowCrop));
    
        changeState(mUninitializedState);
    }
    

我们先回到刚才的MediaCodec::init()方法来，看到后面的一段代码

    
    
    if (mIsVideo) {
            // video codec needs dedicated looper
            if (mCodecLooper == NULL) {
                mCodecLooper = new ALooper;
                mCodecLooper->setName("CodecLooper");
                mCodecLooper->start(false, false, ANDROID_PRIORITY_AUDIO);
            }
    
            mCodecLooper->registerHandler(mCodec);
        } else {
            mLooper->registerHandler(mCodec);
        }
    
        mLooper->registerHandler(this);
    
        mCodec->setNotificationMessage(new AMessage(kWhatCodecNotify, this));
    
        sp msg = new AMessage(kWhatInit, this);
        msg->setString("name", name);
        msg->setInt32("nameIsType", nameIsType);
    
        if (nameIsType) {
            msg->setInt32("encoder", encoder);
        }
    
        status_t err;
        Vector resources;
        MediaResource::Type type =
                secureCodec ? MediaResource::kSecureCodec : MediaResource::kNonSecureCodec;
        MediaResource::SubType subtype =
                mIsVideo ? MediaResource::kVideoCodec : MediaResource::kAudioCodec;
        resources.push_back(MediaResource(type, subtype, 1));
        for (int i = 0; i <= kMaxRetry; ++i) {
            if (i > 0) {
                // Don't try to reclaim resource for the first time.
                if (!mResourceManagerService->reclaimResource(resources)) {
                    break;
                }
            }
    
            sp response;
            err = PostAndAwaitResponse(msg, &response);
            if (!isResourceError(err)) {
                break;
            }
        }
    

在这里我们看到init()方法发送了一条`kWhatInit`的Msg，我们直接来看对应的回调`MediaCodec::onMessageReceived()`方法

    
    
    case kWhatInit:
            {
                sp replyID;
                CHECK(msg->senderAwaitsResponse(&replyID));
    
                if (mState != UNINITIALIZED) {
                    PostReplyWithError(replyID, INVALID_OPERATION);
                    break;
                }
    
                mReplyID = replyID;
                setState(INITIALIZING);
    
                AString name;
                CHECK(msg->findString("name", &name));
    
                int32_t nameIsType;
                int32_t encoder = false;
                CHECK(msg->findInt32("nameIsType", &nameIsType));
                if (nameIsType) {
                    CHECK(msg->findInt32("encoder", &encoder));
                }
    
                sp format = new AMessage;
    
                if (nameIsType) {
                    format->setString("mime", name.c_str());
                    format->setInt32("encoder", encoder);
                } else {
                    format->setString("componentName", name.c_str());
                }
    
                mCodec->initiateAllocateComponent(format);
                break;
            }
    

主要是改变内部状态为INITIALIZING，同时调用了mCodec(此时为ACodec)的initiateAllocateComponent()方法

    
    
    void ACodec::initiateAllocateComponent(const sp &msg) {
        msg->setWhat(kWhatAllocateComponent);
        msg->setTarget(this);
        msg->post();
    }
    

同样的按照消息队列机制找到回调`ACodec::UninitializedState::onMessageReceived(const sp &msg)`

    
    
     case ACodec::kWhatAllocateComponent:
            {
                onAllocateComponent(msg);
                handled = true;
                break;
            }
    

MediaCodec::UninitializedState::onAllocateComponent()

    
    
    bool ACodec::UninitializedState::onAllocateComponent(const sp &msg) {
        ALOGV("onAllocateComponent");
    
        CHECK(mCodec->mNode == 0);
    
        OMXClient client;
        if (client.connect() != OK) {
            mCodec->signalError(OMX_ErrorUndefined, NO_INIT);
            return false;
        }
    
        sp omx = client.interface();
    
        sp notify = new AMessage(kWhatOMXDied, mCodec);
    
        Vector matchingCodecs;
    
        AString mime;
    
        AString componentName;
        uint32_t quirks = 0;
        int32_t encoder = false;
        if (msg->findString("componentName", &componentName)) {
            sp list = MediaCodecList::getInstance();
            if (list != NULL && list->findCodecByName(componentName.c_str()) >= 0) {
                matchingCodecs.add(componentName);
            }
        } else {
            CHECK(msg->findString("mime", &mime));
    
            if (!msg->findInt32("encoder", &encoder)) {
                encoder = false;
            }
    
            MediaCodecList::findMatchingCodecs(
                    mime.c_str(),
                    encoder, // createEncoder
                    0,       // flags
                    &matchingCodecs);
        }
    
        sp observer = new CodecObserver;
        IOMX::node_id node = 0;
    
        status_t err = NAME_NOT_FOUND;
        for (size_t matchIndex = 0; matchIndex < matchingCodecs.size();
                ++matchIndex) {
            componentName = matchingCodecs[matchIndex];
            quirks = MediaCodecList::getQuirksFor(componentName.c_str());
    
            pid_t tid = gettid();
            int prevPriority = androidGetThreadPriority(tid);
            androidSetThreadPriority(tid, ANDROID_PRIORITY_FOREGROUND);
            err = omx->allocateNode(componentName.c_str(), observer, &mCodec->mNodeBinder, &node);
            androidSetThreadPriority(tid, prevPriority);
    
            if (err == OK) {
                break;
            } else {
                ALOGW("Allocating component '%s' failed, try next one.", componentName.c_str());
            }
    
            node = 0;
        }
    
        if (node == 0) {
            if (!mime.empty()) {
                ALOGE("Unable to instantiate a %scoder for type '%s' with err %#x.",
                        encoder ? "en" : "de", mime.c_str(), err);
            } else {
                ALOGE("Unable to instantiate codec '%s' with err %#x.", componentName.c_str(), err);
            }
    
            mCodec->signalError((OMX_ERRORTYPE)err, makeNoSideEffectStatus(err));
            return false;
        }
    
        mDeathNotifier = new DeathNotifier(notify);
        if (mCodec->mNodeBinder == NULL ||
                mCodec->mNodeBinder->linkToDeath(mDeathNotifier) != OK) {
            // This was a local binder, if it dies so do we, we won't care
            // about any notifications in the afterlife.
            mDeathNotifier.clear();
        }
    
        notify = new AMessage(kWhatOMXMessageList, mCodec);
        observer->setNotificationMessage(notify);
    
        mCodec->mComponentName = componentName;
        mCodec->mRenderTracker.setComponentName(componentName);
        mCodec->mFlags = 0;
    
        if (componentName.endsWith(".secure")) {
            mCodec->mFlags |= kFlagIsSecure;
            mCodec->mFlags |= kFlagIsGrallocUsageProtected;
            mCodec->mFlags |= kFlagPushBlankBuffersToNativeWindowOnShutdown;
        }
    
        mCodec->mQuirks = quirks;
        mCodec->mOMX = omx;
        mCodec->mNode = node;
    
        {
            sp notify = mCodec->mNotify->dup();
            notify->setInt32("what", CodecBase::kWhatComponentAllocated);
            notify->setString("componentName", mCodec->mComponentName.c_str());
            notify->post();
        }
    
        mCodec->changeState(mCodec->mLoadedState);
    
        return true;
    }
    

这段代码中，我们看到mCodec的mOMX被初始化，而omx对象的初始化过程非常像是C/S架构，那么我们这里插入一段，介绍下Android
中OMX的实现手段了

![](/image/mediacodec_yuan_ma_qian_xi__yi____chu_shi_hua_guo_cheng/7f983cecbf97186699d5a7f48d03ee1bae3506769d69626c512011fdeb42e596)  

[ Android media architecture ]

先看OMXClient::connect()方法

    
    
    status_t OMXClient::connect() {
        sp sm = defaultServiceManager();
        sp playerbinder = sm->getService(String16("media.player"));
        sp mediaservice = interface_cast(playerbinder);
    
        if (mediaservice.get() == NULL) {
            ALOGE("Cannot obtain IMediaPlayerService");
            return NO_INIT;
        }
    
        sp mediaServerOMX = mediaservice->getOMX();
        if (mediaServerOMX.get() == NULL) {
            ALOGE("Cannot obtain mediaserver IOMX");
            return NO_INIT;
        }
    
        // If we don't want to use the codec process, and the media server OMX
        // is local, use it directly instead of going through MuxOMX
        if (!sCodecProcessEnabled &&
                mediaServerOMX->livesLocally(0 /* node */, getpid())) {
            mOMX = mediaServerOMX;
            return OK;
        }
    
        sp codecbinder = sm->getService(String16("media.codec"));
        sp codecservice = interface_cast(codecbinder);
    
        if (codecservice.get() == NULL) {
            ALOGE("Cannot obtain IMediaCodecService");
            return NO_INIT;
        }
    
        sp mediaCodecOMX = codecservice->getOMX();
        if (mediaCodecOMX.get() == NULL) {
            ALOGE("Cannot obtain mediacodec IOMX");
            return NO_INIT;
        }
    
        mOMX = new MuxOMX(mediaServerOMX, mediaCodecOMX);
    
        return OK;
    }
    

这里毫无疑问是做一次IPC工作，函数通过binder机制
获得到MediaPlayerService，然后通过MediaPlayerService来创建OMX的实例。这样OMXClient就获得到了OMX的入口，接下来就可以通过binder机制来获得OMX提供的服务。也就是说OMXClient
是Android中 openmax 的入口。

可以看到这里的mediaServerOMX, mediaCodecOMX都是Binder通信的代理对象，在AOSP官网上对与OMX的支持描述如下:

    
    
    Application Framework
    
    At the application framework level is application code that utilizesandroid.media APIs to interact with the multimedia hardware.
    
    Binder IPC
    
    The Binder IPC proxies facilitate communication over process boundaries. They are located in the frameworks/av/media/libmedia directory and begin with the letter "I".
    
    Native Multimedia Framework
    
    At the native level, Android provides a multimedia framework that utilizes the Stagefright engine for audio and video recording and playback. Stagefright comes with a default list of supported software codecs and you can implement your own hardware codec by using the OpenMax integration layer standard. For more implementation details, see the MediaPlayer and Stagefright components located in frameworks/av/media.
    
    OpenMAX Integration Layer (IL)
    
    The OpenMAX IL provides a standardized way for Stagefright to recognize and use custom hardware-based multimedia codecs called components. You must provide an OpenMAX plugin in the form of a shared library namedlibstagefrighthw.so. This plugin links Stagefright with your custom codec components, which must be implemented according to the OpenMAX IL component standard.
    

我们可以猜测，在Server端真正实现功能时，肯定是和这个
libstagefrighthw.so动态链接库有关。往后看的时候我们再来分析这个东西。这里获取OMX对象是整个MediaCodec功能实现的核心点，后面在configure方法的分析时会重点看这个对象的获取过程。

分析完这个函数后，我们再去看ACodec的构造函数中的一个函数:`changeState()`

这个函数的实现在`frameworks/av/media/libstagefright/foundation/AHierarchicalStateMachine.cpp`中

    
    
    void AHierarchicalStateMachine::changeState(const sp &state) {
        if (state == mState) {
            // Quick exit for the easy case.
            return;
        }
    
        Vector > A;
        sp cur = mState;
        for (;;) {
            A.push(cur);
            if (cur == NULL) {
                break;
            }
            cur = cur->parentState();
        }
    
        Vector > B;
        cur = state;
        for (;;) {
            B.push(cur);
            if (cur == NULL) {
                break;
            }
            cur = cur->parentState();
        }
    
        // Remove the common tail.
        while (A.size() > 0 && B.size() > 0 && A.top() == B.top()) {
            A.pop();
            B.pop();
        }
    
        mState = state;
    
        for (size_t i = 0; i < A.size(); ++i) {
            A.editItemAt(i)->stateExited();
        }
    
        for (size_t i = B.size(); i > 0;) {
            i--;
            B.editItemAt(i)->stateEntered();
        }
    }
    

同时我们看到ACodec.h中

    
    
    struct ACodec : public AHierarchicalStateMachine, public CodecBase {
        // .....
         // AHierarchicalStateMachine implements the message handling
        virtual void onMessageReceived(const sp &msg) {
            handleMessage(msg);
        }
    }
    

`CodecBase.h`中

    
    
    struct CodecBase : public AHandler, /* static */ ColorUtils {
    }
    

`AHierarchicalStateMachine.cpp`中

    
    
    void AHierarchicalStateMachine::handleMessage(const sp &msg) {
        sp save = mState;
    
        sp cur = mState;
        while (cur != NULL && !cur->onMessageReceived(msg)) {
            // If you claim not to have handled the message you shouldn't
            // have called setState...
            CHECK(save == mState);
    
            cur = cur->parentState();
        }
    
        if (cur != NULL) {
            return;
        }
    
        ALOGW("Warning message %s unhandled in root state.",
             msg->debugString().c_str());
    }
    

也就是说，从Handler传给ACodec的Message经过上面的逻辑都会转发到当前ACodec状态机上状态链上每一个`AState::onMessageReceived()`方法上,这个很关键，会对后面的MediaCodec#start(),
stop(), release()等都有关系

也就是说，Acodec内部事实上是一个维护了由AState子类构建的状态机，我们现在已经在构造函数中看到了它`changeState()`到了一个`mUninitializedState`状态

从刚才的changeState()方法可以看到，如果状态相同的会被直接移去，而状态不同的状态链，原有的状态链会被逐个调用`stateExited()`，现在新加入的状态链会翻转过来调用`stateEntered()`方法，我们接着就来看这个`UninitializedState::stateEntered()`做了什么

    
    
    void ACodec::UninitializedState::stateEntered() {
        ALOGV("Now uninitialized");
    
        if (mDeathNotifier != NULL) {
            mCodec->mNodeBinder->unlinkToDeath(mDeathNotifier);
            mDeathNotifier.clear();
        }
    
        mCodec->mUsingNativeWindow = false;
        mCodec->mNativeWindow.clear();
        mCodec->mNativeWindowUsageBits = 0;
        mCodec->mNode = 0;
        mCodec->mOMX.clear();
        mCodec->mQuirks = 0;
        mCodec->mFlags = 0;
        mCodec->mInputMetadataType = kMetadataBufferTypeInvalid;
        mCodec->mOutputMetadataType = kMetadataBufferTypeInvalid;
        mCodec->mConverter[0].clear();
        mCodec->mConverter[1].clear();
        mCodec->mComponentName.clear();
    }
    

其实就是初始化工作,到这里`MediaCodec`的构造过程基本上就分析完了，其中省略了大量关于Android消息机制native的逻辑，这一块可以参考一下网上很多的文章，而且这也不是这篇文章的重点

如果分析的有错误的话请在评论区指出，谢谢大家的阅读。

## 附录: OpenMAX IL

OpenMAX IL
API透过C语言致力于打造可移植的媒体组件的阵列的平台。这些组件可以是来源（source）、汇出（sink）、编解码器（codec）、过滤器（filter）、分离器（splitter）、混频器（mixers），或任何其他资料操作。

界面是用于抽象化硬件和软件架构的系统。OpenMAX IL
API允许用户装载，控制，连接和卸载各个组件。这种灵活的核心架构允许整合层可以轻松地实现任何媒体的使用情况，并实作图形基础的媒体框架。Android主要的多媒体引擎[StageFright](https://zh.wikipedia.org/w/index.php?title=StageFright&action=edit&redlink=1)是透过IBinder使用OpenMax，用于编解码（Codec）处理。按照OpenMAX的抽象，Android本身是不关心被构造的Codec到底是硬件解码还是软件解码的

