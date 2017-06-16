//
//  PlayerView.m
//  video
//
//  Created by 纪奥宁 on 2017/6/7.
//  Copyright © 2017年 纪奥宁. All rights reserved.
//

#import "JANPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import <MediaPlayer/MediaPlayer.h>

@interface JANPlayerView ()<UIGestureRecognizerDelegate>
{
    CGPoint startPoint;
    CGPoint changePoint;
    id _playerTimeObserver; /* 时间观察者 */
}
/** 播放器 */
@property (nonatomic, strong) AVPlayer *player;
/** 播放器的layer */
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/** 视频资源 */
@property (nonatomic, strong) AVPlayerItem *currentItem;
/* 视频总时长 */
@property (nonatomic, assign) CGFloat totalTime;
/** 是否正在拖动*/
@property (nonatomic, assign) BOOL isSliding;
/** 加载Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
//
//窗口情况下 视频控制菜单
//
//中间播放按钮
@property (nonatomic, strong) UIButton *centerPlayButton;
//底部控制条
@property (nonatomic, strong) UIView *bottomView;//与全屏共用
//播放按钮
@property (nonatomic, strong) UIButton *bottomPlayButton;
//当前时长
@property (nonatomic, strong) UILabel *currentTimeLabel;//与全屏共用
//总时长
@property (nonatomic, strong) UILabel *totalTimeLabel;//与全屏共用
//进度条
@property (nonatomic, strong) UISlider *sliderView;//与全屏共用
//缓存条
@property (nonatomic, strong) UIProgressView *loadedProgress;//与全屏共用
//切换全屏
@property (nonatomic, strong) UIButton *rotationButton;//与全屏共用

//
//全屏情况下 视频控制菜单
//
//顶部控制条
@property (nonatomic, strong) UIView *topView;
//提示文字
@property (nonatomic, strong) UILabel *tipLabel;
//音量控制
@property (nonatomic, strong) MPVolumeView *volumeView;

@property (nonatomic, assign) BOOL isFirst;
//初始frame
@property (nonatomic, assign) CGRect initFrame;

@property (nonatomic, strong) NSTimer *timer;
//是否显示工具条
@property (nonatomic, assign) BOOL isShowControlView;
@end

@implementation JANPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor blackColor];
        self.isFullScreen = NO;
        _isShowControlView = NO;
        [self createCommonView];
        self.initFrame = frame;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doRotateAction:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}
#
#pragma mark - 页面布局
#
//
//窗口模式下视频控制菜单
//
- (void)createControlViewOnWindow
{
    //窗口模式下底部控制条
    self.bottomView = [[UIView alloc]init];
    self.bottomView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.7];
    [self addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.bottom.equalTo(self.mas_bottom);
        make.width.equalTo(self.mas_width);
        make.height.mas_equalTo(40);
    }];
    //播放按钮
    self.bottomPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.bottomPlayButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateSelected];
    [self.bottomPlayButton setImage:[UIImage imageNamed:@"Stop.png"] forState:UIControlStateNormal];
    [self.bottomPlayButton addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.bottomPlayButton];
    [self.bottomPlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.bottom.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    //当前时长
    self.currentTimeLabel = [[UILabel alloc]init];
    self.currentTimeLabel.textColor = [UIColor blackColor];
    self.currentTimeLabel.font = [UIFont systemFontOfSize:12.0];
    self.currentTimeLabel.textAlignment = NSTextAlignmentRight;
    [self.bottomView addSubview:self.currentTimeLabel];
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomPlayButton.mas_right);
        make.centerY.equalTo(self.bottomPlayButton.mas_centerY);
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(60);
    }];
    //总时长
    self.totalTimeLabel = [[UILabel alloc]init];
    self.totalTimeLabel.textColor = [UIColor blackColor];
    self.totalTimeLabel.font = [UIFont systemFontOfSize:12.0];
    self.totalTimeLabel.textAlignment = NSTextAlignmentLeft;
    [self.bottomView addSubview:self.totalTimeLabel];
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomPlayButton.mas_centerY);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(25);
        make.right.equalTo(self.bottomView.mas_right).with.offset(-40);
    }];
    //缓存条
    self.loadedProgress = [[UIProgressView alloc]init];
    self.loadedProgress.layer.borderWidth = 0.5;
    self.loadedProgress.layer.cornerRadius = 2;
    self.loadedProgress.layer.borderColor = [UIColor blackColor].CGColor;
    self.loadedProgress.progressTintColor = [UIColor blackColor];
    [self.bottomView addSubview:self.loadedProgress];
    [self.loadedProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).with.offset(5);
        make.right.equalTo(self.totalTimeLabel.mas_left).with.offset(-5);
        make.centerY.equalTo(self.bottomPlayButton.mas_centerY);
        make.height.mas_equalTo(2.5);
    }];
    //进度条
    self.sliderView = [[UISlider alloc]init];
    self.sliderView.minimumValue = 0;
    self.sliderView.maximumValue = 1;
    self.sliderView.minimumTrackTintColor = [UIColor whiteColor];
    self.sliderView.maximumTrackTintColor = [UIColor clearColor];
    [self.sliderView addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.sliderView addTarget:self action:@selector(sliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.sliderView addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.bottomView addSubview:self.sliderView];
    [self.sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).with.offset(5);
        make.right.equalTo(self.totalTimeLabel.mas_left).with.offset(-5);
        make.centerY.equalTo(self.bottomPlayButton.mas_centerY);
        make.height.mas_equalTo(25);
    }];
    //旋转button  这里只切换全屏
    self.rotationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rotationButton setImage:[UIImage imageNamed:@"Rotation.png"] forState:UIControlStateNormal];
    [self.rotationButton addTarget:self action:@selector(fullScreenOrWindow:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.rotationButton];
    [self.rotationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.and.bottom.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    //设置初始值
    [self showTime:self.currentItem];
    [self showControlView];
}
//
//全屏模式下视频控制菜单
//
- (void)createControlViewFullScreen
{
    //顶部控制条
    self.topView = [[UIView alloc]init];
    self.topView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.7];
    [self addSubview:self.topView];
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.top.equalTo(self.mas_top);
        make.width.equalTo(self.mas_width);
        make.height.mas_equalTo(50);
    }];
    //提示文字
    self.tipLabel = [[UILabel alloc]init];
    self.tipLabel.alpha = 0;
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    self.tipLabel.numberOfLines = 0;
    self.tipLabel.font = [UIFont systemFontOfSize:10.0];
    [self addSubview:self.tipLabel];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topView.mas_centerX);
        make.bottom.equalTo(self.topView.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(200, 25));
    }];
    //完成按钮
    UIButton *completeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [completeButton setTitle:@"完成" forState:UIControlStateNormal];
    [completeButton addTarget:self action:@selector(completeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:completeButton];
    [completeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView.mas_left);
        make.top.equalTo(self.topView.mas_top).with.offset(20);
        make.size.mas_equalTo(CGSizeMake(60, 25));
    }];
    //当前时长
    self.currentTimeLabel = [[UILabel alloc]init];
    self.currentTimeLabel.textColor = [UIColor blackColor];
    self.currentTimeLabel.font = [UIFont systemFontOfSize:12.0];
    self.currentTimeLabel.textAlignment = NSTextAlignmentRight;
    [self.topView addSubview:self.currentTimeLabel];
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(completeButton.mas_right);
        make.centerY.equalTo(completeButton.mas_centerY);
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(60);
    }];
    //总时长
    self.totalTimeLabel = [[UILabel alloc]init];
    self.totalTimeLabel.textColor = [UIColor blackColor];
    self.totalTimeLabel.font = [UIFont systemFontOfSize:12.0];
    self.totalTimeLabel.textAlignment = NSTextAlignmentLeft;
    [self.topView addSubview:self.totalTimeLabel];
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(completeButton.mas_centerY);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(25);
        make.right.equalTo(self.topView.mas_right).with.offset(-60);
    }];
    //缓存条
    self.loadedProgress = [[UIProgressView alloc]init];
    self.loadedProgress.layer.borderWidth = 0.5;
    self.loadedProgress.layer.cornerRadius = 2;
    self.loadedProgress.layer.borderColor = [UIColor blackColor].CGColor;
    self.loadedProgress.progressTintColor = [UIColor blackColor];
    [self.topView addSubview:self.loadedProgress];
    [self.loadedProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).with.offset(5);
        make.right.equalTo(self.totalTimeLabel.mas_left).with.offset(-5);
        make.centerY.equalTo(completeButton.mas_centerY);
        make.height.mas_equalTo(2.5);
    }];
    //进度条
    self.sliderView = [[UISlider alloc]init];
    self.sliderView.minimumValue = 0;
    self.sliderView.maximumValue = 1;
    self.sliderView.continuous = YES;
    self.sliderView.minimumTrackTintColor = [UIColor whiteColor];
    self.sliderView.maximumTrackTintColor = [UIColor clearColor];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    pan.delegate = self;
    [self.sliderView addGestureRecognizer:pan];
    [self.sliderView addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.sliderView addTarget:self action:@selector(sliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.sliderView];
    [self.sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).with.offset(5);
        make.right.equalTo(self.totalTimeLabel.mas_left).with.offset(-5);
        make.centerY.equalTo(completeButton.mas_centerY);
        make.height.mas_equalTo(25);
    }];
    
    //全屏模式下底部控制条
    self.bottomView = [[UIView alloc]init];
    self.bottomView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.7];
    [self addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.bottom.equalTo(self.mas_bottom);
        make.width.equalTo(self.mas_width);
        make.height.mas_equalTo(40);
    }];
    //播放按钮
    self.bottomPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.bottomPlayButton setImage:[UIImage imageNamed:@"video_play.png"] forState:UIControlStateSelected];
    [self.bottomPlayButton setImage:[UIImage imageNamed:@"video_stop.png"] forState:UIControlStateNormal];
    [self.bottomPlayButton addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.bottomPlayButton];
    [self.bottomPlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView.mas_centerX);
        make.top.equalTo(self.bottomView.mas_top);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    //调整按钮状态
    if(self.player.rate == 0){//暂停状态，应显示play
        self.bottomPlayButton.selected = YES;
    }else{
        self.bottomPlayButton.selected = NO;
    }
    //后退
    UIButton *backwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backwardButton setImage:[UIImage imageNamed:@"video_backward.png"] forState:UIControlStateNormal];
    [backwardButton addTarget:self action:@selector(backwardButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:backwardButton];
    [backwardButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView.mas_centerX).with.offset(-70);
        make.top.equalTo(self.bottomView.mas_top);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    //前进
    UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [forwardButton setImage:[UIImage imageNamed:@"video_forward.png"] forState:UIControlStateNormal];
    [forwardButton addTarget:self action:@selector(forwardButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:forwardButton];
    [forwardButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView.mas_centerX).with.offset(70);
        make.top.equalTo(self.bottomView.mas_top);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    //    音量控制条
    self.volumeView = [[MPVolumeView alloc]init];
    self.volumeView.showsRouteButton = NO;
    for (UIView *view in [self.volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            UISlider *volumeViewSlider = (UISlider*)view;
            volumeViewSlider.minimumTrackTintColor = [UIColor whiteColor];
            volumeViewSlider.maximumTrackTintColor = [UIColor blackColor];
            break;
        }
    }
    [self.bottomView addSubview:self.volumeView];
    [self.volumeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView.mas_left).with.offset(15);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.bottomView.mas_bottom).with.offset(-10);
    }];
    //旋转button  这里只切换为窗口模式
    self.rotationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rotationButton setImage:[UIImage imageNamed:@"Rotation.png"] forState:UIControlStateNormal];
    [self.rotationButton addTarget:self action:@selector(fullScreenOrWindow:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.rotationButton];
    [self.rotationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.and.bottom.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    //设置初始值
    [self showTime:self.currentItem];
    [self showControlView];
}

//indicatorView
- (void)createCommonView{
    self.indicatorView = [[UIActivityIndicatorView alloc]init];
    self.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self addSubview:self.indicatorView];
    [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(25, 25));
    }];
    
    //中间播放按钮
    self.centerPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.centerPlayButton setImage:[UIImage imageNamed:@"Start.png"] forState:UIControlStateNormal];
    //这个按钮只会从窗口切换到全屏
    [self.centerPlayButton addTarget:self action:@selector(fullScreenOrWindow:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.centerPlayButton];
    self.centerPlayButton.hidden = YES;
    [self.centerPlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(60, 60));
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showOrHideControlView:)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
}

#
#pragma mark - 播放器初始化
#
- (void)playWithUrl:(NSURL *)url
{
    [self createPlayer:url];
    [self.indicatorView startAnimating];
    self.centerPlayButton.hidden = YES;
    _isFirst = YES;
}

//创建 player
- (void)createPlayer:(NSURL *)videoURL
{
    //创建Item,如果已经存在 移除监听
    if(self.currentItem){
        [self removeObserverFromPlayerItem:self.currentItem];
        self.currentItem = nil;
    }
    self.currentItem = [self createPlayerItem:videoURL];
    if(!_player){
        //创建player
        self.player = [[AVPlayer alloc]init];
        //创建layer并添加
        [self createPlayerLayer:self.player];
        //添加时间监听
        [self addTimeObserver];
    }
    
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
    //给item添加监听
    [self addObserverToPlayerItem:self.currentItem];
}

//创建 playerItem
- (AVPlayerItem *)createPlayerItem:(NSURL *)videoURL
{
    AVPlayerItem *item = [[AVPlayerItem alloc]initWithURL:videoURL];
    return item;
}

//创建 playerLayer
- (void)createPlayerLayer:(AVPlayer *)player
{
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    _playerLayer.frame = self.bounds;
    _playerLayer.backgroundColor = [UIColor clearColor].CGColor;
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer insertSublayer:_playerLayer atIndex:0];
}

/**
 给item添加监听
 */
- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem
{
    __weak JANPlayerView *weakSelf = self;
    //状态
    [playerItem addObserver:weakSelf forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //缓存进度
    [playerItem addObserver:weakSelf forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

/**
 移除item监听
 */
- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem
{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

/**
 添加播放时间监听
 */
- (void)addTimeObserver
{
    __weak JANPlayerView *weakSelf = self;
    _playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:NULL usingBlock:^(CMTime time) {
        if(weakSelf.isSliding == NO)
        {
            [weakSelf showTime:weakSelf.currentItem];
        }
    }];
}
/**
 设置时间，进度条的值
 */
- (void)showTime:(AVPlayerItem *)playerItem
{
    CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;
    self.currentTimeLabel.text = [self timeformatFromSeconds:currentSecond];
    self.sliderView.value = currentSecond/_totalTime;
    
    NSString *totalTimeString = [self timeformatFromSeconds:(_totalTime - currentSecond)];
    self.totalTimeLabel.text = [NSString stringWithFormat:@"-%@",totalTimeString];
}
/**
 item监听变化处理
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if([keyPath isEqualToString:@"status"]){
        
        [self handleStatusWithPlayerItem:playerItem];
        
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
        [self handleLoadedTimeRangesWithPlayerItem:playerItem];
        
    }
}

/**
 处理item状态
 */
- (void)handleStatusWithPlayerItem:(AVPlayerItem *)item
{
    AVPlayerItemStatus status = item.status;
    switch (status) {
        case AVPlayerItemStatusReadyToPlay:
            // 准备好播放
            NSLog(@"AVPlayerItemStatusReadyToPlay");
            [self.player play];
            //获取视频总时长
            _totalTime = item.duration.value/item.duration.timescale;
            if(_isFirst){
                [self fullScreenOrWindow:nil];
                _isFirst = NO;
            }
            [self.indicatorView stopAnimating];
            break;
        case AVPlayerItemStatusFailed:
            
            // 播放出错
            NSLog(@"AVPlayerItemStatusFailed");
            
            break;
        case AVPlayerItemStatusUnknown:
            
            // 状态未知
            NSLog(@"AVPlayerItemStatusUnknown");
            break;
            
        default:
            break;
    }
}

/**
 处理缓存进度
 */
- (void)handleLoadedTimeRangesWithPlayerItem:(AVPlayerItem *)item
{
    NSArray *loadArray = item.loadedTimeRanges;
    // CMTimeRange 结构体 start duration 表示起始位置 和 持续时间
    CMTimeRange range = [[loadArray firstObject] CMTimeRangeValue];
    float start = CMTimeGetSeconds(range.start);
    float duration = CMTimeGetSeconds(range.duration);
    // 缓存总长度
    NSTimeInterval totalTime = start + duration;
    self.loadedProgress.progress = totalTime/_totalTime;
}

#pragma mark - 控制事件

/**
 播放/暂停
 avplayer自身有一个rate属性
 rate ==1.0，表示正在播放；rate == 0.0，暂停；rate == -1.0，播放失败
 */
- (void)playOrPause:(UIButton *)button
{
    if(self.player.rate == 0)
    {
        [self performSelector:@selector(hideControlView) withObject:nil afterDelay:5];
        [self.player play];
        button.selected = NO;
    }else if(self.player.rate == 1.0)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
        [self.player pause];
        button.selected = YES;
    }else{
        NSLog(@"播放出错！");
    }
}

/**
 拖拽进度
 */

//按下
- (void)sliderTouchDown:(UISlider *)slider
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    [self.player pause];
    _isSliding = YES;
    if(_isFullScreen){
        [self.topView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(50 + 25);
        }];
        //控制提示文字与布局
        [UIView animateWithDuration:0.25 animations:^{
            self.tipLabel.alpha = 1;
            self.tipLabel.text = @"手指向下滑动来调整进退速度。\n高速进退";
            [self layoutIfNeeded];
        }];
    }
}
//滑动结束
- (void)sliderTouchUpInside:(UISlider *)slider
{
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:5];
    [self.player play];
    _isSliding = NO; // 滑动结束
    if(_isFullScreen)
    {
        [self.topView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(50);
        }];
        //控制提示文字与布局
        [UIView animateWithDuration:0.25 animations:^{
            self.tipLabel.alpha = 0;
            [self layoutIfNeeded];
        }completion:^(BOOL finished) {
            self.tipLabel.text = @"";
        }];
    }
}
- (void)sliderValueChange:(UISlider *)slider
{
    if(_isFullScreen){
        return;
    }
    // 跳转到拖拽秒处
    CMTime changedTime = CMTimeMakeWithSeconds(self.sliderView.value*self.totalTime, 1.0);
    [self.currentItem seekToTime:changedTime completionHandler:^(BOOL finished) {
        // 跳转完成后
    }];
}
//控制快慢
- (void)panAction:(UIPanGestureRecognizer *)pan
{
    if(_isSliding)
    {
        changePoint = [pan locationInView:self.sliderView];
        if(pan.state == UIGestureRecognizerStateBegan)
        {
            startPoint = [pan locationInView:self.sliderView];
        }
        else if(pan.state == UIGestureRecognizerStateChanged)
        {
            if(changePoint.y < 70){//高速进退
                self.tipLabel.text = @"手指向下滑动来调整进退速度。\n高速进退";
                //调整进度
                self.sliderView.value += (changePoint.x - startPoint.x)/self.sliderView.frame.size.width;
                //向手指方向靠近
                if(changePoint.x/self.sliderView.frame.size.width > self.sliderView.value + 0.05)
                {
                    self.sliderView.value += 0.02;
                }else if(changePoint.x/self.sliderView.frame.size.width < self.sliderView.value - 0.05){
                    self.sliderView.value -= 0.02;
                }
            }else if(changePoint.y < 140){//半速进退
                self.tipLabel.text = @"手指向下滑动来调整进退速度。\n半速进退";
                //调整进度
                self.sliderView.value += (changePoint.x - startPoint.x)/self.sliderView.frame.size.width/2;
                //向手指方向靠近
                if(changePoint.x/self.sliderView.frame.size.width > self.sliderView.value)
                {
                    self.sliderView.value += 0.005;
                }else{
                    self.sliderView.value -= 0.005;
                }
            }else if(changePoint.y < 210){//四分之一速度进退
                self.tipLabel.text = @"手指向下滑动来调整进退速度。\n四分之一速度进退";
                //调整进度
                self.sliderView.value += (changePoint.x - startPoint.x)/self.sliderView.frame.size.width/4;
                //向手指方向靠近
                if(changePoint.x/self.sliderView.frame.size.width > self.sliderView.value)
                {
                    self.sliderView.value += 0.001;
                }else{
                    self.sliderView.value -= 0.001;
                }
            }else{//慢速进退
                self.tipLabel.text = @"手指向下滑动来调整进退速度。\n慢速进退";
                self.sliderView.value += (changePoint.x - startPoint.x)/self.sliderView.frame.size.width/8;
            }
            // 跳转到拖拽秒处
            CMTime changedTime = CMTimeMakeWithSeconds(self.sliderView.value*self.totalTime, 1.0);
            [self.currentItem seekToTime:changedTime completionHandler:^(BOOL finished) {
                // 跳转完成后
            }];
            startPoint = [pan locationInView:self.sliderView];
        }
        else if(pan.state == UIGestureRecognizerStateEnded)
        {
            [self sliderTouchUpInside:self.sliderView];
        }
    }
}

