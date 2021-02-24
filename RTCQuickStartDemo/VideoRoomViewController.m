//
//  VideoRoomViewController.m
//  RTCQuickStartDemo
//
//  Created by huan xu on 2020/10/27.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "VideoRoomViewController.h"
#import "AppID.h"
#import <Masonry.h>
#import <RongRTCLib/RongRTCLib.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCRTCStatusReportHandler.h"

#define kScreenWidth self.view.frame.size.width
#define kScreenHeight self.view.frame.size.height


@interface VideoRoomViewController () <RCRTCRoomEventDelegate>

@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) RCRTCLocalVideoView *localView;
@property (nonatomic, strong) RCRTCRemoteVideoView *remoteView;
@property (nonatomic, strong) RCRTCRoom *room;
@property (nonatomic, strong) RCRTCEngine *engine;

@end


@implementation VideoRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeRCIMCoreClient];
    [self initializeRCRTCEngine];
    [self setupLocalVideoView];
    [self setupRemoteVideoView];
    [self setupRoomMenuView];
    [self joinRoom];
}

- (void)initializeRCIMCoreClient {
    //融云SDK 5.0.0 及其以上版本使用
    [[RCCoreClient sharedCoreClient] initWithAppKey:AppID];
    [[RCCoreClient sharedCoreClient] connectWithToken:token
                                             dbOpened:^(RCDBErrorCode code) {
        NSLog(@"MClient dbOpened code: %zd", code);
    } success:^(NSString *userId) {
        NSLog(@"IM连接成功userId: %@", userId);
    } error:^(RCConnectErrorCode status) {
        NSLog(@"IM连接失败errorCode: %ld", (long)status);
    }];
    
    /*
     //融云SDK 5.0.0 以下版本, 不包含5.0.0 使用
    //初始化融云 SDK
    [[RCIMClient sharedRCIMClient] initWithAppKey:AppID];
    RCIMClient.sharedRCIMClient.logLevel = RC_Log_Level_None;
    //前置条件 IM建立连接
    [[RCIMClient sharedRCIMClient] connectWithToken:token
                                           dbOpened:^(RCDBErrorCode code) {
    }
                                            success:^(NSString *userId) {
        NSLog(@"IM连接成功userId:%@",userId);
    }
                                              error:^(RCConnectErrorCode errorCode) {
        NSLog(@"IM连接失败errorCode:%ld",(long)errorCode);
    }];
     */
}

- (void)initializeRCRTCEngine {
    self.engine = [RCRTCEngine sharedInstance];
    [self.engine enableSpeaker:YES];
    
    //解析音视频房间状态报告
    RCRTCStatusReportHandler *reportHandler = [[RCRTCStatusReportHandler alloc] init];
    self.engine.statusReportDelegate = reportHandler;
}

//添加本地采集预览界面
- (void)setupLocalVideoView{
    RCRTCLocalVideoView *localView = [[RCRTCLocalVideoView alloc] initWithFrame:self.view.bounds];
    localView.fillMode = RCRTCVideoFillModeAspectFill;
    [self.view addSubview:localView];
    self.localView = localView;
}
    
//添加远端视频小窗口
- (void)setupRemoteVideoView{
    CGRect rect = CGRectMake(kScreenWidth - 120, 20, 100, 100 * 4/3);
    _remoteView = [[RCRTCRemoteVideoView alloc] initWithFrame:rect];
    _remoteView.fillMode = RCRTCVideoFillModeAspectFill;
    [_remoteView setHidden:YES];
    [self.view addSubview:_remoteView];
}

//添加控制按钮层
- (void)setupRoomMenuView{
    [self.view addSubview:self.menuView];
    [self.menuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.bottom.mas_equalTo(-50);
        make.size.mas_offset(CGSizeMake(kScreenWidth, 50));
    }];
}

/*
 加入房间, 回调成功后:
   1.本地视频采集
   2.发布本地视频流
   3.加入房间时如果已经有远端用户在房间中, 需要订阅远端流
 */
