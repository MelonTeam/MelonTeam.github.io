---
layout: post
title: "Bitmap 源码阅读笔记"
date: 2017-09-01 00:00:00 +0800
categories: android
author: nearlei
tags: Bitmap
---

* content
{:toc}

| 导语 Android 系统上的图片的处理，跟Bitmap
这个类脱不了关系，我们有必要去深入阅读里面的源码，以便在工作中能更好的处理Bitmap相关的问题。

Bitmap 源码阅读笔记

<!--more-->
### Bitmap 源码阅读笔记

#### 前言

Android 系统上的图片的处理，跟Bitmap 这个类脱不了关系，我们有必要去深入阅读里面的源码，以便在工作中能更好的处理Bitmap相关的问题。

#### 阅读目标

在使用Bitmap 的过程中，我们遇到最大的问题就是Bitmap加载过程中 OOM 的问题 和 Bitmap 过多时的内存占用问题，因此我们主要是要了解的是
Bitmap 的加载流程 和 Bitmap里的内存到底是怎么分配，怎么释放

#### 入口

查看Bitmap.java 的构造方法就会发现 它不是一个 public 方法，而且注释写着 “called from JNI”
，因此它不像普通的类一样能随便new出来

Bitmap(long nativeBitmap, byte[] buffer, int width, int height, int density,

boolean isMutable, boolean requestPremultiplied,

byte[] ninePatchChunk, NinePatch.InsetStruct ninePatchInsets) {

.....

内容省略

.....

}

创建Bitmap 大致有两个途径，一个是通过 BitmapFactory.java 的decodeXXXXX 方法去创建，另外一个是 通过 Bitmap
里的createBitmap 方法去创建

我们先从BitmapFactory.java 的 decodeXXXX 这些方法里跟进去

/**

* Private helper function for decoding an InputStream natively. Buffers the input enough to

* do a rewind as needed, and supplies temporary storage if necessary. is MUST NOT be null.

*/

private static Bitmap decodeStreamInternal(InputStream is, Rect outPadding,
Options opts) {

// ASSERT(is != null);

byte [] tempStorage = null;

if (opts != null) tempStorage = opts.inTempStorage;

if (tempStorage == null) tempStorage = new byte[DECODE_BUFFER_SIZE];

return nativeDecodeStream(is, tempStorage, outPadding, opts);

}

这里会通过JNI 调用到native层的 BitmapFactory.cpp

static jobject nativeDecodeStream(JNIEnv* env, jobject clazz, jobject is,
jbyteArray storage,

jobject padding, jobject options) {

jobject bitmap = NULL;

SkAutoTDelete stream(CreateJavaInputStreamAdaptor(env, is, storage));

if (stream.get()) {

SkAutoTDelete bufferedStream(

SkFrontBufferedStream::Create(stream.detach(), BYTES_TO_BUFFER));

SkASSERT(bufferedStream.get() != NULL);

bitmap = doDecode(env, bufferedStream, padding, options);

}

return bitmap;

}

这里发现所有的 decodeXXXX 方法都会统一调用到 doDecode( ) 这个方法里

