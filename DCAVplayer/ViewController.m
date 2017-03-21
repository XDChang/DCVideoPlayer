//
//  ViewController.m
//  DCAVplayer
//
//  Created by XDChang on 17/3/16.
//  Copyright © 2017年 XDChang. All rights reserved.
//

#import "ViewController.h"
#import "DCRotatingWheel.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<DCRotatingWheelDelegate>
{
    id _playTimeObserver; // 观察者
    BOOL _play;           // 记录播放状态
    BOOL _isSlider;       // 记录滑动状态

}
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerItem *item;
@property (weak, nonatomic) IBOutlet UISlider *mp4Slider; // sliderView,播放进度
@property (weak, nonatomic) IBOutlet UIProgressView *progressView; // 缓冲进度
@property (weak, nonatomic) IBOutlet UILabel *startTime;  // 记录已经播放的时间
@property (weak, nonatomic) IBOutlet UILabel *endTime;    // 记录视频总时长
@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _play = YES;
    _isSlider = NO;
    // 创建慢放滚轮，并绑定其三个状态的方法
    DCRotatingWheel *control = [[DCRotatingWheel alloc]initWithFrame:CGRectMake(40, 340, self.view.frame.size.width-80, 50)];
    
    control.delegate = self; // 设置惯性代理
    
    [control addTarget:self action:@selector(onControlTouchDown:) forControlEvents:UIControlEventTouchDown];
    [control addTarget:self action:@selector(onControlTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    [control addTarget:self action:@selector(onControlValueChange:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:control];
    
    // 视频播放地址是网络提供的，视频短，就一分钟。建议自己加个长点的视频。

    NSString *urlStr = @"https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
//    NSString *urlStr = @"http://zyvideo1.oss-cn-qingdao.aliyuncs.com/zyvd/7c/de/04ec95f4fd42d9d01f63b9683ad0";
//    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"xiujian2" ofType:@"mp4"];
   
//    NSURL *url = [NSURL fileURLWithPath:filePath];

    NSURL *mp4Url = [NSURL URLWithString:urlStr];
    
    self.item = [[AVPlayerItem alloc]initWithURL:mp4Url];
    
    
    // 注册观察者,观察status属性
    [_item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 观察缓冲进度
    [_item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    self.player = [[AVPlayer alloc]initWithPlayerItem:_item];
    
    
    AVPlayerLayer *avLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    
    avLayer.frame = CGRectMake(0, 70, self.view.frame.size.width, 180);
    
    avLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.view.layer addSublayer:avLayer];
    
    // 观察播放进度
    [self monitoringPlayBack:_item];
    
    
}

// 移除通知
- (void)dealloc
{
    [_player replaceCurrentItemWithPlayerItem:nil];
    [_item removeObserver:self forKeyPath:@"status"];
    [_item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_player removeTimeObserver:_playTimeObserver];
    _playTimeObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
// 观察status属性
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerStatus status = [[change objectForKey:@"new"]integerValue];
        // 准备播放
        if (status == AVPlayerStatusReadyToPlay) {
            
            CMTime duration = _item.duration;
            
            NSLog(@"sssss%.2f", CMTimeGetSeconds(duration));
            
            // 设置视频时间
            [self setMaxDuration:CMTimeGetSeconds(duration)];
            
            [self.player play];
            
        }// 播放视频失败
        else if (status == AVPlayerStatusFailed)
        {
        
            NSLog(@"AVPlayerStatusFailed");
        }
        else {
        
            NSLog(@"AVPlayerStatusUnknown");
        }
        // 缓冲进度
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
    
    
        NSTimeInterval timeInterval = [self availableDurationRanges];
        
        CGFloat totalDuration = CMTimeGetSeconds(_item.duration); // 总时间
        
        [self.progressView setProgress:timeInterval / totalDuration animated:YES];
    
    }
}


// 观察播放进度
- (void)monitoringPlayBack:(AVPlayerItem *)item {

    __weak typeof(self)WeekSelf = self;
    
    // 播放进度, 每秒执行30次， CMTime 为30分之一秒
    _playTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        // 当前播放秒
        float currentPlayTime = (double)item.currentTime.value/ item.currentTime.timescale;
        // 更新播放进度Slider
        [WeekSelf updateVideoSlider:currentPlayTime];
        
    }];
}
// 更新滑条
- (void)updateVideoSlider:(float)currentTime {
    self.mp4Slider.value = currentTime;
    self.startTime.text = [self convertTime:currentTime];
}

