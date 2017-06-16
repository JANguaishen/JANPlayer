//
//  CustomNavigationController.m
//  video
//
//  Created by 纪奥宁 on 2017/6/12.
//  Copyright © 2017年 纪奥宁. All rights reserved.
//

#import "CustomNavigationController.h"
#import "ListViewController.h"

@interface CustomNavigationController ()

@end

@implementation CustomNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


//普通vc只支持竖屏
- (BOOL)shouldAutorotate
{
    if([self.topViewController isKindOfClass:[ListViewController class]])
    {
        return self.topViewController.shouldAutorotate;
    }
    return YES;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if([self.topViewController isKindOfClass:[ListViewController class]])
    {
        return self.topViewController.supportedInterfaceOrientations;
    }
    return UIInterfaceOrientationMaskPortrait;
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
