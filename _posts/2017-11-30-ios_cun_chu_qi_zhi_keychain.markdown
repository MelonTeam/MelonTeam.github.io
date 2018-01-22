---
layout: post
title: "iOS存储器之Keychain"
date: 2017-11-30 16:40:00 +0800
categories: 未分类
author: maxsezhang
tags: keychianios
---

* content
{:toc}



Keychain[](/blog/archives)

## 什么是Keychain?
<!--more-->

根据苹果的介绍，iOS设备中的Keychain是一个安全的存储容器，可以用来为不同应用保存敏感信息比如用户名，密码，网络密码，认证令牌
。苹果自己用keychain来保存Wi-Fi网络密码，VPN凭证等等。它是一个在所有app之外的sqlite数据库。

如果我们手动把自己的私密信息加密，然后通过写文件保存在本地，再从本地取出不仅麻烦，而且私密信息也会随着App的删除而丢失。iOS的Keychain能完美的解决这些问题。并且从iOS
3.0开始，Keychain还支持跨程序分享。这样就极大的方便了用户。省去了很多要记忆密码的烦恼。

## Structure of a Keychain

Keychain内部可以保存很多的信息。每条信息作为一个单独的keychain item，keychain item一般为一个字典，每条keychain
item包含一条data和很多attributes。举个例子，一个用户账户就是一条item，用户名可以作为一个attribute , 密码就是data。
keychain虽然是可以保存15000条item,每条50个attributes，但是苹果工程师建议最好别放那么多，存几千条密码，几千字节没什么问题。

如果把keychain item的类型指定为需要保护的类型比如password或者private
key，item的data会被加密并且保护起来，如果把类型指定为不需要保护的类型，比如certificates，item的data就不会被加密。

item可以指定为以下几种类型：

  * extern CFTypeRef kSecClassGenericPassword
  * extern CFTypeRef kSecClassInternetPassword
  * extern CFTypeRef kSecClassCertificate
  * extern CFTypeRef kSecClassKey
  * extern CFTypeRef kSecClassIdentity **OSX_AVAILABLE_STARTING(**MAC_10_7, __IPHONE_2_0);

## Keychain的用法

首先导入Security.framework 。

Keychain的API提供以下几个函数来操作Keychain

  * SecItemAdd 添加一个keychain item
  * SecItemUpdate 修改一个keychain item
  * SecItemCopyMatching 搜索一个keychain item
  * SecItemDelete 删除一个keychain item

也可以参考以下这段简单的代码来了解下Keychain API的用法。

    
    
    
    - (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
        NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
        //指定item的类型为GenericPassword
        [searchDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
        
        //类型为GenericPassword的信息必须提供以下两条属性作为unique identifier
        [searchDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount]；
        [searchDictionary setObject:encodedIdentifier forKey:(id)kSecAttrService]；
        
        return searchDictionary;
    }
    - (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
        NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
        
        //在搜索keychain item的时候必须提供下面的两条用于搜索的属性
        //只返回搜索到的第一条item
        [searchDictionary setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
        //返回item的kSecValueData
        [searchDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
        
        NSData *result = nil;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)searchDictionary,
                                              (CFTypeRef *)&result);
        [searchDictionary release];
        return result;
    }
    - (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
        NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
        
        NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
        [dictionary setObject:passwordData forKey:(id)kSecValueData];
        
        OSStatus status = SecItemAdd((CFDictionaryRef)dictionary, NULL);
        [dictionary release];
        if (status == errSecSuccess) {
            return YES;
        }
        return NO;
    }
    - (BOOL)updateKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
        NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
        
        NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
        NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
        [updateDictionary setObject:passwordData forKey:(id)kSecValueData];
        
        OSStatus status = SecItemUpdate((CFDictionaryRef)searchDictionary,
                                        (CFDictionaryRef)updateDictionary);
        
        [searchDictionary release];
        [updateDictionary release];
        
        if (status == errSecSuccess) {
            return YES;
        }
        return NO;
    }
    - (void)deleteKeychainValue:(NSString *)identifier {
        NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
        SecItemDelete((CFDictionaryRef)searchDictionary);
        [searchDictionary release];
    }
    

Keychain API的用法稍微有点复杂。不过Apple自己也提供了一个封装了Keychain API的类： KeychainItemWrapper
<https://developer.apple.com/library/ios/samplecode/GenericKeychain/Introduction/Intro.html>
虽然这个类封装了Keychain的API，但是不仅代码写的很不容易理解，而且里面也有不少的Bug。所以还是不建议使用。
目前发现这个类的1.2版存在的Bug为：

  1. 如果需要某个keychain item支持iCloud备份，添加kSecAttrSynchronizable属性之后，它并没有在第二次更新item或者搜索item的时候加上这一条，所以导致item已经存在但是它却获取不到。
  2. 类型为GenericPassword的item必须使用kSecAttrAccount和kSecAttrService作为主要的key，但是这个类仅仅以kSecAttrGeneric作主要的key。所以在用它添加item的时候容易出现重复添加的错误。

每种类型的Keychain item都有不同的键作为主要的Key也就是唯一标示符用于搜索，更新和删除，Keychain内部不允许添加重复的Item。

