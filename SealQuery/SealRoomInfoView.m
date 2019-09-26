//
//  SealRoomInfoView.m
//  RCSignalingQueryDemo
//
//  Created by jfdreamyang on 2019/9/4.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "SealRoomInfoView.h"

@interface SealRoomInfoView()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic,strong)NSDictionary <NSString *,NSString *>*dataSource;
@property (nonatomic,strong)NSArray <NSString *>*allKeys;
@end


@implementation SealRoomInfoView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
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
    return self.dataSource.allKeys.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    NSString *key = self.allKeys[indexPath.row];
    NSString *value = self.dataSource[key];
    cell.textLabel.text = [NSString stringWithFormat:@"K=>%@  V=>%@",key,value];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

-(void)reloadData:(NSDictionary *)dataSource{
    
    NSMutableDictionary *__dataSource = dataSource.mutableCopy;
    
    NSString *v = __dataSource[@"room"];
    [__dataSource removeObjectForKey:@"room"];
    
    NSMutableArray *__allKeys = __dataSource.allKeys.mutableCopy;
    [__allKeys insertObject:@"room" atIndex:0];
    __dataSource[@"room"] = v;
    self.allKeys = __allKeys;
    self.dataSource = __dataSource;
    [self.tableView reloadData];
}

@end
