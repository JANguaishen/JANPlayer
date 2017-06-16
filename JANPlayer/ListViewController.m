//
//  ListViewController.m
//  JANPlayer
//
//  Created by 纪奥宁 on 2017/6/15.
//  Copyright © 2017年 纪奥宁. All rights reserved.
//

#import "ListViewController.h"
#import "JANPlayerView.h"
#import "CustomTableViewCell.h"

@interface ListViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong)UITableView *tableView;//视频列表

@property (nonatomic, strong)NSMutableArray *dataSource;

@property (strong, nonatomic) JANPlayerView *playerView;//播放器View

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView = [[UITableView alloc]initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    self.dataSource = [[NSMutableArray alloc]init];
    NSDictionary *dic = @{@"name":@"视频名称",@"url":@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"};
    for(int i = 0;i < 10; i++)
    {
        [self.dataSource addObject:dic];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 180;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"custom"];
    if(cell == nil){
        cell = [[CustomTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"custom"];
    }
    NSDictionary *dic = self.dataSource[indexPath.row];
    [cell setValueWithData:dic AndIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
    //获取cell在window上的位置
    CGRect rect = [tableView convertRect:rectInTableView toView:[tableView superview]];
    if(!self.playerView){
        self.playerView  = [[JANPlayerView alloc]initWithFrame:cell.bounds];
    }
    [cell addSubview:self.playerView];
    //设置playerView在window上的位置  因为有nav 所以+64
    self.playerView.windowRect = CGRectMake(rect.origin.x, rect.origin.y + 64, rect.size.width, rect.size.height);
    
    [self.playerView playWithUrl:[NSURL URLWithString:[self.dataSource[indexPath.row] objectForKey:@"url"]]];
}

//在非全屏状态下不允许切换横竖屏
- (BOOL)shouldAutorotate
{
    return self.playerView.isFullScreen;
}
//横竖屏支持方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}
//自动选择横竖屏时会调用viewWillLayoutSubviews viewDidLayoutSubviews 在这方法里设置playerView的frame，会保持屏幕旋转动画与playerView的变化一致， 若不在此设置而在playerView内的屏幕旋转通知内设置frame  动画不一致 能看到playerView后面的controller  可自行测试
- (void)viewWillLayoutSubviews

{
    self.playerView.frame = [UIScreen mainScreen].bounds;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
