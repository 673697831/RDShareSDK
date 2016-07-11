//
//  RDShareManager+Authorize.m
//  RiceDonate
//
//  Created by ozr on 16/7/8.
//  Copyright © 2016年 ricedonate. All rights reserved.
//

#import "RDShareManager+Authorize.h"
#import "WeiboSDK.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"

@implementation RDShareManager (Authorize)

+ (void)authWithWeibo:(RDThirdPartyAuthSuccessBlock)successBlock
{
    
    [RDShareManager sharedClient].weiboAuthBlock = [successBlock copy];
    
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = [self sharedClient].redirectURI;
    request.scope = @"all";
    
    [WeiboSDK sendRequest:request];
}

+ (void)authWithQQ:(RDThirdPartyAuthSuccessBlock)successBlock
{
    [RDShareManager sharedClient].qqAuthBlock = [successBlock copy];
    
    NSArray* permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_USER_INFO,
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            kOPEN_PERMISSION_ADD_ALBUM,
                            kOPEN_PERMISSION_ADD_IDOL,
                            kOPEN_PERMISSION_ADD_ONE_BLOG,
                            kOPEN_PERMISSION_ADD_PIC_T,
                            kOPEN_PERMISSION_ADD_SHARE,
                            kOPEN_PERMISSION_ADD_TOPIC,
                            kOPEN_PERMISSION_CHECK_PAGE_FANS,
                            kOPEN_PERMISSION_DEL_IDOL,
                            kOPEN_PERMISSION_DEL_T,
                            kOPEN_PERMISSION_GET_FANSLIST,
                            kOPEN_PERMISSION_GET_IDOLLIST,
                            kOPEN_PERMISSION_GET_INFO,
                            kOPEN_PERMISSION_GET_OTHER_INFO,
                            kOPEN_PERMISSION_GET_REPOST_LIST,
                            kOPEN_PERMISSION_LIST_ALBUM,
                            kOPEN_PERMISSION_UPLOAD_PIC,
                            kOPEN_PERMISSION_GET_VIP_INFO,
                            kOPEN_PERMISSION_GET_VIP_RICH_INFO,
                            kOPEN_PERMISSION_GET_INTIMATE_FRIENDS_WEIBO,
                            kOPEN_PERMISSION_MATCH_NICK_TIPS_WEIBO,
                            nil];
    
    [[[RDShareManager sharedClient] tencentOAuth] authorize:permissions inSafari:NO];
}

+ (void)authWithWeChat:(RDWechatLoginCallback)successBlock
{
    [self sharedClient].wechatAuthCallback = successBlock;
    
    //构造SendAuthReq结构体
    SendAuthReq* req =[[SendAuthReq alloc ] init];
    req.scope = @"snsapi_userinfo" ;
    req.state = @"123";
    //第三方向微信终端发送一个SendAuthReq消息结构
    [WXApi sendReq:req];
}

@end
