//
//  SealQueryViewController.m
//  RCSignalingQueryDemo
//
//  Created by jfdreamyang on 2019/9/4.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "SealQueryViewController.h"
#import <RongSignalingLib/RongSignalingLib.h>
#import <RongIMLib/RongIMLib.h>
#import "RCFetchTokenManager.h"
#import "SealCallManager.h"
#import "SealMemberInfoView.h"
#import "SealRoomInfoView.h"
#import "UIView+Toast.h"

@interface SealQueryViewController ()<RCSignalingClientDelegate,RCConnectionStatusChangeDelegate>
{
    BOOL _open;
    BOOL _isAdd;
}
@property (nonatomic,strong)SealMemberInfoView *memberInfoView;
@property (nonatomic,strong)SealRoomInfoView *roomInfoView;

@property (nonatomic,strong)NSMutableDictionary <NSString *,NSString *>*roomDataSource;
@property (nonatomic,strong)NSMutableDictionary <NSString *,NSDictionary *>*membersDataSource;

@end

@implementation SealQueryViewController
- (IBAction)addToBlack:(id)sender {
    
    _isAdd = !_isAdd;
    if (_isAdd) {
        [[RCIMClient sharedRCIMClient] addToBlacklist:@"SealCall_User03" success:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view makeToast:@"拉黑成功"];
            });
            
            NSLog(@"addToBlacklist success");
        } error:^(RCErrorCode status) {
            NSLog(@"addToBlacklist error");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view makeToast:@"拉黑失败"];
            });
        }];
    }
    else{
        [[RCIMClient sharedRCIMClient] removeFromBlacklist:@"SealCall_User03" success:^{
            NSLog(@"removeFromBlacklist success");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view makeToast:@"移除拉黑成功"];
            });
            
        } error:^(RCErrorCode status) {
            NSLog(@"removeFromBlacklist error");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view makeToast:@"移除拉黑失败"];
            });
        }];
    }
}

-(void)didReceiveChannelAttributeChanged:(RCSignalingChannelAttributeChangedNotification *)notification{
    NSArray *allKeys = notification.changedList;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.type == RCOperationTypeAdd) {
            [allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                self.roomDataSource[obj] = [RCSignalingClient sharedSignalingClient].channelInfo.attribute[obj];
                
            }];
            [self.roomInfoView reloadData:self.roomDataSource];
        }
        else if (notification.type == RCOperationTypeDelete){
            [allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self.roomDataSource removeObjectForKey:obj];
            }];
            [self.roomInfoView reloadData:self.roomDataSource];
        }
    });
}
- (IBAction)channelMessageButton:(id)sender {
    RCSignalingInviteMessage *message = [RCSignalingInviteMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"HelloCCC";
    
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        NSLog(@"===============%ld",desc);
        
    }];
}

