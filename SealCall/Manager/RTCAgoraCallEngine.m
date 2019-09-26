//
//  RTCAgoraCallEngine.m
//  SealCall
//
//  Created by jfdreamyang on 2019/8/27.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RTCAgoraCallEngine.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import <RongSignalingLib/RongSignalingLib.h>
#import <RongSignalingKit/RCSCallLib.h>
#import <RongIMLib/RongIMLib.h>

NSString *const kAgoraAppID = @"f9ab64251ff84a0e91194f491812432d";
NSString *const kAgoraToken = nil;

@interface RTCAgoraCallEngine ()<AgoraRtcEngineDelegate>
@property (nonatomic, weak)id <RCSAVEngineDelegate> weakDelegate;
@property (nonatomic, strong)AgoraRtcEngineKit *agoraKit;
@property (nonatomic, strong)NSMutableSet *joinedUserIdSet;
@property (nonatomic, strong)NSMutableDictionary *remoteVideoViewDic;
@property (nonatomic, strong)NSString *userID;
@property (nonatomic, strong)AgoraRtcVideoCanvas *localPreview;
@end

@implementation RTCAgoraCallEngine


- (instancetype)init {
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

-(void)configure{
    self.remoteVideoViewDic = [NSMutableDictionary new];
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:kAgoraAppID delegate:self];
    NSString *userId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
    [self.agoraKit registerLocalUserAccount:userId appId:kAgoraAppID];
}

-(void)setDelegate:(id<RCSAVEngineDelegate>)delegate{
    self.weakDelegate = delegate;
}

-(id<RCSAVEngineDelegate>)delegate{
    return self.weakDelegate;
}

- (void)setUserId:(NSString *)userId {
    self.userID = userId;
}

-(void)joinChannel{
    RCSCallProfile *profile = [self.delegate currentCallProfileOfManager];
    NSString *userId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
    [self.agoraKit joinChannelByUserAccount:userId token:nil channelId:profile.callId joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        [self.delegate onJoinAVEngineSuccess:YES withCode:0];
        [self.delegate onPublishLocalAVStreamSuccess:YES withCode:0];
    }];
}

-(void)leaveChannel{
    [self.agoraKit leaveChannel:^(AgoraChannelStats * _Nonnull stat) {
        
    }];
    [self.agoraKit stopPreview];
    [self.remoteVideoViewDic removeAllObjects];
    self.localPreview = nil;
}


- (void)setLocalViewRenderMode:(RCSCallRenderMode)mode{
    dispatch_async(dispatch_get_main_queue(), ^{
        RCSCallProfile *profile = [self.delegate currentCallProfileOfManager];
        if (profile.myStatus.mediaType == RCSCallMediaVideo) {
            UIView *mainView = profile.myStatus.videoView;
            [self.agoraKit enableVideo];
            if (self.localPreview) {
                [self.localPreview.view removeFromSuperview];
            }
            self.localPreview = [[AgoraRtcVideoCanvas alloc]init];
            AgoraVideoEncoderConfiguration *encoderConfiguration =
            [[AgoraVideoEncoderConfiguration alloc] initWithSize:AgoraVideoDimension640x480
                                                       frameRate:AgoraVideoFrameRateFps15
                                                         bitrate:AgoraVideoBitrateStandard orientationMode:AgoraVideoOutputOrientationModeAdaptative];
            [self.agoraKit setVideoEncoderConfiguration:encoderConfiguration];
            AgoraErrorCode code;
            AgoraUserInfo *userInfo = [self.agoraKit getUserInfoByUserAccount:[RCIMClient sharedRCIMClient].currentUserInfo.userId withError:&code];
            self.localPreview.uid = userInfo.uid;
            UIView *renderView = [[UIView alloc]initWithFrame:mainView.bounds];
            [mainView addSubview:renderView];
            self.localPreview.view = renderView;
            [self.agoraKit setupLocalVideo:self.localPreview];
            [self.agoraKit startPreview];
            self.localPreview.renderMode = (AgoraVideoRenderMode)mode;
        }
    });
}