static jobject doDecode(JNIEnv* env, SkStreamRewindable* stream, jobject
padding, jobject options) {

int sampleSize = 1;

SkImageDecoder::Mode decodeMode = SkImageDecoder::kDecodePixels_Mode;

SkColorType prefColorType = kN32_SkColorType;

bool doDither = true;

bool isMutable = false;

float scale = 1.0f;

bool preferQualityOverSpeed = false;

bool requireUnpremultiplied = false;

jobject javaBitmap = NULL;

if (options != NULL) {

sampleSize = env->GetIntField(options, gOptions_sampleSizeFieldID);

if (optionsJustBounds(env, options)) {

decodeMode = SkImageDecoder::kDecodeBounds_Mode;

}

// initialize these, in case we fail later on

env->SetIntField(options, gOptions_widthFieldID, -1);

env->SetIntField(options, gOptions_heightFieldID, -1);

env->SetObjectField(options, gOptions_mimeFieldID, 0);

jobject jconfig = env->GetObjectField(options, gOptions_configFieldID);

prefColorType = GraphicsJNI::getNativeBitmapColorType(env, jconfig);

isMutable = env->GetBooleanField(options, gOptions_mutableFieldID);

doDither = env->GetBooleanField(options, gOptions_ditherFieldID);

preferQualityOverSpeed = env->GetBooleanField(options,

gOptions_preferQualityOverSpeedFieldID);

requireUnpremultiplied = !env->GetBooleanField(options,
gOptions_premultipliedFieldID);

javaBitmap = env->GetObjectField(options, gOptions_bitmapFieldID);

if (env->GetBooleanField(options, gOptions_scaledFieldID)) {

const int density = env->GetIntField(options, gOptions_densityFieldID);

const int targetDensity = env->GetIntField(options,
gOptions_targetDensityFieldID);

const int screenDensity = env->GetIntField(options,
gOptions_screenDensityFieldID);

if (density != 0 && targetDensity != 0 && density !=
screenDensity) {

scale = (float) targetDensity / density;

}

}

}

const bool willScale = scale != 1.0f;

SkImageDecoder* decoder = SkImageDecoder::Factory(stream);

if (decoder == NULL) {

return nullObjectReturn("SkImageDecoder::Factory returned null");

}

decoder->setSampleSize(sampleSize);

decoder->setDitherImage(doDither);

decoder->setPreferQualityOverSpeed(preferQualityOverSpeed);

decoder->setRequireUnpremultipliedColors(requireUnpremultiplied);

android::Bitmap* reuseBitmap = nullptr;

unsigned int existingBufferSize = 0;

if (javaBitmap != NULL) {

reuseBitmap = GraphicsJNI::getBitmap(env, javaBitmap);

if (reuseBitmap->peekAtPixelRef()->isImmutable()) {

ALOGW("Unable to reuse an immutable bitmap as an image decoder target.");

javaBitmap = NULL;

reuseBitmap = nullptr;

} else {

existingBufferSize = GraphicsJNI::getBitmapAllocationByteCount(env,
javaBitmap);

}

}

NinePatchPeeker peeker(decoder);

decoder->setPeeker(&peeker);

JavaPixelAllocator javaAllocator(env);

RecyclingPixelAllocator recyclingAllocator(reuseBitmap, existingBufferSize);

ScaleCheckingAllocator scaleCheckingAllocator(scale, existingBufferSize);

SkBitmap::Allocator* outputAllocator = (javaBitmap != NULL) ?

(SkBitmap::Allocator*)&recyclingAllocator :
(SkBitmap::Allocator*)&javaAllocator;

if (decodeMode != SkImageDecoder::kDecodeBounds_Mode) {

if (!willScale) {

// If the java allocator is being used to allocate the pixel memory, the
decoder

// need not write zeroes, since the memory is initialized to 0.

decoder->setSkipWritingZeroes(outputAllocator == &javaAllocator);

decoder->setAllocator(outputAllocator);

} else if (javaBitmap != NULL) {

// check for eventual scaled bounds at allocation time, so we don't decode the
bitmap

// only to find the scaled result too large to fit in the allocation

decoder->setAllocator(&scaleCheckingAllocator);

}

}

// Only setup the decoder to be deleted after its stack-based, refcounted

// components (allocators, peekers, etc) are declared. This prevents RefCnt

// asserts from firing due to the order objects are deleted from the stack.

SkAutoTDelete add(decoder);

AutoDecoderCancel adc(options, decoder);

// To fix the race condition in case "requestCancelDecode"

// happens earlier than AutoDecoderCancel object is added

// to the gAutoDecoderCancelMutex linked list.

if (options != NULL && env->GetBooleanField(options,
gOptions_mCancelID)) {

return nullObjectReturn("gOptions_mCancelID");

}

SkBitmap decodingBitmap;

if (decoder->decode(stream, &decodingBitmap, prefColorType, decodeMode)

!= SkImageDecoder::kSuccess) {

return nullObjectReturn("decoder->decode returned false");

}

int scaledWidth = decodingBitmap.width();

int scaledHeight = decodingBitmap.height();

if (willScale && decodeMode != SkImageDecoder::kDecodeBounds_Mode) {

scaledWidth = int(scaledWidth * scale + 0.5f);

scaledHeight = int(scaledHeight * scale + 0.5f);

}

// update options (if any)

if (options != NULL) {

jstring mimeType = getMimeTypeString(env, decoder->getFormat());

if (env->ExceptionCheck()) {

return nullObjectReturn("OOM in getMimeTypeString()");

}

env->SetIntField(options, gOptions_widthFieldID, scaledWidth);

env->SetIntField(options, gOptions_heightFieldID, scaledHeight);

env->SetObjectField(options, gOptions_mimeFieldID, mimeType);

}

// if we're in justBounds mode, return now (skip the java bitmap)

if (decodeMode == SkImageDecoder::kDecodeBounds_Mode) {

return NULL;

}

jbyteArray ninePatchChunk = NULL;

if (peeker.mPatch != NULL) {

if (willScale) {

scaleNinePatchChunk(peeker.mPatch, scale, scaledWidth, scaledHeight);

}

size_t ninePatchArraySize = peeker.mPatch->serializedSize();

ninePatchChunk = env->NewByteArray(ninePatchArraySize);

if (ninePatchChunk == NULL) {

return nullObjectReturn("ninePatchChunk == null");

}

jbyte* array = (jbyte*) env->GetPrimitiveArrayCritical(ninePatchChunk,
NULL);

if (array == NULL) {

return nullObjectReturn("primitive array == null");

}

memcpy(array, peeker.mPatch, peeker.mPatchSize);

env->ReleasePrimitiveArrayCritical(ninePatchChunk, array, 0);

}

jobject ninePatchInsets = NULL;

if (peeker.mHasInsets) {

ninePatchInsets = env->NewObject(gInsetStruct_class,
gInsetStruct_constructorMethodID,

peeker.mOpticalInsets[0], peeker.mOpticalInsets[1], peeker.mOpticalInsets[2],
peeker.mOpticalInsets[3],

peeker.mOutlineInsets[0], peeker.mOutlineInsets[1], peeker.mOutlineInsets[2],
peeker.mOutlineInsets[3],

peeker.mOutlineRadius, peeker.mOutlineAlpha, scale);

if (ninePatchInsets == NULL) {

return nullObjectReturn("nine patch insets == null");

}

if (javaBitmap != NULL) {

env->SetObjectField(javaBitmap, gBitmap_ninePatchInsetsFieldID,
ninePatchInsets);

}

}

SkBitmap outputBitmap;

if (willScale) {

// This is weird so let me explain: we could use the scale parameter

// directly, but for historical reasons this is how the corresponding

// Dalvik code has always behaved. We simply recreate the behavior here.

// The result is slightly different from simply using scale because of

// the 0.5f rounding bias applied when computing the target image size

const float sx = scaledWidth / float(decodingBitmap.width());

const float sy = scaledHeight / float(decodingBitmap.height());

// TODO: avoid copying when scaled size equals decodingBitmap size

SkColorType colorType = colorTypeForScaledOutput(decodingBitmap.colorType());

// FIXME: If the alphaType is kUnpremul and the image has alpha, the

// colors may not be correct, since Skia does not yet support drawing

// to/from unpremultiplied bitmaps.

outputBitmap.setInfo(SkImageInfo::Make(scaledWidth, scaledHeight,

colorType, decodingBitmap.alphaType()));

if (!outputBitmap.tryAllocPixels(outputAllocator, NULL)) {

return nullObjectReturn("allocation failed for scaled bitmap");

}

// If outputBitmap's pixels are newly allocated by Java, there is no need

// to erase to 0, since the pixels were initialized to 0.

if (outputAllocator != &javaAllocator) {

outputBitmap.eraseColor(0);

}

SkPaint paint;

paint.setFilterQuality(kLow_SkFilterQuality);

SkCanvas canvas(outputBitmap);

canvas.scale(sx, sy);

canvas.drawARGB(0x00, 0x00, 0x00, 0x00);

canvas.drawBitmap(decodingBitmap, 0.0f, 0.0f, &paint);

} else {

outputBitmap.swap(decodingBitmap);

}

if (padding) {

if (peeker.mPatch != NULL) {

GraphicsJNI::set_jrect(env, padding,

peeker.mPatch->paddingLeft, peeker.mPatch->paddingTop,

peeker.mPatch->paddingRight, peeker.mPatch->paddingBottom);

} else {

GraphicsJNI::set_jrect(env, padding, -1, -1, -1, -1);

}

}

// if we get here, we're in kDecodePixels_Mode and will therefore

// already have a pixelref installed.

if (outputBitmap.pixelRef() == NULL) {

return nullObjectReturn("Got null SkPixelRef");

}

if (!isMutable && javaBitmap == NULL) {

// promise we will never change our pixels (great for sharing and pictures)

outputBitmap.setImmutable();

}

if (javaBitmap != NULL) {

bool isPremultiplied = !requireUnpremultiplied;

GraphicsJNI::reinitBitmap(env, javaBitmap, outputBitmap.info(),
isPremultiplied);

outputBitmap.notifyPixelsChanged();

// If a java bitmap was passed in for reuse, pass it back

return javaBitmap;

}

int bitmapCreateFlags = 0x0;

if (isMutable) bitmapCreateFlags |= GraphicsJNI::kBitmapCreateFlag_Mutable;

if (!requireUnpremultiplied) bitmapCreateFlags |=
GraphicsJNI::kBitmapCreateFlag_Premultiplied;

// now create the java bitmap

return GraphicsJNI::createBitmap(env, javaAllocator.getStorageObjAndReset(),

bitmapCreateFlags, ninePatchChunk, ninePatchInsets, -1);

}

