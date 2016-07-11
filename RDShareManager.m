//
//  RDShareManager.m
//  RiceDonate
//
//  Created by Tony on 15/4/1.
//  Copyright (c) 2015年 tietie tech. All rights reserved.
//

#import "RDShareManager.h"
#import "RDFunction.h"
#import "RDNetworkAdapter.h"
#import "WeiboUser.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentApiInterface.h>
#import "WeiboSDK.h"

@interface RDShareManager ()<WXApiDelegate, QQApiInterfaceDelegate, TencentSessionDelegate,WeiboSDKDelegate>

@property (nonatomic, copy)RDShareSendMessageSuccessBlock sendSuccessBlock;
@property (nonatomic, copy)RDShareSendMessageFailureBlock sendFailureBlock;
@property (nonatomic, assign)RDShareLoginType shareLoginType;

@end

@implementation RDShareManager

+ (RDShareManager *)sharedClient {
    
    static RDShareManager *_sharedClient = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _sharedClient = [[RDShareManager alloc] init];
        
    });
    
    return _sharedClient;
    
}


- (instancetype)init{
    self = [super init];
    if (self) {
        _shareLoginType = RDShareLoginTypeNone;
    }
    return self;
}

+ (void)initializeSDKWithRedirectURI:(NSString *)redirectURI
                            wxApiKey:(NSString *)wxApiKey
                         wxApiSecret:(NSString *)wxApiSecret
                          tencentKey:(NSString *)tencentKey
                            weiboKey:(NSString *)weiboKey
{
    [RDShareManager sharedClient].redirectURI = redirectURI;
    [RDShareManager sharedClient].wxApiKey = wxApiKey;
    [RDShareManager sharedClient].wxApiSecret = wxApiSecret;
    [RDShareManager sharedClient].tencentKey = tencentKey;
    [RDShareManager sharedClient].weiboKey = weiboKey;
    [[RDShareManager sharedClient] innerInitialize];
}


- (void)innerInitialize{
    [WXApi registerApp:_wxApiKey];
    _tencentOAuth = [[TencentOAuth alloc] initWithAppId:_tencentKey andDelegate:self];
    _tencentOAuth.redirectURI = _redirectURI;
    [WeiboSDK enableDebugMode:YES];
    [WeiboSDK registerApp:_weiboKey];
}


+ (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL*)url{

    
    if ([TencentOAuth HandleOpenURL:url]) {
        return YES;
    }
    
    if ([QQApiInterface handleOpenURL:url delegate:[RDShareManager sharedClient]]) {
        return YES;
    }
    
    if ([WXApi handleOpenURL:url delegate:[RDShareManager sharedClient]] ) {
        return YES;
    }
    
    if ([WeiboSDK handleOpenURL:url delegate:[RDShareManager sharedClient]]) {
        return YES;
    }
    return NO;
}


+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{

    
    if ([TencentOAuth HandleOpenURL:url]) {
        return YES;
    }
    
    if ([QQApiInterface handleOpenURL:url delegate:[RDShareManager sharedClient]]) {
        return YES;
    }
    
    if ([WXApi handleOpenURL:url delegate:[RDShareManager sharedClient]] ) {
        return YES;
    }
    
    if ([WeiboSDK handleOpenURL:url delegate:[RDShareManager sharedClient]]) {
        return YES;
    }
    return NO;
}