-(void)didReceiveMemberAttributeChanged:(RCSignalingMemberAttributeChangedNotification *)notification{
    
    NSString *memberId = notification.memberId;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.type == RCOperationTypeAdd) {
            NSMutableDictionary *kvs = [self.membersDataSource[memberId] mutableCopy];
            if (!kvs) {
                kvs = [@{@"userId":memberId} mutableCopy];
            }
            for (RCSignalingChannelMember *member in [RCSignalingClient sharedSignalingClient].channelInfo.members) {
                if ([member.memberId isEqualToString:memberId]) {
                    [notification.changedList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        kvs[obj] = member.attribute[obj];
                    }];
                    self.membersDataSource[memberId] = kvs;
                    break;
                }
            }
        }
        else{
            NSMutableDictionary *kvs = [self.membersDataSource[memberId] mutableCopy];
            if (!kvs) {
                kvs = [@{@"userId":memberId} mutableCopy];
            }
            [notification.changedList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [kvs removeObjectForKey:obj];
            }];
            self.membersDataSource[memberId] = kvs;
        }
        [self.memberInfoView reloadData:self.membersDataSource];
    });
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self.view insertSubview:self.memberInfoView atIndex:0];
    [self.view insertSubview:self.roomInfoView atIndex:0];
    self.roomDataSource = [NSMutableDictionary new];
    self.membersDataSource = [NSMutableDictionary new];
    _open = YES;
    [[RCSignalingClient sharedSignalingClient] addEventObserver:self];
    
    [[RCIMClient sharedRCIMClient] setRCConnectionStatusChangeDelegate:self];
    NSLog(@"==========>%@",[SealCallManager sharedManager].userID);
    NSString *defaultToken = [[NSUserDefaults standardUserDefaults] objectForKey:[SealCallManager sharedManager].userID];
    
    if (!defaultToken) {
        [[RCFetchTokenManager sharedManager] fetchTokenWithUserId:[SealCallManager sharedManager].userID username:@"" portraitUri:@"" completion:^(BOOL isSucccess, NSString * _Nullable token) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (token) {
                    [[NSUserDefaults standardUserDefaults] setObject:token forKey:[SealCallManager sharedManager].userID];
                    [[RCIMClient sharedRCIMClient] connectWithToken:token success:^(NSString *userId) {
                        [self connected:userId];
                    } error:^(RCConnectErrorCode status) {
                        
                    } tokenIncorrect:^{
                        [self disconnected];
                    }];
                }
                else{
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            });
            
        }];
    }
    else{
        [[RCIMClient sharedRCIMClient] connectWithToken:defaultToken success:^(NSString *userId) {
            [self connected:userId];
        } error:^(RCConnectErrorCode status) {
            
        } tokenIncorrect:^{
//            [self disconnected];
        }];
    }
}
- (void)onConnectionStatusChanged:(RCConnectionStatus)status{
    if (status == ConnectionStatus_Connected) {
        [self connected:[SealCallManager sharedManager].userID];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([SealCallManager sharedManager].roomId.length <= 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
}

- (IBAction)messageTestAction:(id)sender {
    RCSignalingInviteMessage *message = [RCSignalingInviteMessage message];
    message.channelId = @"HelloCCC";
    message.signalingContent = @"HelloCCC";
    [[RCSignalingClient sharedSignalingClient] sendSignalingMessage:message userIdList:@[@"SealCall_User01",@"SealCall_User02"] completion:^(RCSignalingErrorCode desc) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"消息发送成功"];
            }
            else if (desc == RC_MSG_RESPONSE_TIMEOUT){
                [self.view makeToast:@"消息发送超时"];
            }
            else{
                [self.view makeToast:@"消息发送失败"];
            }
        });
        NSLog(@"sealquery=>message test result:%ld",desc);
    }];
}
- (IBAction)openOrClose:(UIButton *)sender {
    _open = !_open;
    if (_open) {
        [sender setTitle:@"黑名单已打开" forState:UIControlStateNormal];
    }
    else{
        [sender setTitle:@"黑名单已关闭" forState:UIControlStateNormal];
    }
}
-(void)disconnected{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)createRoom:(id)sender {
    
    
}
- (IBAction)joinRoom:(id)sender {
    
    [[RCSignalingClient sharedSignalingClient] joinChannel:[SealCallManager sharedManager].roomId option:RCSignalingJoinChannelOptionDefault completion:^(RCSignalingErrorCode desc) {
        NSLog(@"sealquery=>join channel code:%ld",desc);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                self.roomDataSource[@"room"] = [SealCallManager sharedManager].roomId;
                [self.roomInfoView reloadData:self.roomDataSource];
                [self.view makeToast:@"加入房间成功"];
                
                for (RCSignalingChannelMember *member in [RCSignalingClient sharedSignalingClient].channelInfo.members) {
                    NSDictionary *kvs = @{@"userId":member.memberId};
                    self.membersDataSource[member.memberId] = kvs;
                }
                [self.memberInfoView reloadData:self.membersDataSource];
                
                [self getRoomAttribute:nil];
                [self getUserAttribute:nil];
                
            }
            else{
                [self.view makeToast:[NSString stringWithFormat:@"加入房间失败 code:%ld",desc]];
            }
        });
    }];
}

