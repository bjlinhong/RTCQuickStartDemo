//
//  RCFetchTokenManager.h
//  SealRTC
//
//  Created by jfdreamyang on 2019/8/14.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

// 以下宏定义为线上环境
//#define RCIMAPPKey @"z3v5yqkbv8v30"
//#define RCIM_Navi @"nav.cn.ronghub.com"
//#define RCIM_API_SECRET @"aL1VbnQdzNII8v"
//#define RCIM_API_SERVER @"http://api-cn.ronghub.com"

// 以下宏定义为小乔环境
//#define RCIM_API_SERVER @"http://apixq.rongcloud.net"
//#define RCIMAPPKey @"e0x9wycfx7flq"
//#define RCIM_API_SECRET @"UfmrYyG1lpE"
//#define RCIM_Navi @"http://navxq.rongcloud.net"

// 以下宏定义为大乔环境
#define RCIM_API_SERVER @"http://apiqa.cn.ronghub.com"
#define RCIMAPPKey  @"c9kqb3rdkbb8j"
#define RCIM_API_SECRET    @"OYjzdrxMmUOmq"
#define RCIM_Navi @"http://navqa.cn.ronghub.com"

NS_ASSUME_NONNULL_BEGIN

typedef void(^RCFetchTokenCompletion)(BOOL isSucccess,NSString * _Nullable token);

@interface RCFetchTokenManager : NSObject

/**
 获取 IM token 管理，为避免 secret 信息泄露，推荐用户在 App Server 获取 token 而不是在客户端获取
 */
+(RCFetchTokenManager *)sharedManager;

/**
 
 设置用户所在的视频View
 @param userId userId 指定 token 对应的 userId
 @param username 用户名称
 @param portraitUri 指定用户头像
 @param completion 获取完成回调
 */
-(void)fetchTokenWithUserId:(NSString *)userId username:(NSString *)username portraitUri:(NSString *)portraitUri completion:(RCFetchTokenCompletion)completion;

@end

NS_ASSUME_NONNULL_END