+ (BOOL)shareImage:(UIImage *)image
        thumbimage:(UIImage *)thumbimage
             title:(NSString *)title
          withType:(RDShareType)shareType
      successBlock:(RDShareSendMessageSuccessBlock)successBlock
      failureBlock:(RDShareSendMessageFailureBlock)failureBlock
{
    [self sharedClient].sendSuccessBlock = successBlock;
    [self sharedClient].sendFailureBlock = failureBlock;
    
    NSData *thumbImageData = UIImageJPEGRepresentation(thumbimage, 0.005);
    NSData *sendImageData = UIImageJPEGRepresentation(image, 1);
    
    if (shareType == RDShareTypeWechatSession || shareType == RDShareTypeWechatTimeline) {
        if ([[RDShareManager sharedClient] isWechatInstall]) {
            WXMediaMessage *message = [WXMediaMessage message];
            message.thumbData = thumbImageData;
            
            WXImageObject *ext = [WXImageObject object];
            ext.imageData =  sendImageData;
            
            message.mediaObject = ext;
            
            SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
            req.bText = NO;
            req.message = message;
            req.scene = shareType == RDShareTypeWechatSession?WXSceneSession:WXSceneTimeline;
            
            return [WXApi sendReq:req];
        }
        return NO;
    }
    
    if (shareType == RDShareTypeQQ) {
        QQApiImageObject* img = [QQApiImageObject objectWithData:sendImageData previewImageData:thumbImageData title:title description:@""];
        SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
        
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        [[RDShareManager sharedClient] handleQQSendResult:sent];
        
    }
    
    if (shareType == RDShareTypeWeibo) {
        WBMessageObject *message = [WBMessageObject message];
        WBImageObject *image = [WBImageObject object];
        image.imageData = sendImageData;
        message.imageObject = image;
        message.text = title;
        
        WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
        authRequest.redirectURI = [self sharedClient].weiboKey;
        authRequest.scope = @"all";
        
        WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:nil];
        //        request.userInfo = @{@"ShareMessageFrom": @"SendMessageToWeiboViewController",
        //                             @"Other_Info_1": [NSNumber numberWithInt:123],
        //                             @"Other_Info_2": @[@"obj1", @"obj2"],
        //                             @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
        //        request.shouldOpenWeiboAppInstallPageIfNotInstalled = NO;
        return [WeiboSDK sendRequest:request];
    }
    
    if (shareType == RDShareTypeQQZone) {
        //
        
        QQApiURLObject *sendObjc = [QQApiURLObject objectWithURL:[NSURL URLWithString:[self sharedClient].redirectURI]
                                                           title:title
                                                     description:@""
                                                previewImageData:thumbImageData
                                               targetContentType:QQApiURLTargetTypeNews];
        
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:sendObjc];
        //将内容分享到qq
        QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
        [[RDShareManager sharedClient] handleQQSendResult:sent];
        
    }
    
    return NO;

}

+ (BOOL)shareImage:(UIImage *)image
        thumbimage:(UIImage *)thumbimage
          withType:(RDShareType)shareType
      successBlock:(RDShareSendMessageSuccessBlock)successBlock
      failureBlock:(RDShareSendMessageFailureBlock)failureBlock
{
    return [RDShareManager shareImage:image thumbimage:image title:@"分享图片" withType:shareType successBlock:successBlock failureBlock:failureBlock];
}


+ (BOOL)shareImage:(UIImage *)image
          withType:(RDShareType)shareType
      successBlock:(RDShareSendMessageSuccessBlock)successBlock
      failureBlock:(RDShareSendMessageFailureBlock)failureBlock;
{
    return [RDShareManager shareImage:image thumbimage:image withType:shareType successBlock:successBlock failureBlock:failureBlock];
}

+ (BOOL)shareThumbimage:(UIImage *)thumbimage title:(NSString *)title content:(NSString *)content webpageURL:(NSString*)webpageURL  withType:(RDShareType)shareType successBlock:(RDShareSendMessageSuccessBlock)successBlock failureBlock:(RDShareSendMessageFailureBlock)failureBlock
{
    
    [RDShareManager sharedClient].sendSuccessBlock = successBlock;
    [RDShareManager sharedClient].sendFailureBlock = failureBlock;
    
    CGFloat maxSize = [RDShareManager maxSizeWithShareType:shareType];
    
    NSData *thumbImageData = [RDFunction imageJPEGRepresentationWithImage:thumbimage size:maxSize];
    
    if (shareType == RDShareTypeWechatSession || shareType == RDShareTypeWechatTimeline) {
        if ([[RDShareManager sharedClient] isWechatInstall]) {
            
            WXMediaMessage *message = [WXMediaMessage message];
            message.title = title;
            message.description = content;
            message.thumbData = thumbImageData;
            
            WXWebpageObject *ext = [WXWebpageObject object];
            ext.webpageUrl = webpageURL;
            
            message.mediaObject = ext;
            
            SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
            req.bText = NO;
            req.message = message;
            
            req.scene = shareType == RDShareTypeWechatSession?WXSceneSession:WXSceneTimeline;
            
            return [WXApi sendReq:req];
        }
        return NO;
    }
    
    if (shareType == RDShareTypeQQ) {
        QQApiURLObject* webObject = [[QQApiURLObject alloc] initWithURL:[NSURL URLWithString:webpageURL] title:title description:content previewImageData:thumbImageData targetContentType:QQApiURLTargetTypeNews];
        SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:webObject];
        
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        [[RDShareManager sharedClient] handleQQSendResult:sent];
        
    }
    
    if (shareType == RDShareTypeWeibo) {
        WBMessageObject *message = [WBMessageObject message];
        WBImageObject *image = [WBImageObject object];
        image.imageData = UIImagePNGRepresentation(thumbimage);
        
        message.text = [NSString stringWithFormat:@"%@ %@", content, webpageURL];
        NSLog(@"%@", message.text);
        NSLog(@"%ld", (long)message.text.length);
        message.imageObject = image;
        
        WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
        authRequest.redirectURI = [self sharedClient].redirectURI;
        authRequest.scope = @"all";
        
        WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:nil];
        
        return [WeiboSDK sendRequest:request];
    }
    
    if (shareType == RDShareTypeQQZone) {
        //
        
        QQApiURLObject* webObject = [[QQApiURLObject alloc] initWithURL:[NSURL URLWithString:webpageURL] title:title description:content previewImageData:thumbImageData targetContentType:QQApiURLTargetTypeNews];
        SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:webObject];
        //将内容分享到qq
        QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
        [[RDShareManager sharedClient] handleQQSendResult:sent];
        
    }
    
    return NO;
}