keychain item的类型，也就是kSecClass键的值 | 主要的Key  
---|---  
kSecClassGenericPassword | kSecAttrAccount,kSecAttrService  
kSecClassInternetPassword | kSecAttrAccount, kSecAttrSecurityDomain,
kSecAttrServer, kSecAttrProtocol,kSecAttrAuthenticationType,
kSecAttrPortkSecAttrPath  
kSecClassCertificate | kSecAttrCertificateType,
kSecAttrIssuerkSecAttrSerialNumber  
kSecClassKey | kSecAttrApplicationLabel, kSecAttrApplicationTag,
kSecAttrKeyType,kSecAttrKeySizeInBits, kSecAttrEffectiveKeySize  
kSecClassIdentity | kSecClassKey,kSecClassCertificate  
  
## Keychain的备份

  1. iOS的Keychain由系统管理并且进行加密，Keychain内的信息会随着iPhone的数据一起备份。但是kSecAttrAccessible 属性被设置为后缀是ThisDeviceOnly的数据会被以硬件相关的密钥(key)加密。并且不会随着备份移动至其他设备。

kSecAttrAccessiblein变量用来指定这条信息的保护程度。我们需要对这个选项特别注意，并且使用最严格的选项。这个键（key）可以设置6种值。

    * CFTypeRef kSecAttrAccessibleWhenUnlocked;
    * CFTypeRef kSecAttrAccessibleAfterFirstUnlock;
    * CFTypeRef kSecAttrAccessibleAlways;
    * CFTypeRef kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    * CFTypeRef kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    * CFTypeRef kSecAttrAccessibleAlwaysThisDeviceOnly;

从iOS5.0开始kSecAttrAccessible默认为kSecAttrAccessibleWhenUnlocked。

  2. Keychain从iOS7.0开始也支持iCloud备份。把kSecAttrSynchronizable属性设置为@YES，这样后Keychain就能被iCloud备份并且跨设备分享。

不过在添加kSecAttrSynchronizable属性后，这条属性会被作为每条Keychain
Item的主要的Key之一，所以在搜索，更新，删除的时候如果查询字典内没有这一条属性，item就匹配不到。

## Keychain Access Group

Keychain通过provisioning profile来区分不同的应用，provisioning文件内含有应用的bundle id和添加的access
groups。不同的应用是完全无法访问其他应用保存在Keychain的信息，除非指定了同样的access
group。指定了同样的group名称后，不同的应用间就可以分享保存在Keychain内的信息。

Keychain Access Group的使用方法：

  1. 首先要在Capabilities下打开工程的Keychain Sharing按钮。然后需要分享Keychain的不同应用添 加相同的Group名称。Xcode6以后Group可以随便命名，不需要加AppIdentifierPrefix前缀，并且Xcode会在以entitlements结尾的文件内自动添加所有Group名称，然后在每一个Group前自动加上$(AppIdentifierPrefix)前缀。虽然文档内提到还需要添加一个包含group的.plist文件，其实它和.entitlements文件是同样的作用，所以不需要重复添加。 但是每个不同的应用第一条Group最好以自己的bundleID命名，因为如果entitlements文件内已经有Keychain Access Groups数组后item的Group属性默认就为数组内的第一条Grop。

  2. 需要支持跨设备分享的Keychain item添加一条AccessGroup属性,不过代码里Group名称一定要加上AppIdentifierPrefix前缀。 `[searchDictionary setObject:@“AppIdentifierPrefix.UC.testWriteKeychainSuit” forKey:(id)kSecAttrAccessGroup];` 如果要在app内部存私有的信息，group置为自己的bundleID即可，如果entitlements文件内没有指定Keychain Access Groups数组。那group也可以置为nil，这样默认也会以自己的bundleID作为Group。

## Keychain的安全性

Keychain内部的数据会自动加密。如果设备没有越狱并且不暴力破解，keychain确实很安全。但是越狱后的设备，keychain就很危险了。

通过上面的一些信息我们已经知道访问keychain里面的数据需要和app一样的证书或者获得access
group的名称。设备越狱后相当于对苹果做签名检查的地方打了个补丁，伪造一个证书的app也能正常使用，并且加上Keychain
Dumper这些工具获取Keychain内的信息会非常容易。

## 使用keychain需要注意的问题

  1. 当我们不支持Keychain Access Group，并且没有entitlement文件时，keychain默认以bundle id为group。如果我们在版本更新的时候改变了bundle id，那么新版本就访问不了旧版本的keychain信息了。解决办法是从一开始我们就打开KeychainSharing，添加Keychain Access Group，并且指定每条keychain Item的group，私有的信息就指定app的bundle id为它的group。
  2. 代码内Access group名称一定要有AppIdentifierPrefix前缀。
  3. Keychain是基于数据库存储，不允许添加重复的条目。所以每条item都必须指定对应的唯一标识符也就是那些主要的key，如果Key指定不正确，可能会出现添加后查找不到的问题。
  4. kSecAttrSynchronizable也会作为主要的key之一。它的value值默认为No，如果之前添加的item此条属性为YES，在搜索，更新，删除的时候必须添加此条属性才能查找到之前添加的item。
  5. Kechain item字典内添加自定义key时会出现参数不合法的错误。

## 总结

keychain很强大，是一个值得利用的工具，我们可以在保存密码或者证书的时候使用keychain，并且支持不同应用分享Keychain内的信息，或者支持iCloud备份跨设备分享，但是越狱版应用不建议使用。

