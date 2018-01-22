---
layout: post
title: "大隐隐于市——零宽字符介绍"
date: 2017-10-31 23:59:00 +0800
categories: android
author: pelli
tags: Android 零宽字符
---

* content
{:toc}



有一类字符，能够合法地出现在字符串里面，但是它的显示宽度为0，不能被显示或打印出来（即使用的是等宽字体），这就是零宽字符。零宽字符被设计出来是用于排版，但它不会被看见的特点，也能做一些开脑洞的事情。

## 本职工作——排版
<!--more-->

估计每个开发都曾经被测试同学提过长单词不换行的bug，面对滚键盘滚出来的输入黯然神伤。  

![](/image/da_yin_yin_yu_shi__ling_kuan_zi_fu_jie_shao/c50ca0193b27a35e621cee73cac60000808711a342ca6bdef541a977b607a4fb)

为了解决这个头疼的问题，常见的做法是实现自定义的TextView，在渲染的时候逐字计算宽度，在适当的地方增加换行。

    
    
    private String autoSplitText(final TextView tv) {
        final String rawText = tv.getText().toString(); //原始文本
        final Paint tvPaint = tv.getPaint(); //paint，包含字体等信息
        final float tvWidth = tv.getWidth() - tv.getPaddingLeft() - tv.getPaddingRight(); //控件可用宽度
    
        //将原始文本按行拆分
        String [] rawTextLines = rawText.replaceAll("\r", "").split("\n");
        StringBuilder sbNewText = new StringBuilder();
        for (String rawTextLine : rawTextLines) {
            if (tvPaint.measureText(rawTextLine) <= tvWidth) {
                //如果整行宽度在控件可用宽度之内，就不处理了
                sbNewText.append(rawTextLine);
            } else {
                //如果整行宽度超过控件可用宽度，则按字符测量，在超过可用宽度的前一个字符处手动换行
                float lineWidth = 0;
                for (int cnt = 0; cnt != rawTextLine.length(); ++cnt) {
                    char ch = rawTextLine.charAt(cnt);
                    lineWidth += tvPaint.measureText(String.valueOf(ch));
                    if (lineWidth <= tvWidth) {
                        sbNewText.append(ch);
                    } else {
                        sbNewText.append("\n");
                        lineWidth = 0;
                        --cnt;
                    }
                }
            }
            sbNewText.append("\n");
        }
        return sbNewText.toString();
    }
    

代码来源：[cnblogs]( "cnblogs" )

然而有时候我们不方便使用自定义的TextView，譬如在notification里面，自定义View会改变系统样式，使我们的notification很不协调。这时候就可以使用零宽字符来实现在超长单词中间换行。

> Unicode Character ‘ZERO WIDTH SPACE’ (U+200B)  
> commonly abbreviated ZWSP  
> this character is intended for invisible word separation and for line break
control; it has no width, but its presence between two characters does not
prevent increased letter spacing in justification

Android系统从4.3开始支持\u200b的换行。  

![](/image/da_yin_yin_yu_shi__ling_kuan_zi_fu_jie_shao/9b305f05d704292d5437e23f56015d97178c360c72a185d431cfdc389fa54ee6)

  

![](/image/da_yin_yin_yu_shi__ling_kuan_zi_fu_jie_shao/454ce13af3793a2b4e5c2158b17cd5d5d5e315a8e6fe549e1b8ab38afd7acd28)

  
代码来源：[grepcode](http://www.grepcode.com/file/repository.grepcode.com/java/ext/com.google.android/android/4.3_r1/android/text/StaticLayout.java#StaticLayout
"grepcode" )

