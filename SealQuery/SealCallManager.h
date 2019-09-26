//
//  SealCallManager.h
//  SealCall
//
//  Created by LiuLinhong on 2019/08/15.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

#define kSelectedUserIDIndex @"selectedUserIDIndex"

NS_ASSUME_NONNULL_BEGIN

@interface SealCallManager : NSObject 

@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSArray *userIDArray;
@property (nonatomic, strong)NSString *roomId;

+ (instancetype)sharedManager;

- (void)launch;

- (NSArray *)getAllUserIdArray;

- (NSArray *)getAllOtherUserIdArray;

-(void)setIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
