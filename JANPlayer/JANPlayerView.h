//
//  PlayerView.h
//  video
//
//  Created by 纪奥宁 on 2017/6/7.
//  Copyright © 2017年 纪奥宁. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JANPlayerDelegate <NSObject>

//窗口模式下的frame  default is init frame
- (void)changeTheFrameOfPlayerViewOnWindow;
//全屏模式下的frame  注意存在nav情况下frame的y值
- (void)changeTheFrameOfPlayerViewOnFullScreen;

@end

@interface JANPlayerView : UIView

@property (nonatomic, weak) id delegate;

@property (nonatomic, weak) UIView *windowSuperView;

@property (nonatomic, assign)CGRect windowRect;

@property (nonatomic, assign)CGRect fullScreenRect;

/** 是否是全屏*/
@property (nonatomic, assign) BOOL isFullScreen;

- (void)playWithUrl:(NSURL *)url;

@end