doDeocode 方法是阅读的重点，这里会去读取从上层传进来的 Config
里的参数值去配置各种状态,而且还会去选择不同的分配器，去分配内存,具体代码如下

JavaPixelAllocator javaAllocator(env);

RecyclingPixelAllocator recyclingAllocator(reuseBitmap, existingBufferSize);

ScaleCheckingAllocator scaleCheckingAllocator(scale, existingBufferSize);

SkBitmap::Allocator* outputAllocator = (javaBitmap != NULL) ?

(SkBitmap::Allocator*)&recyclingAllocator :
(SkBitmap::Allocator*)&javaAllocator;

if (decodeMode != SkImageDecoder::kDecodeBounds_Mode) {

if (!willScale) {

// If the java allocator is being used to allocate the pixel memory, the
decoder

// need not write zeroes, since the memory is initialized to 0.

decoder->setSkipWritingZeroes(outputAllocator == &javaAllocator);

decoder->setAllocator(outputAllocator);

} else if (javaBitmap != NULL) {

// check for eventual scaled bounds at allocation time, so we don't decode the
bitmap

// only to find the scaled result too large to fit in the allocation

decoder->setAllocator(&scaleCheckingAllocator);

}

}

最后会调用到Graphics.cpp 里的 GraphicsJNI::createBitmap 方法去创建真正的bitmap

jobject GraphicsJNI::createBitmap(JNIEnv* env, android::Bitmap* bitmap,

int bitmapCreateFlags, jbyteArray ninePatchChunk, jobject ninePatchInsets,

int density) {

bool isMutable = bitmapCreateFlags & kBitmapCreateFlag_Mutable;

bool isPremultiplied = bitmapCreateFlags &
kBitmapCreateFlag_Premultiplied;

// The caller needs to have already set the alpha type properly, so the

// native SkBitmap stays in sync with the Java Bitmap.

assert_premultiplied(bitmap->info(), isPremultiplied);

jobject obj = env->NewObject(gBitmap_class, gBitmap_constructorMethodID,

reinterpret_cast(bitmap), bitmap->javaByteArray(),

bitmap->width(), bitmap->height(), density, isMutable, isPremultiplied,

ninePatchChunk, ninePatchInsets);

hasException(env); // For the side effect of logging.

return obj;

}

这里我们发现，最后创建是通过调用 Bitmap 的构造方法去创建一个java 的对象返回回来

* * *

项目有事找我，我先去处理一下项目的事，具体分析未完待续……..

我的博客即将同步至腾讯云+社区，邀请大家一同入驻。