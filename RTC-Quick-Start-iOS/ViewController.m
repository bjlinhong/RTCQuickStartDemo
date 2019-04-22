//
//  ViewController.m
//  HelloRTC
//
//  Created by jfdreamyang on 2019/3/29.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import <RongRTCLib/RongRTCLib.h>

@interface ViewController ()<RongRTCRoomDelegate>
@property (nonatomic,strong)RongRTCRoom *room;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // AppKey 设置请查看 AppDelegate

    // 设置采集参数，本地摄像头预览视图
    [[RongRTCAVCapturer sharedInstance] setCaptureParam:[RongRTCVideoCaptureParam defaultParameters]];
    RongRTCLocalVideoView * localView = [[RongRTCLocalVideoView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:localView];
    [[RongRTCAVCapturer sharedInstance] setVideoRender:localView];
    [[RongRTCAVCapturer sharedInstance] startCapture];
    // 连接 IM
    [[RCIMClient sharedRCIMClient] connectWithToken:@"" success:^(NSString *userId) {
        // 加入房间
        [[RongRTCEngine sharedEngine] joinRoom:@"HelloRTC" completion:^(RongRTCRoom * _Nullable room, RongRTCCode code) {
            room.delegate = self;
            self.room = room;
            // 发布资源
            [room.localUser publishDefaultAVStream:^(BOOL isSuccess, RongRTCCode desc) {
                
            }];
        }];
        
    } error:^(RCConnectErrorCode status) {
        
    } tokenIncorrect:^{
        
    }];
}


-(void)didPublishStreams:(NSArray<RongRTCAVInputStream *> *)streams{
    
    // 订阅资源
    [self.room.remoteUsers.firstObject subscribeAVStream:streams tinyStreams:nil completion:^(BOOL isSuccess, RongRTCCode desc) {
        
    }];
    // 设置远端渲染视图
    for (RongRTCAVInputStream * stream in streams) {
        if (stream.streamType == RTCMediaTypeVideo) {
            RongRTCRemoteVideoView * videoView = [[RongRTCRemoteVideoView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 120, self.view.frame.size.height - 120, 100, 100)];
            [stream setVideoRender:videoView];
            [self.view addSubview:videoView];
        }
    }
    
    
}





@end