- (void)joinRoom {
    __weak typeof(self) weakSelf = self;
    [[RCRTCEngine sharedInstance] joinRoom:RoomId completion:^(RCRTCRoom * _Nullable room, RCRTCCode code) {
        __strong typeof(weakSelf) self = weakSelf;
        if (code == RCRTCCodeSuccess) {
            //设置房间代理
            self.room = room;
            room.delegate = self;
            
            // 1.本地视频采集
            [[self.engine defaultVideoStream] setVideoView:self.localView];
            [[self.engine defaultVideoStream] startCapture];
            
            // 2.发布本地视频流
            [room.localUser publishDefaultStreams:^(BOOL isSuccess, RCRTCCode desc) {
                if (isSuccess && desc == RCRTCCodeSuccess) {
                    NSLog(@"本地流发布成功");
                }
            }];
    
            // 3.加入房间时如果已经有远端用户在房间中, 需要订阅远端流
            if ([room.remoteUsers count] > 0) {
                NSMutableArray *streamArray = [NSMutableArray array];
                for (RCRTCRemoteUser *user in room.remoteUsers) {
                    [streamArray addObjectsFromArray:user.remoteStreams];
                }
                // 订阅远端音视频流
                [self subscribeRemoteResource:streamArray];
            }
        } else {
            NSLog(@"加入房间失败");
        }
    }];
}

//麦克风静音
- (void)micMute:(UIButton *)btn {
    btn.selected = !btn.selected;
    [self.engine.defaultAudioStream setMicrophoneDisable:btn.selected];
}

//本地摄像头切换
- (void)changeCamera:(UIButton *)btn {
    btn.selected = !btn.selected;
    [self.engine.defaultVideoStream switchCamera];
}

//挂断
- (void)exitRoom {
    //取消本地发布
    [self.room.localUser unpublishDefaultStreams:^(BOOL isSuccess, RCRTCCode desc) {}];
    //关闭摄像头采集
    [self.engine.defaultVideoStream stopCapture];
    [self.remoteView removeFromSuperview];
    //退出房间
    [self.engine leaveRoom:RoomId
                completion:^(BOOL isSuccess, RCRTCCode code) {
        if (isSuccess && code == RCRTCCodeSuccess) {
            NSLog(@"退出房间成功code:%ld",(long)code);
        }
    }];
}

#pragma mark - RCRTCRoomEventDelegate
- (void)didPublishStreams:(NSArray<RCRTCInputStream *> *)streams {
    [self subscribeRemoteResource:streams];
}

- (void)didUnpublishStreams:(NSArray<RCRTCInputStream *>*)streams {
    [self.remoteView setHidden:YES];
}

- (void)didLeaveUser:(RCRTCRemoteUser*)user {
    [self.remoteView setHidden:YES];
}

- (void)subscribeRemoteResource:(NSArray<RCRTCInputStream *> *)streams {
    // 订阅房间中远端用户音视频流资源
    [self.room.localUser subscribeStream:streams
                             tinyStreams:nil
                              completion:^(BOOL isSuccess, RCRTCCode desc) {}];
    // 创建并设置远端视频预览视图
    for (RCRTCInputStream *stream in streams) {
        if (stream.mediaType == RTCMediaTypeVideo) {
            [(RCRTCVideoInputStream *) stream setVideoView:self.remoteView];
            [self.remoteView setHidden:NO];
        }
    }
}

#pragma mark - Lazy Loading
- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [UIView new];
        UIButton *muteBtn = [UIButton buttonWithType:0];
        [muteBtn setImage:[UIImage imageNamed:@"mute"] forState:0];
        [muteBtn setImage:[UIImage imageNamed:@"mute_hover"] forState:UIControlStateSelected];
        [muteBtn addTarget:self action:@selector(micMute:) forControlEvents:UIControlEventTouchUpInside];
        UIButton *exitBtn = [UIButton buttonWithType:0];
        [exitBtn setImage:[UIImage imageNamed:@"hang_up"] forState:0];
        [exitBtn addTarget:self action:@selector(exitRoom) forControlEvents:UIControlEventTouchUpInside];
        UIButton *changeBtn = [UIButton buttonWithType:0];
        [changeBtn setImage:[UIImage imageNamed:@"camera"] forState:0];
        [changeBtn setImage:[UIImage imageNamed:@"camera_hover"] forState:UIControlStateSelected];
        [changeBtn addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
        [_menuView addSubview:muteBtn];
        [_menuView addSubview:exitBtn];
        [_menuView addSubview:changeBtn];
        
        CGFloat padding = (kScreenWidth - 50 * 3)/4;
        CGSize btnSize = CGSizeMake(50, 50);
        
        [muteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_offset(padding);
            make.centerY.mas_equalTo(0);
            make.size.mas_offset(btnSize);
        }];
        [exitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(0);
            make.size.mas_offset(btnSize);
        }];
        [changeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_offset(-padding);
            make.centerY.mas_equalTo(0);
            make.size.mas_offset(btnSize);
        }];
    }
    return _menuView;
}

@end