/**
 全屏/窗口切换
 */
- (void)fullScreenOrWindow:(UIButton *)button
{
    //移除控制条
    if(self.bottomView)
    {
        [self.bottomView removeFromSuperview];
    }
    if(self.topView)
    {
        [self.topView removeFromSuperview];
    }
    if(_isFullScreen)
    {
        if(self.player.rate == 0){
            //暂停状态下 缩小为窗口模式 逻辑与点击完成按钮一致
            [self completeButtonClick:nil];
            return;
        }
        [UIView animateWithDuration:0.25 animations:^{
            [self setFullscreen:NO];
            self.isFullScreen = NO;
            self.frame = self.windowRect;
        }completion:^(BOOL finished) {
            self.frame = self.initFrame;
            [self.windowSuperView addSubview:self];
            [self createControlViewOnWindow];
        }];
    }else{
        //如果点击的是centerPlayerButton来切换全屏，此时肯定是在暂停状态下，应该隐藏centerPlayerButton 并且播放
        if(button == self.centerPlayButton){
            [self.player play];
            self.centerPlayButton.hidden = YES;
        }
        self.windowSuperView = self.superview;
        self.frame = self.windowRect;
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
        [UIView animateWithDuration:0.25 animations:^{
            self.isFullScreen = YES;
            [self setFullscreen:YES];
            self.frame = [UIScreen mainScreen].bounds;
        }completion:^(BOOL finished) {
            [self createControlViewFullScreen];
        }];
    }
}
/**
 点击完成，屏幕变为窗口模式
 */
