//
//  ZRMoviePlayerController.m
//  TakeVideos
//
//  Created by VictorZhang on 20/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRVideoPlayerController.h"
#import <AVFoundation/AVFoundation.h>


#define ZRVideoPlayerButtonDiameter           70
#define ZRVideoPlayerButtonCircleDiameter     (ZRVideoPlayerButtonDiameter + 2)


@interface ZRCircleProgressView : UIView

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, strong) CAShapeLayer *spLayer;

@end

@implementation ZRCircleProgressView

- (void)drawProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (CAShapeLayer *)spLayer
{
    if (!_spLayer) {
        _spLayer = [CAShapeLayer layer];
        [self.layer addSublayer:self.spLayer];
    }
    return _spLayer;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat circleWidth = ZRVideoPlayerButtonCircleDiameter;
//    CGFloat circleHeight = circleWidth;
    CGRect circleRect = CGRectMake(0, 0, circleWidth, circleWidth);

    //画圆形
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    UIBezierPath *circleBezier = [UIBezierPath bezierPathWithOvalInRect:circleRect];
    
    if (_progress == 0.0) { //等于0时，就删掉这个圆形进度条
        [self.spLayer removeFromSuperlayer];
        self.spLayer = nil;
    } else {
        self.spLayer.frame = circleRect;
        self.spLayer.position = center;
        self.spLayer.strokeStart = 0.0f;//路径开始位置
        self.spLayer.strokeEnd = _progress;//路径结束位置
        self.spLayer.fillColor = [UIColor clearColor].CGColor;//填充颜色
        self.spLayer.strokeColor = [UIColor whiteColor].CGColor;//绘制线条颜色
        self.spLayer.lineWidth = 8.f;
        self.spLayer.lineCap = kCALineCapRound;
        self.spLayer.path = circleBezier.CGPath;
    }
//    
//    
//    CAGradientLayer *colorLayer = [CAGradientLayer layer];
//    colorLayer.backgroundColor = [UIColor blueColor].CGColor;
//    colorLayer.frame    = circleRect;
//    colorLayer.position = center;
//    [self.layer addSublayer:colorLayer];
    
}


@end



@interface ZRVideoPlayerController ()

@property (nonatomic, strong) NSURL *url;

@property (nonatomic,strong) AVPlayer *player;    //播放器对象

@property (nonatomic, strong) UIImageView *playingImg;

@property (nonatomic, assign) NSTimeInterval videoTotalLength; //视频总长度

@property (nonatomic, strong) id periodicTimeObserver;

@property (nonatomic, strong) ZRCircleProgressView *progressView;


@end

@implementation ZRVideoPlayerController

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self calculateVideoSize];
    [self setupPlayer];
    [self setupUI];
}

- (void)setupPlayer {
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.url];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.view.frame;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    [self observeToPlayerItems];
    [self addNotification];
    [self addProgressObserver];
}

- (void)replaceCurrentPlayerItem:(NSURL *)replacedUrl {
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:replacedUrl];
//    [self.player replaceCurrentItemWithPlayerItem:playerItem];
//    
//    [self addObservers];
}

- (void)setupUI {
    CGRect viewFrame = self.view.frame;
    
    //背景
    CGFloat btViewHeight = 120;
    UIView * bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, viewFrame.size.height - btViewHeight, viewFrame.size.width, btViewHeight)];
    bottomView.backgroundColor = [UIColor clearColor];
    bottomView.hidden = YES;
    [self.view addSubview:bottomView];
    
    CGFloat btnWidth = ZRVideoPlayerButtonDiameter;
    CGFloat btnHeight = btnWidth;
    CGFloat leftMargin = (viewFrame.size.width - (btnWidth * 3)) / 4;
    CGFloat topMargin = 10;
    CGFloat btnX = leftMargin;
    
    //重拍
    UIView *retakeBtn = [self getButtonWithFrame:CGRectMake(btnX, topMargin, btnWidth, btnHeight) image:@"zr_retaking_video" type:1];
    [retakeBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retakeVideo)]];
    [bottomView addSubview:retakeBtn];
    
    //播放
    btnX = leftMargin * 2 + btnWidth;
    UIView *playBtn = [self getButtonWithFrame:CGRectMake(btnX, topMargin, btnWidth, btnHeight) image:@"zr_video_play" type:2];
    [playBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playVideo)]];
    [bottomView addSubview:playBtn];
    
    if (!self.playVideOnly) {
        //确定
        btnX = leftMargin * 3 + btnWidth * 2;
        UIView *okBtn = [self getButtonWithFrame:CGRectMake(btnX, topMargin, btnWidth, btnHeight) image:@"zr_video_selection" type:3];
        [okBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(choseVideo)]];
        [bottomView addSubview:okBtn];
    }
    
    //播放视频进度条
    CGRect circlePView = playBtn.frame;
    CGFloat circleViewWidth = circlePView.size.width + 8;
    CGFloat circleViewX = (viewFrame.size.width - circleViewWidth) / 2;
    CGFloat circleViewY = topMargin - 4;
    ZRCircleProgressView *progressView = [[ZRCircleProgressView alloc] init];
    progressView.frame = CGRectMake(circleViewX, circleViewY, circleViewWidth, circleViewWidth);
    progressView.backgroundColor = [UIColor clearColor];
    _progressView = progressView;
    [bottomView insertSubview:progressView belowSubview:playBtn];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        bottomView.hidden = NO;
    });
}