/*! @brief 收到一个来自微信的请求，第三方应用程序处理完后调用sendResp向微信发送结果
 *
 * 收到一个来自微信的请求，异步处理完成后必须调用sendResp发送处理结果给微信。
 * 可能收到的请求有GetMessageFromWXReq、ShowMessageFromWXReq等。
 * @param req 具体请求内容，是自动释放的
 */
- (void) onReq:(id)req{

    if ([req isKindOfClass:[BaseReq class]]) {
       __unused BaseReq *request = (BaseReq *)req;
    }
    
    if ([req isKindOfClass:[QQBaseReq class]]) {
        __unused QQBaseReq *request = (QQBaseReq *)req;
    }
}

- (void)getUserInfoResponse:(APIResponse*) response{
    if (self.getUserInfoCallback) {
        NSString *avatarUrl100 = response.jsonResponse[@"figureurl_qq_2"];
        NSString *avatarUrl40 = response.jsonResponse[@"figureurl_qq_1"];
        NSString *nickname = response.jsonResponse[@"nickname"];
        NSInteger sex = response.jsonResponse[@"gender"] && [@"男" isEqualToString:response.jsonResponse[@"gender"]]?1:2;
        if (avatarUrl100 && avatarUrl100.length > 0) {
            self.getUserInfoCallback(nickname, avatarUrl100, sex);
        }else if (avatarUrl40 && avatarUrl40.length > 0){
            self.getUserInfoCallback(nickname, avatarUrl40, sex);
        }
    }
    self.getUserInfoCallback = nil;
}



/*! @brief 发送一个sendReq后，收到微信的回应
 *
 * 收到一个来自微信的处理结果。调用一次sendReq后会收到onResp。
 * 可能收到的处理结果有SendMessageToWXResp、SendAuthResp等。
 * @param resp具体的回应内容，是自动释放的
 */
- (void) onResp:(id)resp{
    
    if ([resp isKindOfClass:[SendMessageToQQResp class]]) {
        SendMessageToQQResp *sendMessageResp = (SendMessageToQQResp *)resp;
        if (sendMessageResp.type == ESENDMESSAGETOQQRESPTYPE) {
            if ([sendMessageResp.result isEqualToString:@"0"]) {
                if (self.sendSuccessBlock) {
                    self.sendSuccessBlock();
                }
            }else
            {
                if (self.sendFailureBlock) {
                    self.sendFailureBlock(sendMessageResp.result);
                }
            }
        }

        self.sendSuccessBlock = nil;
        self.sendFailureBlock = nil;
        return;
    }
    
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        SendMessageToWXResp *sendMessageResp = (SendMessageToWXResp *)resp;
        if (sendMessageResp.type == 0) {
            if (sendMessageResp.errCode == 0) {
                if (self.sendSuccessBlock) {
                    self.sendSuccessBlock();
                }
            }else
            {
                if (self.sendFailureBlock) {
                    self.sendFailureBlock(@(sendMessageResp.errCode).stringValue);
                }
            }
        }
        
        self.sendSuccessBlock = nil;
        self.sendFailureBlock = nil;
        return;
    }
    
    
    if ([resp isKindOfClass:[BaseResp class]]) {
        BaseResp *response = (BaseResp *)resp;
        if ([response isKindOfClass:[SendAuthResp class]]) {
            [self handleWechartLogin:(SendAuthResp *)response];
        }
        return;
    }
    
    if ([resp isKindOfClass:[QQBaseResp class]]) {
        __unused QQBaseResp *response = (QQBaseResp *)resp;
    }
}

