//
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import <RongRTCLib/RongRTCLib.h>

@interface ViewController () <RCRTCRoomEventDelegate>
@property(nonatomic, strong) RCRTCRoom *room;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  // AppKey 设置请查看 AppDelegate

  // 设置采集参数，本地摄像头预览视图
    RCRTCLocalVideoView *localView = [[RCRTCLocalVideoView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:localView];
  [[[RCRTCEngine sharedInstance] defaultVideoStream] setVideoView:localView];
  [[[RCRTCEngine sharedInstance] defaultVideoStream] startCapture];
  // 连接 IM
  [[RCIMClient sharedRCIMClient]
      connectWithToken:@""
              dbOpened:^(RCDBErrorCode code) {
              }
               success:^(NSString *userId) {
                 [[RCRTCEngine sharedInstance] joinRoom:@"HelloRTC" completion:^(RCRTCRoom *_Nullable room,
                     RCRTCCode code) {
                   room.delegate = self;
                   self.room = room;
                   // 发布资源
                   [room.localUser publishDefaultStream:^(BOOL isSuccess, RCRTCCode desc) {
                   }];
                 }];
               }
                 error:^(RCConnectErrorCode status) {
                 }
  ];
}

- (void)didPublishStreams:(NSArray<RCRTCInputStream *> *)streams {
  // 订阅资源
  [self.room.localUser subscribeStream:streams tinyStreams:nil completion:^(BOOL isSuccess, RCRTCCode desc) {
  }];
  // 设置远端渲染视图
  for (RCRTCInputStream *stream in streams) {
    if (stream.mediaType == RTCMediaTypeVideo) {
      RCRTCRemoteVideoView *videoView = [[RCRTCRemoteVideoView alloc] initWithFrame:CGRectMake(
          self.view.frame.size.width - 120,
          self.view.frame.size.height - 120,
          100,
          100)];
      [(RCRTCVideoInputStream *) stream setVideoView:videoView];
      [self.view addSubview:videoView];
    }
  }
}

@end
