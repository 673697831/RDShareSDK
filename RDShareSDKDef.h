//
//  RDShareSDKDef.h
//  RiceDonate
//
//  Created by ozr on 16/7/8.
//  Copyright © 2016年 ricedonate. All rights reserved.
//

#ifndef RDShareSDKDef_h
#define RDShareSDKDef_h

/**
 *  分享类型
 */
typedef NS_ENUM(NSUInteger, RDShareType){
    /**
     *  微信
     */
    RDShareTypeWechatSession,
    /**
     *  朋友圈
     */
    RDShareTypeWechatTimeline,
    /**
     *  qq
     */
    RDShareTypeQQ,
    /**
     *  QQ空间
     */
    RDShareTypeQQZone,
    /**
     *  微博
     */
    RDShareTypeWeibo,
};

typedef NS_ENUM(NSUInteger, RDShareLoginType){
    RDShareLoginTypeWeixin,
    RDShareLoginTypeWeibo,
    RDShareLoginTypeQQ,
    RDShareLoginTypeNone,
};

typedef void(^RDThirdPartyAuthSuccessBlock)(NSString *, NSString *);
typedef void(^RDThirdPartyAuthFailureBlock)();
typedef void(^RDShareSendMessageSuccessBlock)();
typedef void(^RDShareSendMessageFailureBlock)(NSString *);
typedef void(^RDThirdPartyGetUserInfoCallback)(NSString *, NSString *, NSInteger);
typedef void(^RDWechatLoginCallback)(NSString *, NSString *, NSString *);

#endif /* RDShareSDKDef_h */