只要在超长单词中适当的地方加入\u200b，就能实现换行了。

    
    
    /**
     * Created by pelli on 2016/4/26.
     */
    public class LongWordBreaker {
        private static final int MAX_ALLOW_LENGTH = 6;
        private static final String SPLITER = "\u200b";
        public static String breakLongWord(String text) {
            if (text == null) {
                return null;
            }
            int len = text.length();
            if (len > MAX_ALLOW_LENGTH) {
                StringBuilder out = null;
                int enqueued = 0;
                int confirmed = 0;
                int cursor = 0;
                int lastCursor = 0;
                boolean lastIsCJK = false;
                while (cursor <= len) {
                    boolean isCJK;
                    int next = cursor + 1;
                    int newConfirmed = confirmed;
                    if (cursor < len) {
                        // 检查
                        char c = text.charAt(cursor);
                        if (c == ' ' || c == '\n' || c == '\r' || c == '\u200b') { // 一只野生的可换行字符
                            newConfirmed = next;
                            isCJK = false;
                        } else {
                            if (Character.isHighSurrogate(c) && cursor < len - 1) { // 处理utf16字符
                                int codePoint = Character.toCodePoint(c, text.charAt(next));
                                isCJK = isCJK(codePoint);
                                ++next;
                            } else {
                                isCJK = isCJK(c);
                            }
                            if (confirmed < cursor && lastIsCJK && isCJK) { // 上一个字中文并且现在还是中文,那么它们中间就可以换行了
                                newConfirmed = cursor;
                            }
                        }
                        lastIsCJK = isCJK;
                    } else {
                        newConfirmed = len;
                    }
                    // 切割
                    if (newConfirmed != confirmed) {
                        if (cursor - confirmed > MAX_ALLOW_LENGTH) { // 发现一个长长的单词, 我们把它切开吧
                            if (out == null) {
                                out = new StringBuilder();
                            }
                            // enqueued必小于等于confirmed, 这里多割一个字, 可以减少分段数, question:需要判断utf16吗, 为什么可以这样做?
                            int charSize = Character.isHighSurrogate(text.charAt(confirmed)) ? 2 : 1;
                            out.append(text.substring(enqueued, confirmed + charSize));
                            split(text, confirmed + charSize, lastCursor, out);
                            enqueued = lastCursor;
                        }
                        confirmed = newConfirmed;
                    }
                    lastCursor = cursor;
                    cursor = next;
                }
                if (out != null) {
                    out.append(text.substring(enqueued));
                    return out.toString();
                }
            }
            return text;
        }
    
        private static boolean isCJK(int c) {
            // https://en.wikipedia.org/wiki/CJK_Unified_Ideographs
            return 0x3300 <= c && /*c <= 0x33ff || // CJK Compatibility
                    0x3400 <= c &&*/ c <= 0x4dbf || // CJK Unified Ideographs Extension A
                    0x4e00 <= c && c <= 0x9fff || // CJK Unified Ideographs
                    0xf900 <= c && c <= 0xfaff || // CJK Compatibility Ideographs
                    0xfe30 <= c && c <= 0xfe4f || // CJK Compatibility Forms
                    0x20000 <= c && c <= 0x2a6df || // CJK Unified Ideographs Extension B
                    0x2a700 <= c && /*c <= 0x2b73f || // CJK Unified Ideographs Extension C
                    0x2b740 <= c && c <= 0x2b81f || // CJK Unified Ideographs Extension D
                    0x2b820 <= c &&*/ c <= 0x2ceaf || // CJK Unified Ideographs Extension E
                    0x2f800 <= c && c <= 0x2fa1f; // CJK Compatibility Ideographs Supplement
        }
    
        private static void split(String source, int start, int end, StringBuilder dst) {
            dst.append(SPLITER);
            for (int i = start; i < end; ++i) {
                char c = source.charAt(i);
                dst.append(c);
                if (Character.isHighSurrogate(c) && i < end - 1) {
                    ++i;
                    dst.append(source.charAt(i));
                }
                dst.append(SPLITER);
            }
        }
    }
    

![](/image/da_yin_yin_yu_shi__ling_kuan_zi_fu_jie_shao/e3031b0765e5302fdde5d3faf6645b64d43a579546e73d9523396a9e2763215a)

## 绕过敏感词检查

为了绕过敏感词检查，很多攻击者会在文本中间插入特殊符号和emoji表情，或者使用错别字。但如果把五花八门的特殊符号和emoji表情换成不可见的零宽字符，不知高到哪里去了。  

![](/image/da_yin_yin_yu_shi__ling_kuan_zi_fu_jie_shao/b90311ccbcc5b1a2e877022bac7d05a6c8d8d8db094bc10399524600986e995b)

## 用来写不可维护的代码

可以用在代码混淆里，当然不要作死地真的写到源码里。

    
    
    public class Main {
        public static void main(String[] args) {
            String test = "a";
            String result;
            if ("​a".equals(test)) {
                result = "​​​Yes​No".substring(3, 6);
            } else {
                result = "​​​​True​False".substring(4, 9);
            }
            System.out.println(result);
        }
    }
    

![](/image/da_yin_yin_yu_shi__ling_kuan_zi_fu_jie_shao/0dbe75de6db4fab656494a1c88f8074c7f757d01beb0e267ac5d3e79de56e8c8)

## 用来隐写签名

很多提供内容的平台都会在自己的图片中加入不可见的信号，用来保护版权。但在文本里面，就没那么容易了，ctrl+c再ctrl+v就会让隐写的信号暴露无遗。而用不同的零宽字符组合出来的信号，就没那么容易被发现了。