- (void)completeButtonClick:(UIButton *)button
{
    //移除控制条
    if(self.bottomView)
    {
        [self.bottomView removeFromSuperview];
    }
    if(self.topView)
    {
        [self.topView removeFromSuperview];
    }
    //如果在播放中， 暂停并缩小为窗口模式
    if(self.player.rate == 1.0){
        [self.player pause];
    }
    [UIView animateWithDuration:0.25 animations:^{
        [self setFullscreen:NO];
        self.isFullScreen = NO;
        self.frame = self.windowRect;
    }completion:^(BOOL finished) {
        self.frame = self.initFrame;
        [self.windowSuperView addSubview:self];
        self.centerPlayButton.hidden = NO;
    }];
}
//后退
- (void)backwardButtonClick:(UIButton *)button
{
    
}
//前进
- (void)forwardButtonClick:(UIButton *)button
{
    
}

#pragma mark - 其他
//时间转换
- (NSString*)timeformatFromSeconds:(NSInteger)seconds
{
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%2ld",seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%2ld",(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    //format of time
    if(seconds >= 3600)
    {
        NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
        return format_time;
    }else
    {
        NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
        return format_time;
    }
}

#pragma mark - 横竖屏布局

- (void)layoutSubviews {
    [super layoutSubviews];
    _playerLayer.frame = self.bounds;
}
//横竖屏通知
- (void)doRotateAction:(NSNotification *)notification {
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait) {
        NSLog(@"竖屏");
        if(self.bottomView.superview && self.topView.superview){
            NSLog(@"布局");
            [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(70);
            }];
            [self.volumeView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.bottomView.mas_left).with.offset(15);
                make.right.equalTo(self.bottomView.mas_right).with.offset(-55);
                make.bottom.equalTo(self.bottomView.mas_bottom).with.offset(-10);
                make.height.mas_equalTo(20);
            }];
        }
    } else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        NSLog(@"横屏");
        if(self.bottomView.superview && self.topView.superview){
            NSLog(@"布局");
            [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(40);
            }];
            [self.volumeView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.bottomView.mas_left).with.offset(15);
                make.width.mas_equalTo(200);
                make.height.mas_equalTo(20);
                make.bottom.equalTo(self.bottomView.mas_bottom).with.offset(-10);
            }];
        }
    }
}
//强制横竖屏
- (void)setFullscreen:(BOOL)fullscreen
{
    if (fullscreen) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationLandscapeRight;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
    }else{
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationPortrait;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
    }
}