- (UIView *)getButtonWithFrame:(CGRect)frame image:(NSString *)imageName type:(int)type {
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.layer.cornerRadius = 35;
    
    CGRect subFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    
    if ([[UIDevice currentDevice].systemVersion floatValue] > 8.0) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.frame = subFrame;
        effectView.layer.cornerRadius = 35;
        effectView.layer.masksToBounds = YES;
        [view addSubview:effectView];

        if (type == 3) {
            UIView *bg = [[UIView alloc] initWithFrame:subFrame];
            bg.backgroundColor = [UIColor whiteColor];
            bg.layer.cornerRadius = 35;
            bg.alpha = 0.5f;
            [view addSubview:bg];
        }
    } else {
        UIView *bg = [[UIView alloc] initWithFrame:subFrame];
        if (type == 1 || type == 3) {
            bg.backgroundColor = [UIColor whiteColor];
        } else {
            bg.backgroundColor = [UIColor blackColor];
        }
        bg.layer.cornerRadius = 35;
        bg.alpha = 0.6f;
        [view addSubview:bg];
    }
    
    UIImageView *img = [[UIImageView alloc] initWithFrame:subFrame];
    img.image = [UIImage imageNamed:imageName];
    img.layer.cornerRadius = 35;
    [view addSubview:img];
    
    if (type == 2) {
        self.playingImg = img;
    }
    
    return view;
}

- (void)retakeVideo {
    [self videoPausedWhenPlaying];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    if ([self.videoPlayerDelegate respondsToSelector:@selector(videoPlayerWithRetakingVideo)]) {
        [self.videoPlayerDelegate videoPlayerWithRetakingVideo];
    }
}

- (void)playVideo { 
    if (self.player.rate == 0) {
        [self.player play];
        
        [self setVideoPausedImg:YES];
    } else {
        [self videoPausedWhenPlaying];
    }
}

- (void)choseVideo {
    [self videoPausedWhenPlaying];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    if ([self.videoPlayerDelegate respondsToSelector:@selector(videoPlayerWithChoseVideo:videoInterval:)]) {
        [self.videoPlayerDelegate videoPlayerWithChoseVideo:self.url videoInterval:self.videoTotalLength];
    }
}

- (void)setVideoPausedImg:(BOOL)isPaused {
    if (isPaused) {
        self.playingImg.image = [UIImage imageNamed:@"zr_video_play_paused"];
    } else {
        self.playingImg.image = [UIImage imageNamed:@"zr_video_play"];
    }
}

- (void)videoPausedWhenPlaying {
    [self.player pause];
    [self setVideoPausedImg:NO];
}

// 给播放器添加进度更新
- (void)addProgressObserver{
    
    __weak typeof(self) SELF = self;
    self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([SELF.player.currentItem duration]);
        float rate = current / total;
        NSLog(@"当前已经播放:%.5fs  播放比例:%.5fs.",current, rate);
        if (current) {
            [SELF.progressView drawProgress:rate];
        }
    }];
}

#pragma mark - Notification
- (void)playbackFinished:(NSNotification *)notification{
    NSLog(@"视频播放完成.");
    [self videoPausedWhenPlaying];
    [self.progressView drawProgress:0.0f];
    [self.player.currentItem seekToTime:kCMTimeZero];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeToPlayerItems {
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObservers {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    
    if (self.periodicTimeObserver) {
        [self.player removeTimeObserver:self.periodicTimeObserver];
        self.periodicTimeObserver = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay){
            NSLog(@"视频总长度:%.5f", CMTimeGetSeconds(playerItem.duration));
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        self.videoTotalLength = totalBuffer;
        NSLog(@"视频共缓冲：%.2f",totalBuffer);
    }
}

- (void)calculateVideoSize {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError * error;
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    int random = arc4random() % 10000001;
    NSString *filename = [NSString stringWithFormat:@"%@/%d.mp4", path, random];
    
    BOOL success = [fileManager copyItemAtURL:self.url toURL:[NSURL fileURLWithPath:filename isDirectory:NO] error:&error];
    if (!success) {
        success = [fileManager copyItemAtPath:self.url.absoluteString toPath:filename error:&error];
    }
    NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:filename error:&error];
    long fileSize = [[fileAttr objectForKey:NSFileSize] longValue];
    NSString *bytes = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
    float fileMB = fileSize / 1024.0 / 1024.0;
    NSLog(@"fileMB = %lf   bytes=%@", fileMB, bytes);
}

- (void)dealloc
{
    [self removeObservers];
    [self removeNotification];
    NSLog(@"ZRVideoPlayerController has been deallocated!");
}

@end