- (IBAction)setRoomAttribute:(id)sender {
    
    NSDictionary *attributes = @{[NSString stringWithFormat:@"random%ld",(long)(arc4random()%1000)]:@"HelloRoom"};
    
    [[RCSignalingClient sharedSignalingClient] setChannelAttributes:attributes notifyOthers:YES completion:^(RCSignalingErrorCode code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == RCSignalingErrorCodeSuccess) {
                [attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                    self.roomDataSource[key] = obj;
                }];
                [self.roomInfoView reloadData:self.roomDataSource];
                [self.view makeToast:@"设置房间成功"];
            }
            else{
                [self.view makeToast:@"设置房间失败"];
            }
        });
    }];
}
- (IBAction)getRoomAttribute:(id)sender {
    
    [[RCSignalingClient sharedSignalingClient] getChannelAttributes:nil completion:^(RCSignalingErrorCode code, NSDictionary * _Nonnull info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == RCSignalingErrorCodeSuccess) {
                [self.roomDataSource removeAllObjects];
                self.roomDataSource[@"room"] = [RCSignalingClient sharedSignalingClient].channelInfo.channelId;
                [self.view makeToast:@"获取房间属性成功"];
                [info enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    self.roomDataSource[key] = obj;
                }];
                [self.roomInfoView reloadData:self.roomDataSource];
            }
            else{
                [self.view makeToast:@"获取房间属性失败"];
            }
        });
    }];
    
    
}
- (IBAction)deleteRoomAttribute:(id)sender {
    NSArray *allKeys = self.roomDataSource.allKeys;
    if (allKeys.count > 1) {
        NSString *key = allKeys.firstObject;
        if ([key isEqualToString:@"room"]) {
            key = allKeys[1];
        }
        [[RCSignalingClient sharedSignalingClient] deleteChannelAttributes:@[key] notifyOthers:YES completion:^(RCSignalingErrorCode code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (code == RCSignalingErrorCodeSuccess) {
                    [self.roomDataSource removeObjectForKey:key];
                    [self.roomInfoView reloadData:self.roomDataSource];
                    [self.view makeToast:@"删除属性成功"];
                }
                else{
                    [self.view makeToast:@"删除属性失败"];
                }
            });
        }];
    }
}
- (IBAction)setMyAttribute:(id)sender {
    
    NSDictionary *attributes =  @{[NSString stringWithFormat:@"random%ld",(long)(arc4random()%1000)]:@"HelloMember"};
    [[RCSignalingClient sharedSignalingClient] setMemberAttributes:attributes notifyOthers:YES completion:^(RCSignalingErrorCode code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == RCSignalingErrorCodeSuccess) {
                NSMutableDictionary *kvs = [self.membersDataSource[[SealCallManager sharedManager].userID] mutableCopy];
                if (!kvs) {
                    kvs = [@{@"userId":[SealCallManager sharedManager].userID} mutableCopy];
                }
                [attributes enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    kvs[key] = obj;
                }];
                self.membersDataSource[[SealCallManager sharedManager].userID] = kvs;
                [self.view makeToast:@"用户属性设置成功"];
                [self.memberInfoView reloadData:self.membersDataSource];
            }
            else{
                [self.view makeToast:@"用户属性设置失败"];
            }
        });
    }];
    
}
- (IBAction)getUserAttribute:(id)sender {
    
    RCSignalingChannelInfo *channelInfo = [RCSignalingClient sharedSignalingClient].channelInfo;
    NSArray *members = channelInfo.members;
    NSMutableArray *memberIdList = [NSMutableArray new];
    for (RCSignalingChannelMember *member in members) {
        [memberIdList addObject:member.memberId];
    }
    
    [[RCSignalingClient sharedSignalingClient] getMembersAttributes:memberIdList completion:^(RCSignalingErrorCode code, NSArray<RCSignalingChannelMember *> * _Nonnull members) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == RCSignalingErrorCodeSuccess) {
                for (RCSignalingChannelMember *member in members) {
                    NSMutableDictionary *kvs = [@{@"userId":member.memberId} mutableCopy];
                    [member.attribute enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                        kvs[key] = obj;
                    }];
                    self.membersDataSource[member.memberId] = kvs;
                }
                [self.memberInfoView reloadData:self.membersDataSource];
                [self.view makeToast:@"获取用户属性成功"];
            }
            else{
                [self.view makeToast:@"获取用户属性失败"];
            }
        });
        NSLog(@"sealquery=>query attribute: %ld",code);
    }];

}
- (IBAction)deleteMyAttribute:(id)sender {
    NSArray *allKeys = self.membersDataSource[[SealCallManager sharedManager].userID].allKeys;
    if (allKeys.count >= 1) {
        NSString *key = allKeys.firstObject;
        [[RCSignalingClient sharedSignalingClient] deleteMemberAttributes:@[key] notifyOthers:YES completion:^(RCSignalingErrorCode code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (code == RCSignalingErrorCodeSuccess) {
                    NSMutableDictionary *kvs = [self.membersDataSource[[SealCallManager sharedManager].userID] mutableCopy];
                    [kvs removeObjectForKey:key];
                    self.membersDataSource[[SealCallManager sharedManager].userID] = kvs;
                    [self.memberInfoView reloadData:self.membersDataSource];
                    [self.view makeToast:@"删除属性成功"];
                }
                else{
                    [self.view makeToast:@"删除属性失败"];
                }
            });
        }];
    }
}

