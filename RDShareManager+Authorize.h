//
//  RDShareManager+Authorize.h
//  RiceDonate
//
//  Created by ozr on 16/7/8.
//  Copyright © 2016年 ricedonate. All rights reserved.
//

#import "RDShareManager.h"

@interface RDShareManager (Authorize)

+ (void)authWithWeibo:(RDThirdPartyAuthSuccessBlock)successBlock;

+ (void)authWithQQ:(RDThirdPartyAuthSuccessBlock)successBlock;

+ (void)authWithWeChat:(RDWechatLoginCallback)successBlock;

@end