- (void)handleWechartLogin:(SendAuthResp *)wechatResp{
    
    if (wechatResp.errCode != 0) {
        if (wechatResp.errCode == -2) {
            //用户取消
        }
        if (wechatResp.errCode == -4) {
            //用户拒绝授权
        }
    }else
    {
        if (self.wechatAuthCallback) {
            self.wechatAuthCallback(self.wxApiKey, self.wxApiSecret, wechatResp.code);
        }
        self.wechatAuthCallback = nil;
    }

}

/**
 收到一个来自微博客户端程序的请求
 
 收到微博的请求后，第三方应用应该按照请求类型进行处理，处理完后必须通过 [WeiboSDK sendResponse:] 将结果回传给微博
 @param request 具体的请求对象
 */
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request{

}

/**
 收到一个来自微博客户端程序的响应
 
 收到微博的响应后，第三方应用可以通过响应类型、响应的数据和 WBBaseResponse.userInfo 中的数据完成自己的功能
 @param response 具体的响应对象
 */
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response{
    
    if ([response isKindOfClass:[WBSendMessageToWeiboResponse class]]) {
        
        WBSendMessageToWeiboResponse *sendMessageResponse = (WBSendMessageToWeiboResponse *)response;
        
        if (sendMessageResponse.statusCode == WeiboSDKResponseStatusCodeSuccess) {
            if (self.sendSuccessBlock) {
                self.sendSuccessBlock();
            }
        }else
        {
            if (self.sendFailureBlock) {
                self.sendFailureBlock(@(sendMessageResponse.statusCode).stringValue);
            }
        }

        self.sendSuccessBlock = nil;
        self.sendFailureBlock = nil;
        return;
    }else if([response isKindOfClass:[WBAuthorizeResponse class]]){
        WBAuthorizeResponse *authorizeResponse = (WBAuthorizeResponse *)response;
        if (self.weiboAuthBlock && authorizeResponse.statusCode == WeiboSDKResponseStatusCodeSuccess) {
            self.weiboAuthBlock(authorizeResponse.userID, authorizeResponse.accessToken);
        }
        self.weiboAuthBlock = nil;
    }

}



#pragma mark - Tencent 登录
/**
 *  <#Description#>
 *
 *  @return <#return value description#>
 */

/**
 处理QQ在线状态的回调
 */
- (void)isOnlineResponse:(NSDictionary *)response{

}


/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin{
    if (self.qqAuthBlock) {
        self.qqAuthBlock(self.tencentOAuth.openId, self.tencentOAuth.accessToken);
    }
    self.qqAuthBlock = nil;
}

/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled{
    
    _shareLoginType = RDShareLoginTypeNone;
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork{
    
    _shareLoginType = RDShareLoginTypeNone;
}


- (BOOL)isWechatInstall{
//    if (![WXApi isWXAppInstalled]) {
//        UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"错误" message:@"未安装微信" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
//        [msgbox show];
//        return NO;
//    }
//    return YES;
    return [WXApi isWXAppInstalled];
}

- (BOOL)isQQInstall
{
    return [TencentOAuth iphoneQQInstalled];
}

#pragma mark - QQ Error Code

- (BOOL)handleQQSendResult:(QQApiSendResultCode)sendResult
{
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"错误" message:@"App未注册" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"错误" message:@"发送参数错误" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIQQNOTINSTALLED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"错误" message:@"未安装手Q" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"错误" message:@"API接口不支持" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPISENDFAILD:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"错误" message:@"发送失败" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        default:
        {
            return YES;
            break;
        }
    }
    return NO;
}

#pragma mark - 私有定义

+ (CGFloat)maxSizeWithShareType:(RDShareType)shareType
{
    if (shareType == RDShareTypeWeibo) {
        return 32*1024;
    }
    
    if (shareType == RDShareTypeWechatSession || shareType == RDShareTypeWechatTimeline) {
        return 32*1024;
    }
    
    if (shareType == RDShareTypeQQZone || shareType == RDShareTypeQQ) {
        return 1024 * 1024;
    }
    
    return MAXFLOAT;
}

@end
