//
//  SealCallViewController.m
//  SealCall
//
//  Created by LiuLinhong on 2019/08/14.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "SealCallViewController.h"
#import <RongIMLib/RongIMLib.h>
#import <RongSignalingLib/RongSignalingLib.h>
#import "RCFetchTokenManager.h"
#import <RongSignalingKit/RCSCall.h>
#import "SealCallManager.h"
//#import "RTCAgoraCallEngine.h"


@interface SealCallViewController () <RCSignalingClientDelegate,RCConnectionStatusChangeDelegate>

@property (nonatomic, strong) NSArray *allOtherUserIdArray;

@end


@implementation SealCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"SealCall";
    NSString *userId = [SealCallManager sharedManager].userID;
    NSString *defaultToken = [[NSUserDefaults standardUserDefaults] objectForKey:userId];
    [[RCIMClient sharedRCIMClient] setRCConnectionStatusChangeDelegate:self];
    if (!defaultToken) {
        [[RCFetchTokenManager sharedManager] fetchTokenWithUserId:[SealCallManager sharedManager].userID username:@"" portraitUri:@"" completion:^(BOOL isSucccess, NSString * _Nullable token) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (token) {
                    [[NSUserDefaults standardUserDefaults] setObject:token forKey:[SealCallManager sharedManager].userID];
                    [[RCIMClient sharedRCIMClient] connectWithToken:token success:^(NSString *userId) {
                        [self didConnected:userId];
                    } error:^(RCConnectErrorCode status) {
                        
                    } tokenIncorrect:^{
                        [self didDisconnected];
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
            [self didConnected:userId];
        } error:^(RCConnectErrorCode status) {
            
        } tokenIncorrect:^{
            [self didDisconnected];
        }];
    }
    
    UIBarButtonItem *multiItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Multy", @"RongCloudKit", nil) style:UIBarButtonItemStylePlain target:self action:@selector(multiItemAction)];
    self.navigationItem.rightBarButtonItem = multiItem;
    
    self.allOtherUserIdArray = [[SealCallManager sharedManager] getAllOtherUserIdArray];
}
- (void)onConnectionStatusChanged:(RCConnectionStatus)status{
    if (status == ConnectionStatus_Connected) {
        [self didConnected:[SealCallManager sharedManager].userID];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[RCIMClient sharedRCIMClient] disconnect];
}

- (void)didConnected:(NSString *)userId {
    NSLog(@"%s",__func__);
    RCUserInfo *currentUserInfo = [[RCUserInfo alloc]initWithUserId:userId name:userId portrait:@""];
    [RCIMClient sharedRCIMClient].currentUserInfo = currentUserInfo;
    [RCSCall sharedRCSCall];
}

- (void)didDisconnected {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)multiItemAction {
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"ConversationType", @"RongCloudKit", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertViewController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"VoIPAudioCall", @"RongCloudKit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[RCSCall sharedRCSCall] startMultiCall:ConversationType_GROUP targetId:@"" mediaType:RCSCallMediaAudio];
    }]];
    [alertViewController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"VoIPVideoCall", @"RongCloudKit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[RCSCall sharedRCSCall] startMultiCall:ConversationType_GROUP targetId:@"" mediaType:RCSCallMediaVideo];
    }]];
    [self presentViewController:alertViewController animated:YES completion:^{}];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allOtherUserIdArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    
    NSString *identifer = [NSString stringWithFormat:@"Cell%zd%zd", section, row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.textLabel.textColor = [UIColor blackColor];
        
        UIButton *audioButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth-6-36-12-36, 10, 36, 36)];
        [audioButton setImage:[self imageFromVoIPBundle:@"voip/audio_min.png"] forState:UIControlStateNormal];
        [audioButton setImage:[self imageFromVoIPBundle:@"voip/audio_min.png"] forState:UIControlStateHighlighted];
        [audioButton addTarget:self action:@selector(audioButtonPressedAction:) forControlEvents:UIControlEventTouchUpInside];
        [audioButton setTag:row];
        [cell.contentView addSubview:audioButton];
        
        UIButton *videoButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth-6-36, 10, 36, 36)];
        [videoButton setImage:[self imageFromVoIPBundle:@"voip/video_min.png"] forState:UIControlStateNormal];
        [videoButton setImage:[self imageFromVoIPBundle:@"voip/video_min.png"] forState:UIControlStateHighlighted];
        [videoButton addTarget:self action:@selector(videoButtonPressedAction:) forControlEvents:UIControlEventTouchUpInside];
        [videoButton setTag:row];
        [cell.contentView addSubview:videoButton];
    }
    
    cell.textLabel.text = self.allOtherUserIdArray[row];
    return cell;
}

- (void)audioButtonPressedAction:(id)sender {
    UIButton *btn = (UIButton *)sender;
    NSInteger row = btn.tag;
    NSString *targetUserId = self.allOtherUserIdArray[row];
    [[RCSCall sharedRCSCall] startSingleCall:targetUserId mediaType:RCSCallMediaAudio];
}

- (void)videoButtonPressedAction:(id)sender {
    UIButton *btn = (UIButton *)sender;
    NSInteger row = btn.tag;
    NSString *targetUserId = self.allOtherUserIdArray[row];
    [[RCSCall sharedRCSCall] startSingleCall:targetUserId mediaType:RCSCallMediaVideo];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSInteger row = [indexPath row];
//    NSString *targetUserId = self.allOtherUserIdArray[row];
//    [[RCSCall sharedRCSCall] startSingleCall:targetUserId mediaType:RCSCallMediaVideo];
//}
//
//- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
//{
//    return @" ";
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 30.0f;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 0.0f;
//}

#pragma mark - Private
- (UIImage *)imageFromVoIPBundle:(NSString *)imageName {
    NSString *imagePath = [[[NSBundle mainBundle] pathForResource:@"RongCloud" ofType:@"bundle"]
                           stringByAppendingPathComponent:imageName];
    
    UIImage *bundleImage = [UIImage imageWithContentsOfFile:imagePath];
    return bundleImage;
}


@end
