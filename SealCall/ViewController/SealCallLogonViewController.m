//
//  SealCallLogonViewController.m
//  SealCall
//
//  Created by LiuLinhong on 2019/08/18.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "SealCallLogonViewController.h"
#import "SealCallViewController.h"
#import "ZHPickView.h"
#import "SealCallManager.h"

static NSString * const SegueIdentifierCall = @"Call";


@interface SealCallLogonViewController () <ZHPickViewDelegate>
{
    NSInteger selectedIndex;
}
@property (nonatomic, strong) ZHPickView *userIDPickView;

@end


@implementation SealCallLogonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Logon";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    selectedIndex = [userDefaults integerForKey:kSelectedUserIDIndex];
    
    [self setUserButtonTitle:selectedIndex];
    
    self.userIDPickView = [[ZHPickView alloc] initPickviewWithArray:[SealCallManager sharedManager].userIDArray isHaveNavControler:NO];
    self.userIDPickView.delegate = self;
    [self.userIDPickView setSelectedPickerItem:selectedIndex];
}

- (IBAction)selectUserIDAction:(id)sender {
    [self.userIDPickView show];
}

- (IBAction)startButtonAction:(UIButton *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.navigationController.topViewController isKindOfClass:[SealCallViewController class]]){
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setInteger:self->selectedIndex forKey:kSelectedUserIDIndex];
            [userDefaults synchronize];
            [self performSegueWithIdentifier:SegueIdentifierCall sender:self.startButton];
        }
    });
}

- (void)setUserButtonTitle:(NSInteger)index {
    NSArray *userIDs = [SealCallManager sharedManager].userIDArray;
    [self.selectUserIDButton setTitle:userIDs[index] forState:UIControlStateNormal];
    [self.selectUserIDButton setTitle:userIDs[index] forState:UIControlStateHighlighted];
}

#pragma mark - ZhpickVIewDelegate
- (void)toolbarDonBtnHaveClick:(ZHPickView *)pickView resultString:(NSString *)resultString selectedRow:(NSInteger)selectedRow
{
    selectedIndex = selectedRow;
    [self setUserButtonTitle:selectedRow];
}

- (void)toolbarCancelBtnHaveClick:(ZHPickView *)pickView
{
}


@end
