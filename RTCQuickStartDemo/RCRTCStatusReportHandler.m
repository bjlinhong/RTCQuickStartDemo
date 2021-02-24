//
//  RCRTCStatusReportHandler.m
//  RTCQuickStartDemo
//
//  Created by LiuLinhong on 2021/02/24.
//  Copyright © 2021 RongCloud. All rights reserved.
//

#import "RCRTCStatusReportHandler.h"

@interface RCRTCStatusReportHandler ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSNumber *> *timesOfExceedingBaseLine;

@end


@implementation RCRTCStatusReportHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timesOfExceedingBaseLine = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    
    return self;
}

#pragma mark - RCRTCStatusReportDelegate
//上报状态解析处理
- (void)didReportStatusForm:(RCRTCStatusForm *)form {
    BOOL isPrintStatusLog = NO; //如果需要打印报表日志, 请设置为YES
    
    //发送总量
    NSMutableString *totalSend = [[NSMutableString alloc] initWithFormat:@"总发送: %0.2fkbps    ", form.totalSendBitRate];
    [totalSend appendFormat:@"音视频往返延时: %@", @(form.rtt)];
    if (isPrintStatusLog) {
        NSLog(@"%@", totalSend);
    }
    
    //接收总量
    NSMutableString *totalReceive = [[NSMutableString alloc] initWithFormat:@"总接收: %0.2fkbps    ", form.totalRecvBitRate];
    if (isPrintStatusLog) {
        NSLog(@"%@", totalReceive);
    }
    
    //发送明细
    for (RCRTCStreamStat *sendStat in form.sendStats) {
        NSMutableString *sendDetailed = [[NSMutableString alloc] initWithFormat:@"本地  "];
        
        if ([sendStat.mediaType isEqualToString:RongRTCMediaTypeVideo]) {
            [sendDetailed appendString:@"视频发送  "];
            [sendDetailed appendFormat:@"视频编码: %@  ", sendStat.codecName];
            [sendDetailed appendFormat:@"分辨率: %@*%@  ", @(sendStat.frameWidth), @(sendStat.frameHeight)];
            [sendDetailed appendFormat:@"帧率: %@  ", @(sendStat.frameRate)];
        }
        else {
            [sendDetailed appendString:@"音频发送  "];
            [sendDetailed appendFormat:@"音频编码: %@  ", sendStat.codecName];
            [sendDetailed appendFormat:@"音量: %zd  ", sendStat.audioLevel];
        }
        
        [sendDetailed appendFormat:@"码率: %.2fkbps  ", sendStat.bitRate];
        [sendDetailed appendFormat:@"丢包率: %.f%%", sendStat.packetLoss * 100];
        
        if (isPrintStatusLog) {
            NSLog(@"%@", sendDetailed);
        }
    }
    
    //接收明细
    for (RCRTCStreamStat *recvStat in form.recvStats) {
        //获取远端用户UserID
        NSString *userId = [RCRTCStatusForm fetchUserIdFromTrackId:recvStat.trackId];
        NSMutableString *recvDetailed = [[NSMutableString alloc] initWithString:userId];
        
        if ([recvStat.mediaType isEqualToString:RongRTCMediaTypeVideo]) {
            [recvDetailed appendString:@"  视频接收  "];
            [recvDetailed appendFormat:@"视频编码: %@  ", recvStat.codecName];
            [recvDetailed appendFormat:@"分辨率: %@*%@  ", @(recvStat.frameWidth), @(recvStat.frameHeight)];
            [recvDetailed appendFormat:@"帧率: %@  ", @(recvStat.frameRate)];
        }
        else {
            [recvDetailed appendString:@"音频接收  "];
            [recvDetailed appendFormat:@"音频编码: %@  ", recvStat.codecName];
            [recvDetailed appendFormat:@"音量: %zd  ", recvStat.audioLevel];
        }
        
        [recvDetailed appendFormat:@"码率: %.2fkbps  ", recvStat.bitRate];
        [recvDetailed appendFormat:@"丢包率: %.f%%", recvStat.packetLoss * 100];
        
        if (isPrintStatusLog) {
            NSLog(@"%@", recvDetailed);
        }
    }
    
    
    /*
     弱网提示逻辑
     通话中, 监控每个参会者的网络丢包率, 1个监控周期为10秒,
     在1个监控周期内某人的音频丢包出现5次大于 30% 或 视频丢包率出现5次大于15%时, 需将此人认定为弱网
     */
    const CGFloat audioLossBaseline = 0.3;   // 音频丢包基准新(30%)
    const CGFloat videoLossBaseLine = 0.15;  // 视频丢包基准线(15%)
    const NSInteger cycleLength = 10;        // 统计周期长度(秒)
    const NSInteger timesThreshold = 5;      // 次数阈值(次)
    
    static NSInteger triggerTimes = 0;
    triggerTimes++;
    
    for (RCRTCStreamStat *each in form.sendStats) {
        if (([each.mediaType isEqualToString:RongRTCMediaTypeAudio] && each.packetLoss > audioLossBaseline) ||
            ([each.mediaType isEqualToString:RongRTCMediaTypeVideo] && each.packetLoss > videoLossBaseLine)) {
            NSInteger lastValue = [self.timesOfExceedingBaseLine[each.trackId] integerValue];
            self.timesOfExceedingBaseLine[each.trackId] = @(lastValue + 1);
        }
    }
    
    for (RCRTCStreamStat *each in form.recvStats) {
        if (([each.mediaType isEqualToString:RongRTCMediaTypeAudio] && each.packetLoss > audioLossBaseline) ||
            ([each.mediaType isEqualToString:RongRTCMediaTypeVideo] && each.packetLoss > videoLossBaseLine)) {
            NSInteger lastValue = [self.timesOfExceedingBaseLine[each.trackId] integerValue];
            self.timesOfExceedingBaseLine[each.trackId] = @(lastValue + 1);
        }
    }
    
    if (triggerTimes < cycleLength) {
        return;
    }
    triggerTimes = 0;
    
    NSMutableArray *userIdArray = [[NSMutableArray alloc] initWithCapacity:10];
    
    [self.timesOfExceedingBaseLine enumerateKeysAndObjectsUsingBlock:^(NSString *trackId, NSNumber *times, BOOL * _Nonnull stop) {
        NSInteger count = [times integerValue];
        if (count >= timesThreshold) {
            NSString *userId = [RCRTCStatusForm fetchUserIdFromTrackId:trackId];
            if (userId.length > 0) {
                [userIdArray addObject:userId];
            }
        }
    }];
    
    [self.timesOfExceedingBaseLine removeAllObjects];
    
    for (NSInteger i = 0; i < userIdArray.count; i++) {
        if (isPrintStatusLog) {
            NSLog(@"%@ 的网络状况不佳", userIdArray[i]);
        }
    }
}

@end