- (void)setRemoteViewUserId:(NSString *)userId renderMode:(RCSCallRenderMode)mode{
    RCSCallProfile *profile = [self.delegate currentCallProfileOfManager];
    RCSCallUserProfile *userProfile = [profile getUserStatusInMemberStatusList:userId];
    UIView *remoteView = userProfile.videoView;
    if (profile.myStatus.mediaType == RCSCallMediaVideo) {
        
        AgoraRtcVideoCanvas *remoteVideoView = self.remoteVideoViewDic[userId];
        if (remoteVideoView) {
            [remoteVideoView.view removeFromSuperview];
            
        }
        remoteVideoView = [[AgoraRtcVideoCanvas alloc]init];
        remoteVideoView.view = [[UIView alloc]initWithFrame:remoteView.bounds];
        [remoteView addSubview:remoteVideoView.view];
        remoteVideoView.renderMode = (AgoraVideoRenderMode)mode;
        AgoraErrorCode code;
        AgoraUserInfo *userInfo = [self.agoraKit getUserInfoByUserAccount:userId withError:&code];
        if (code == AgoraErrorCodeNoError) {
            remoteVideoView.uid = userInfo.uid;
            [self.agoraKit setupRemoteVideo:remoteVideoView];
        } else {
            remoteVideoView.uid = 0;
        }
        self.remoteVideoViewDic[userId] = remoteVideoView;
    }
}

- (void)setMicrophoneEnabled:(BOOL)enabled{
    if (enabled) {
        [self.agoraKit enableAudio];
    }
    else{
        [self.agoraKit disableAudio];
    }
}

- (void)setSpeakerEnabled:(BOOL)enabled{
    [self.agoraKit setEnableSpeakerphone:enabled];
}

- (void)setCameraEnabled:(BOOL)enabled{
    if (enabled) {
        [self.agoraKit enableVideo];
    }
    else{
        [self.agoraKit disableVideo];
    }
}

- (void)switchCamera{
    [self.agoraKit switchCamera];
}

- (RCSCallEngineType)getEngineType {
    return RCSCallEngineAgora;
}

- (RCSCallEngineCapability)getEngineCapability {
    return  RCSCallCapabilityAudioSingleCall | RCSCallCapabilityAudioMultiCall  | RCSCallCapabilityVideoSingleCall | RCSCallCapabilityVideoMultiCall;
}

#pragma mark - Agora Delegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed{
    NSLog(@"JoinedOfUid: %zd  elapsed: %zd", uid, elapsed);
}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason{
    AgoraErrorCode code;
    AgoraUserInfo *userInfo = [self.agoraKit getUserInfoByUid:uid withError:&code];
    [self.joinedUserIdSet removeObject:userInfo.userAccount];
    [self.delegate onRemoteUserOfflineSuccess:YES withUserId:userInfo.userAccount];
}
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine firstRemoteAudioFrameDecodedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed{
    AgoraErrorCode code;
    AgoraUserInfo *userInfo = [self.agoraKit getUserInfoByUid:uid withError:&code];
    [self.joinedUserIdSet addObject:userInfo.userAccount];
    [self.delegate onRemoteUserOnlineSuccess:YES withUserId:userInfo.userAccount];
    AgoraRtcVideoCanvas *convas = self.remoteVideoViewDic[userInfo.userAccount];
    if (convas && convas.uid != uid) {
        convas.uid = uid;
        [self.agoraKit setupRemoteVideo:convas];
    }
    [self.delegate onSubscribeRemoteAVStreamSuccess:YES withCode:0];
}


- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size: (CGSize)size elapsed:(NSInteger)elapsed{
    AgoraErrorCode code;
    AgoraUserInfo *userInfo = [self.agoraKit getUserInfoByUid:uid withError:&code];
    [self.delegate didRemoteFirstKeyFrame:userInfo.userAccount];
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine didRegisteredLocalUser:(NSString *)userAccount withUid:(NSUInteger)uid{
    RCLogI(@"register success userId:%@ uid:%lu",userAccount,(unsigned long)uid);
}

@end