//事件过滤
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //防止在slider上的tap事件阻碍 slider事件 或者 slider上的pan手势
    if([touch.view isKindOfClass:[UISlider class]] && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        return NO;
    }
    return YES;
}
- (void)showOrHideControlView:(UITapGestureRecognizer *)tap
{
    if(_isShowControlView){
        [self hideControlView];
    }else{
        [self showControlView];
    }
}
//隐藏控制条
- (void)hideControlView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showControlView) object:nil];
    [UIView animateWithDuration:0.3 animations:^{
        if(self.bottomView)
        {
            self.bottomView.alpha = 0;
        }
        if(self.topView)
        {
            self.topView.alpha = 0;
        }
    }];
    _isShowControlView = NO;
}
//显示控制条
- (void)showControlView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    [UIView animateWithDuration:0.3 animations:^{
        if(self.bottomView)
        {
            self.bottomView.alpha = 1;
        }
        if(self.topView)
        {
            self.topView.alpha = 1;
        }
    }completion:^(BOOL finished) {
        //在播放状态下才会隐藏控制条
        if(self.bottomPlayButton.selected == NO)
        {
            [self performSelector:@selector(hideControlView) withObject:nil afterDelay:5];
        }
    }];
   
    _isShowControlView = YES;
}


- (void)removePlayer
{
    [self.player removeTimeObserver:_playerTimeObserver];
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.player = nil;
}

- (void)dealloc{
    [self removePlayer];
    [self removeObserverFromPlayerItem:self.currentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"-----playerViewDealloc-----");
}
@end