// 已缓冲进度
- (NSTimeInterval)availableDurationRanges {
    NSArray *loadedTimeRanges = [_item loadedTimeRanges]; // 获取item的缓冲数组

    // CMTimeRange 结构体 start duration 表示起始位置 和 持续时间
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds; // 计算总缓冲时间 = start + duration
    return result;
}
// 设置最大时间
- (void)setMaxDuration:(CGFloat)duration {

    self.mp4Slider.maximumValue = duration;
    
    self.endTime.text = [self convertTime:duration];

}
// 视频播放完毕
- (void)playbackFinished:(NSNotification *)notification {
    
    _play = NO;
    [self setPlayBtnImage];
    
    _item = [notification object];
    // 是否无限循环
    [_item seekToTime:kCMTimeZero]; // 跳转到初始
    //    [_player play]; // 是否无限循环
}

#pragma mark --- slider 三个状态所绑定的方法
- (IBAction)TouchUpInside:(UISlider *)sender {
    
    [self.player play];
    
    _play = YES;
    [self setPlayBtnImage];
}

- (IBAction)TouchDown:(id)sender {
    
    [self.player pause];
    
    _play = NO;
    [self setPlayBtnImage];
}

- (IBAction)ValueChange:(id)sender {
    
    [self.player pause];
    
    _play = NO;
    [self setPlayBtnImage];
    
    CMTime changeTime = CMTimeMakeWithSeconds(self.mp4Slider.value,1.0);
    
    NSLog(@"%.2f", self.mp4Slider.value);
    
    [_item seekToTime:changeTime completionHandler:^(BOOL finished) {
        
//        [self.player play];
        
    }];
    
}

// 设置按钮
- (IBAction)onSetBtnClick:(id)sender {
    
}
// 播放按钮
- (IBAction)PlayOrDisplay:(id)sender {
    
    _play == YES? [self.player pause]:[self.player play];
    
    _play = !_play;
    
    [self setPlayBtnImage];
    
}
// 全屏按钮
- (IBAction)FullScreen:(id)sender {
    
    
    
}
#pragma mark --- DCRotatingWheel 三个状态绑定的方法
- (void)onControlTouchDown:(DCRotatingWheel *)col
{
    [self.player pause];
    
    _play = NO;
    
    [self setPlayBtnImage];
    
}

- (void)onControlTouchUpInside:(DCRotatingWheel *)col
{

    [self.player play];
    _play = YES;
    [self setPlayBtnImage];
}

- (void)onControlValueChange:(DCRotatingWheel *)col
{
    [self.player pause];
    _play = NO;
    [self setPlayBtnImage];
    
    float currentTime = self.mp4Slider.value+(col.value*0.1 );// 滚轮的拨动距离乘以系数，来控制进度（0.5）
    if (currentTime > 0) {
        
        CMTime changeTime = CMTimeMakeWithSeconds(currentTime,1.0);
        
        [self updateVideoSlider:currentTime];
        
        NSLog(@"%.2f", self.mp4Slider.value);
        
        [_item seekToTime:changeTime completionHandler:^(BOOL finished) {
            
        }];
    }
}
/*!
 @method  慢放滚轮的惯性代理方法。
 @abstract 慢放滚轮的惯性代理方法。
 @param value 每次滚动的值

 */
- (void)onDCRotatingWheelDelegateInertanceEventWithValue:(float)value
{
    float currentTime = self.mp4Slider.value+(value*0.1 );// 滚轮的拨动距离乘以系数，来控制进度（0.5）
    
    if (currentTime > 0) {
        
        CMTime changeTime = CMTimeMakeWithSeconds(currentTime,1.0);
        
        
        [self updateVideoSlider:currentTime];
        
        NSLog(@"%.2f", self.mp4Slider.value);
        
        
        [_item seekToTime:changeTime completionHandler:^(BOOL finished) {
            
            
        }];

    }
    
}


/*!
 @method  设置播放按钮图标。
 @discussion 根据播放状态设置按钮图标，用三元运算符实现。
 
 */
- (void)setPlayBtnImage
{
    
    [self.playBtn setImage:[UIImage imageNamed: _play==NO ? @"Play.png":@"Stop.png"] forState:UIControlStateNormal];

}
/*!
 @method  计算视频时间。
 @discussion 根据传入的视频时间戳，换算成时间段。
 @param second 秒数
 
 */
- (NSString *)convertTime:(CGFloat)second {
    // 相对格林时间
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    if (second / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    
    NSString *showTimeNew = [formatter stringFromDate:date];
    return showTimeNew;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
