//
//  ViewController.m
//  RCSignalingQueryDemo
//
//  Created by jfdreamyang on 2019/9/4.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import "ZHPickView.h"
#import "SealCallManager.h"
#import <RongSignalingLib/RongSignalingLib.h>

static NSString * const SegueIdentifierCall = @"Call";
@interface ViewController ()<ZHPickViewDelegate>
{
    NSInteger selectedIndex;
}
@property (weak, nonatomic) IBOutlet UITextField *roomTextfield;
@property (weak, nonatomic) IBOutlet UIButton *selectUserIDButton;
@property (nonatomic, strong) ZHPickView *userIDPickView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    selectedIndex = [userDefaults integerForKey:kSelectedUserIDIndex];
    
    [self setUserButtonTitle:selectedIndex];
    
    self.userIDPickView = [[ZHPickView alloc] initPickviewWithArray:[SealCallManager sharedManager].userIDArray isHaveNavControler:NO];
    self.userIDPickView.delegate = self;
    [self.userIDPickView setSelectedPickerItem:selectedIndex];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(remove)];
    [self.view addGestureRecognizer:tap];
    
    
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [SealCallManager sharedManager].roomId = self.roomTextfield.text;
}

-(void)remove{
    [self.roomTextfield resignFirstResponder];
}


-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    
    return YES;
    
    
}


- (IBAction)selectUserIDAction:(id)sender {
    [self.userIDPickView show];
}
- (void)setUserButtonTitle:(NSInteger)index {
    [[SealCallManager sharedManager] setIndex:index];
    NSArray *userIDs = [SealCallManager sharedManager].userIDArray;
    [SealCallManager sharedManager].userID = userIDs[index];
    NSLog(@"111===========>%@",[SealCallManager sharedManager].userID);
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
