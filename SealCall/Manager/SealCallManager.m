//
//  SealCallManager.m
//  SealCall
//
//  Created by LiuLinhong on 2019/08/15.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "SealCallManager.h"
#import <RongIMKit/RongIMKit.h>


@interface SealCallManager ()<RCIMUserInfoDataSource,RCIMGroupMemberDataSource,RCIMGroupInfoDataSource,RCIMGroupUserInfoDataSource>

@property (nonatomic, strong) NSLock *locker;
@property (nonatomic, strong) NSCache *sharedCache;

@end


@implementation SealCallManager

+ (instancetype)sharedManager {
    static SealCallManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[SealCallManager alloc] init];
        }
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userIDArray = @[@"SealCall_User01",
                             @"SealCall_User02",
                             @"SealCall_User03",
                             @"SealCall_User04",
                             @"SealCall_User05",
                             @"SealCall_User06",
                             @"SealCall_User07",
                             @"SealCall_User08",
                             @"SealCall_User09",
                             @"SealCall_User10",
                             @"SealCall_User11",
                             @"SealCall_User12",
                             @"SealCall_User13",
                             @"SealCall_User14",
                             @"SealCall_User15",
                             @"SealCall_User16",
                             @"SealCall_User17",
                             @"SealCall_User18",
                             @"SealCall_User19",
                             @"SealCall_User20",
                             @"SealCall_User21",
                             @"SealCall_User22",
                             @"SealCall_User23",
                             @"SealCall_User24",
                             @"SealCall_User25",
                             @"SealCall_User26",
                             @"SealCall_User27",
                             @"SealCall_User28",
                             @"SealCall_User29",
                             @"SealCall_User30",
                             @"SealCall_User31",
                             @"SealCall_User32",
                             @"SealCall_User33",
                             @"SealCall_User34",
                             @"SealCall_User35"];
    }
    return self;
}

- (void)launch {
    self.sharedCache = [[NSCache alloc]init];
    self.sharedCache.countLimit = 50;
    self.locker = [[NSLock alloc]init];
    [RCIM sharedRCIM].userInfoDataSource = self;
    [RCIM sharedRCIM].groupInfoDataSource = self;
    [RCIM sharedRCIM].groupMemberDataSource = self;
}

- (void)getAllMembersOfGroup:(NSString *)groupId result:(void (^)(NSArray<NSString *> *userIdList))resultBlock{
    resultBlock(self.userIDArray);
}

- (void)getUserInfoWithUserId:(NSString *)userId completion:(void (^)(RCUserInfo *userInfo))completion{
    completion([self getUserInfoWithUserId:userId]);
}

- (void)getUserInfoWithUserId:(NSString *)userId
   inGroup:(NSString *)groupId
                   completion:(void (^)(RCUserInfo *userInfo))completion{
    completion([self getUserInfoWithUserId:userId]);
}
- (void)getGroupInfoWithGroupId:(NSString *)groupId completion:(void (^)(RCGroup *groupInfo))completion{
    RCGroup *group = [[RCGroup alloc]initWithGroupId:groupId groupName:@"HelloTest" portraitUri:@""];
    completion(group);
}
- (RCUserInfo *)getUserInfoWithUserId:(NSString *)userId {
    if ([userId isEqualToString:[RCIMClient sharedRCIMClient].currentUserInfo.userId]) {
        [RCIMClient sharedRCIMClient].currentUserInfo.portraitUri = [[[NSBundle mainBundle] pathForResource:@"RongCloud" ofType:@"bundle"] stringByAppendingPathComponent:@"default_portrait"];
        return [RCIMClient sharedRCIMClient].currentUserInfo;
    }
    RCUserInfo *userInfo = [self.sharedCache objectForKey:userId];
    if (!userInfo) {
        NSString *imagePath = [[[NSBundle mainBundle] pathForResource:@"RongCloud" ofType:@"bundle"] stringByAppendingPathComponent:@"default_portrait_msg"];
        userInfo = [[RCUserInfo alloc] initWithUserId:userId name:[NSString stringWithFormat:@"%@",userId] portrait:imagePath];
        [self.sharedCache setObject:userInfo forKey:userId];
    }
    return userInfo;
}

- (NSString *)userID {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger selectedIndex = [userDefaults integerForKey:kSelectedUserIDIndex];
    return self.userIDArray[selectedIndex];
}

- (NSArray *)getAllUserIdArray {
    return self.userIDArray;
}

- (NSArray *)getAllOtherUserIdArray {
    NSMutableArray *userIdArray = [NSMutableArray arrayWithArray:self.userIDArray];
    [userIdArray removeObject:self.userID];
    return userIdArray;
}

@end
