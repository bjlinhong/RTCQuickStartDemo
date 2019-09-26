//
//  SealMemberInfoView.m
//  RCSignalingQueryDemo
//
//  Created by jfdreamyang on 2019/9/4.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "SealMemberInfoView.h"

@interface SealMemberInfoView()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic,strong)NSArray <NSDictionary *> *allMembers;
@property (nonatomic,strong)NSArray <NSString *>*userIds;
@end

@implementation SealMemberInfoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.tableView];
        [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"UITableViewCell"];
    }
    return self;
}

-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 20;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSDictionary *item = self.allMembers[section];
    return item.allKeys.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.allMembers.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.userIds[section];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    NSArray *allKeys = self.allMembers[indexPath.section].allKeys;
    NSString *key = allKeys[indexPath.row];
    NSString *value = [NSString stringWithFormat:@"%@",self.allMembers[indexPath.section][key]];
    cell.textLabel.text = [NSString stringWithFormat:@"K=>%@  V=>%@",key,value];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

-(void)reloadData:(NSDictionary *)dataSource{
    
    NSMutableDictionary *__dataSource = dataSource.mutableCopy;
    
    self.userIds = __dataSource.allKeys;
    
    NSMutableArray *members = [NSMutableArray new];
    [dataSource.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *item = [dataSource[obj] mutableCopy];
        [item removeObjectForKey:@"userId"];
        [members addObject:item];
    }];
    self.allMembers = members;
    [self.tableView reloadData];
}
@end