-(void)didReceiveSignalingMessage:(RCSignalingEventInfo *)signaling{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        switch (signaling.signalingType) {
            case RCSignalingTypeLeave:{
                [self.membersDataSource removeObjectForKey:signaling.fromUserId];
                [self.memberInfoView reloadData:self.membersDataSource];
            }
                break;
            case RCSignalingTypeJoin:{
                NSDictionary *kvs = @{@"userId":signaling.fromUserId};
                self.membersDataSource[signaling.fromUserId] = kvs;
                [self.memberInfoView reloadData:self.membersDataSource];
            }
                break;
            default:
                break;
        }
        NSString *signalingContent = @"";
        if ([signaling.signalingContent isKindOfClass:NSDictionary.class]) {
            signalingContent = [NSString stringWithFormat:@"%@",signaling.signalingContent];
        }
        else{
            signalingContent = signaling.signalingContent;
        }
        [self.view makeToast:signalingContent];
    });
}


-(void)connected:(NSString *)userId{
    NSLog(@"sealquery=> IM Connected");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:@"IM 已连接"];
    });
    RCUserInfo *userInfo = [[RCUserInfo alloc]initWithUserId:userId name:@"" portrait:@""];
    [RCIMClient sharedRCIMClient].currentUserInfo = userInfo;
}


-(SealMemberInfoView *)memberInfoView{
    if (!_memberInfoView) {
        _memberInfoView = [[SealMemberInfoView alloc]initWithFrame:CGRectMake(0, 500, self.view.frame.size.width, self.view.frame.size.height - 500)];
        _memberInfoView.backgroundColor = [UIColor lightGrayColor];
    }
    return _memberInfoView;
}

-(SealRoomInfoView *)roomInfoView{
    if (!_roomInfoView) {
        _roomInfoView = [[SealRoomInfoView alloc]initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 300)];
    }
    return _roomInfoView;
}


- (IBAction)leaveRoom:(id)sender {
    
    [[RCSignalingClient sharedSignalingClient] leaveChannel:[SealCallManager sharedManager].roomId completion:^(RCSignalingErrorCode desc) {
        NSLog(@"sealquery=>leave channel code:%ld",desc);
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (IBAction)invite:(id)sender {
    RCSignalingInviteMessage *message = [RCSignalingInviteMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"invite";
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"发送成功"];
            }
            else{
                [self.view makeToast:@"发送失败"];
            }
            
        });
    }];
}

- (IBAction)accept:(id)sender {
    RCSignalingAcceptMessage *message = [RCSignalingAcceptMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"accept";
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"发送成功"];
            }
            else{
                [self.view makeToast:@"发送失败"];
            }
            
        });
    }];
}
- (IBAction)call:(id)sender {
    RCSignalingCallMessage *message = [RCSignalingCallMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"call";
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"发送成功"];
            }
            else{
                [self.view makeToast:@"发送失败"];
            }
            
        });
    }];
}
- (IBAction)hangup:(id)sender {
    RCSignalingHangupMessage *message = [RCSignalingHangupMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"hangup";
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"发送成功"];
            }
            else{
                [self.view makeToast:@"发送失败"];
            }
            
        });
    }];
}
- (IBAction)custom:(id)sender {
    RCSignalingCustomMessage *message = [RCSignalingCustomMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"custom";
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"发送成功"];
            }
            else{
                [self.view makeToast:@"发送失败"];
            }
            
        });
    }];
}
- (IBAction)cancel:(id)sender {
    RCSignalingCancelInviteMessage *message = [RCSignalingCancelInviteMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"cancelinvite";
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"发送成功"];
            }
            else{
                [self.view makeToast:@"发送失败"];
            }
            
        });
    }];
}
- (IBAction)reject:(id)sender {
    RCSignalingRejectMessage *message = [RCSignalingRejectMessage message];
    message.channelId = [SealCallManager sharedManager].roomId;
    message.signalingContent = @"reject";
    [[RCSignalingClient sharedSignalingClient] broadcastMessage:message completion:^(RCSignalingErrorCode desc) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (desc == RCSignalingErrorCodeSuccess) {
                [self.view makeToast:@"发送成功"];
            }
            else{
                [self.view makeToast:@"发送失败"];
            }
            
        });
    }];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
