//
//  CustomTabbarController.m
//  video
//
//  Created by 纪奥宁 on 2017/6/7.
//  Copyright © 2017年 纪奥宁. All rights reserved.
//

#import "CustomTabbarController.h"
#import "ListViewController.h"
#import "CustomNavigationController.h"

@interface CustomTabbarController ()

@end

@implementation CustomTabbarController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController *other1 = [[UIViewController alloc]init];
    other1.title = @"首页";
    
    UIViewController *other2 = [[UIViewController alloc]init];
    other2.title = @"服务";
    
    UIViewController *other3 = [[UIViewController alloc]init];
    other3.title = @"商城";
    
    ListViewController *faxian = [[ListViewController alloc]init];
    faxian.title = @"发现";
    UIViewController *other4 = [[UIViewController alloc]init];
    other4.title = @"我的";
    self.viewControllers = @[
                             [self setNavControllerWithViewController:other1 andImgName:@"" andSelectImgName:@""],
                             [self setNavControllerWithViewController:other2 andImgName:@"" andSelectImgName:@""],
                             [self setNavControllerWithViewController:other3 andImgName:@"" andSelectImgName:@""],
                             [self setNavControllerWithViewController:faxian andImgName:@"" andSelectImgName:@""],
                             [self setNavControllerWithViewController:other4 andImgName:@"" andSelectImgName:@""]];
    self.selectedIndex = 3;
}

- (CustomNavigationController *)setNavControllerWithViewController:(UIViewController *)viewController andImgName:(NSString*)imgName andSelectImgName:(NSString*)selectImgName
{
    CustomNavigationController *nav = [[CustomNavigationController alloc]initWithRootViewController:viewController];
    nav.navigationBar.translucent = NO;
    nav.tabBarItem.image = [UIImage imageNamed:imgName];
    nav.tabBarItem.selectedImage = [UIImage imageNamed:selectImgName];
    return nav;
}
//普通vc只支持竖屏
- (BOOL)shouldAutorotate
{
    return self.selectedViewController.shouldAutorotate;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.selectedViewController.supportedInterfaceOrientations;
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
