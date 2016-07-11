//
//  RDShareManager.h
//  RiceDonate
//
//  Created by Tony on 15/4/1.
//  Copyright (c) 2015年 tietie tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDShareSDKDef.h"

@class TencentOAuth;

//#define kWXApiKey   @"wx4eaf3bb261561bc2"
//#define kWXApiSecret @"0090c314d0b9ba9279885810796dc7bf"
//#define kTencentKey @"100826271"
//#define kWeiboKey   @"4039355246"
//#define kRedirectURI    @"http://www.ricedonate.com"

@interface RDShareManager : NSObject

@property (nonatomic, copy) NSString *wxApiKey;
@property (nonatomic, copy) NSString *wxApiSecret;
@property (nonatomic, copy) NSString *tencentKey;
@property (nonatomic, copy) NSString *weiboKey;
@property (nonatomic, copy) NSString *redirectURI;

@property (nonatomic, strong)TencentOAuth  *tencentOAuth;
@property (nonatomic, assign)BOOL          isWechatInstall;
@property (nonatomic, assign)BOOL          isQQInstall;
@property (nonatomic, copy)  RDThirdPartyAuthSuccessBlock qqAuthBlock;
@property (nonatomic, copy)  RDWechatLoginCallback wechatAuthCallback;
@property (nonatomic, copy)  RDThirdPartyAuthSuccessBlock weiboAuthBlock;
@property (nonatomic, copy)  RDThirdPartyGetUserInfoCallback getUserInfoCallback;

+ (RDShareManager *)sharedClient;

+ (void)initializeSDKWithRedirectURI:(NSString *)redirectURI
                            wxApiKey:(NSString *)wxApiKey
                         wxApiSecret:(NSString *)wxApiSecret
                          tencentKey:(NSString *)tencentKey
                            weiboKey:(NSString *)weiboKey;

+ (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL*)url;

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

+ (BOOL)shareImage:(UIImage *)image
        thumbimage:(UIImage *)thumbimage
             title:(NSString*)title
          withType:(RDShareType)shareType
      successBlock:(RDShareSendMessageSuccessBlock)successBlock
      failureBlock:(RDShareSendMessageFailureBlock)failureBlock;

+ (BOOL)shareImage:(UIImage *)image
        thumbimage:(UIImage *)thumbimage
          withType:(RDShareType)shareType
      successBlock:(RDShareSendMessageSuccessBlock)successBlock
      failureBlock:(RDShareSendMessageFailureBlock)failureBlock;

+ (BOOL)shareImage:(UIImage *)image
          withType:(RDShareType)shareType
      successBlock:(RDShareSendMessageSuccessBlock)successBlock
      failureBlock:(RDShareSendMessageFailureBlock)failureBlock;

+ (BOOL)shareThumbimage:(UIImage *)thumbimage
                  title:(NSString *)title
                content:(NSString *)content
             webpageURL:(NSString*)webpageURL
               withType:(RDShareType)shareType
           successBlock:(RDShareSendMessageSuccessBlock)successBlock
           failureBlock:(RDShareSendMessageFailureBlock)failureBlock;
@end
