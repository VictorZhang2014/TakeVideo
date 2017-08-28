//
//  ZRMediaCaptureView.m
//  TakeVideos
//
//  Created by VictorZhang on 14/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRMediaCaptureView.h"


@interface ZRDownArrow : UIView

@end

@implementation ZRDownArrow

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, 40, 20);
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetRGBStrokeColor(context, 255, 255, 255, 1.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 20, 20);
    CGContextAddLineToPoint(context, 40, 0);
    CGContextStrokePath(context); 
}

@end


@interface ZRMediaCaptureView()

@property (nonatomic, assign, getter=isCapturing) BOOL capture;

@property (nonatomic, strong) UIButton *captureButton;

@property (nonatomic, strong) UILabel *timerLabel;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) int timerSeconds;

@property (nonatomic, strong) UIButton *cameraBtnSwitch;

@property (nonatomic, strong) UIButton *flashLightBtn;

@property (nonatomic, strong) ZRDownArrow *downArrowForDismiss;
@property (nonatomic, strong) UIButton *dismissButton;

@end

@implementation ZRMediaCaptureView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        
        //切换前/后摄像头
        UIButton *btnSwitch = [[UIButton alloc] init];
        btnSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        [btnSwitch addTarget:self action:@selector(cameraSwitchAlternativelyRearOrFront) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnSwitch];
        self.cameraBtnSwitch = btnSwitch;
        NSDictionary *btncameraDic = NSDictionaryOfVariableBindings(btnSwitch);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[btnSwitch(==55)]-(20)-|" options:0 metrics:nil views:btncameraDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(25)-[btnSwitch(==55)]" options:0 metrics:nil views:btncameraDic]];
        
        UIImageView *cameraSwitch = [[UIImageView alloc] init];
        cameraSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        cameraSwitch.image = [UIImage imageNamed:@"zr_camera_switch"];
        [btnSwitch addSubview:cameraSwitch];
        NSDictionary *cameraDic = NSDictionaryOfVariableBindings(cameraSwitch);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[cameraSwitch(==40)]-(0)-|" options:0 metrics:nil views:cameraDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[cameraSwitch(==40)]" options:0 metrics:nil views:cameraDic]];
        
        //计时显示
        UIView *timerView = [[UIView alloc] init];
        timerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:timerView];
        
        UIView *timerbg = [[UIView alloc] init];
        timerbg.translatesAutoresizingMaskIntoConstraints = NO;
        timerbg.backgroundColor = [UIColor blackColor];
        timerbg.alpha = 0.4f;
        timerbg.layer.cornerRadius = 3;
        [timerView addSubview:timerbg];
        
        UILabel *timerLabel = [[UILabel alloc] init];
        timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        timerLabel.text = @"00:00:00";
        timerLabel.textAlignment = NSTextAlignmentCenter;
        timerLabel.textColor = [UIColor whiteColor];
        timerLabel.font = [UIFont systemFontOfSize:20];
        timerLabel.backgroundColor = [UIColor clearColor];
        [timerView addSubview:timerLabel];
        _timerLabel = timerLabel;
        
        NSDictionary *timerDic = NSDictionaryOfVariableBindings(timerView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[timerView(==100)]" options:0 metrics:nil views:timerDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[timerView(==25)]-(120)-|" options:0 metrics:nil views:timerDic]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:timerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        
        NSDictionary *timerbgDic = NSDictionaryOfVariableBindings(timerbg);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[timerbg]|" options:0 metrics:nil views:timerbgDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[timerbg]|" options:0 metrics:nil views:timerbgDic]];
        
        NSDictionary *timerlabelDic = NSDictionaryOfVariableBindings(timerLabel);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[timerLabel]|" options:0 metrics:nil views:timerlabelDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[timerLabel]|" options:0 metrics:nil views:timerlabelDic]];
        
        //背景
        UIView * bottomView = [[UIView alloc] init];
        bottomView.backgroundColor = [UIColor blackColor];
        bottomView.translatesAutoresizingMaskIntoConstraints = NO;
        bottomView.alpha = 0.f;
        [self addSubview:bottomView];
        NSDictionary *viewsDic = NSDictionaryOfVariableBindings(bottomView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[bottomView]-(0)-|" options:0 metrics:nil views:viewsDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomView(==120)]-(0)-|" options:0 metrics:nil views:viewsDic]];
        
        //关闭视图
        ZRDownArrow * downArrow = [[ZRDownArrow alloc] init];
        _downArrowForDismiss = downArrow;
        UIView *cancelView = [[UIView alloc] init];
        cancelView.translatesAutoresizingMaskIntoConstraints = NO;
        cancelView.backgroundColor = [UIColor clearColor];
        [cancelView addSubview:downArrow];
        [self addSubview:cancelView];
        NSDictionary *cancelDic = NSDictionaryOfVariableBindings(cancelView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(30)-[cancelView(==40)]" options:0 metrics:nil views:cancelDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[cancelView(==20)]-(45)-|" options:0 metrics:nil views:cancelDic]];
        
        //关闭按钮
        UIButton *cancelBtn = [[UIButton alloc] init];
        cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [cancelBtn addTarget:self action:@selector(cancelTakingVideo) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancelBtn];
        _dismissButton = cancelBtn;
        NSDictionary *cancelBtnDic = NSDictionaryOfVariableBindings(cancelBtn);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(30)-[cancelBtn(==70)]" options:0 metrics:nil views:cancelBtnDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[cancelBtn(==50)]-(30)-|" options:0 metrics:nil views:cancelBtnDic]];
        
        //拍摄按钮
        UIButton *takeVideoBtn = [[UIButton alloc] init];
        takeVideoBtn.translatesAutoresizingMaskIntoConstraints = NO;
        takeVideoBtn.layer.cornerRadius = 35;
        takeVideoBtn.layer.borderWidth = 6;
        [takeVideoBtn addTarget:self action:@selector(takeVideoClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:takeVideoBtn];
        self.captureButton = takeVideoBtn;
        [self changeCapturingButtonColor:NO];
        NSDictionary *takeVideoBtnDic = NSDictionaryOfVariableBindings(takeVideoBtn);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[takeVideoBtn(==70)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:takeVideoBtnDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[takeVideoBtn(==70)]-(30)-|" options:0 metrics:nil views:takeVideoBtnDic]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:takeVideoBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        
        
    }
    return self;
}

- (void)flashLightClick {
    
}

- (void)cameraSwitchAlternativelyRearOrFront {
    if ([self.mediaCaptureDelegate respondsToSelector:@selector(cameraDeviceAlternativelyRearOrFront)]) {
        [self.mediaCaptureDelegate cameraDeviceAlternativelyRearOrFront];
    }
}

- (void)cancelTakingVideo {
    if ([self.mediaCaptureDelegate respondsToSelector:@selector(closeCaptureView)]) {
        [self.mediaCaptureDelegate closeCaptureView];
    }
}

- (void)takeVideoClick
{
    self.cameraBtnSwitch.hidden = YES;
    
    if (self.isCapturing) {
        if ([self.mediaCaptureDelegate respondsToSelector:@selector(stopCapture)]) {
            self.capture = NO;
            [self changeCapturingButtonColor:NO];
            [self.mediaCaptureDelegate stopCapture];
        }
    } else {
        if ([self.mediaCaptureDelegate respondsToSelector:@selector(startCapture)]) {
            self.capture = YES;
            [self changeCapturingButtonColor:YES];
            [self.mediaCaptureDelegate startCapture];
        }
    }
}

- (void)changeCapturingButtonColor:(BOOL)isCapturing
{
    if (isCapturing) {
        [self startTimer];
        self.captureButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.captureButton.backgroundColor = [UIColor redColor];
    } else {
        [self stopTimer];
        self.captureButton.layer.borderColor = [UIColor grayColor].CGColor;
        self.captureButton.backgroundColor = [UIColor whiteColor];
    }
}

- (void)startTimer {
    _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(timerForTakingVideo) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:UITrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (void)timerForTakingVideo {
    ++self.timerSeconds;
    
    NSString *tlab_txt = _timerLabel.text;
    NSArray *components = [tlab_txt componentsSeparatedByString:@":"];
    int firstNum = [[components firstObject] intValue];
    int secondNum = [[components objectAtIndex:1] intValue];
    int thirdNum = [[components lastObject] intValue];
    
    if (self.timerSeconds == 60) {
        self.timerSeconds = 0;
        
        ++secondNum;
        thirdNum = 0;
        
        if (secondNum == 60) {
            ++firstNum;
            secondNum = 0;
        }
    }
    thirdNum = self.timerSeconds;
    
    _timerLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", firstNum, secondNum, thirdNum];
}

- (void)stopTimer {
    self.timerSeconds = 0;
    [self.timer invalidate];
}

- (void)resetTimer {
    [self stopTimer];
    _timerLabel.text = @"00:00:00";
}

- (void)showCameraSwitch {
    self.cameraBtnSwitch.hidden = NO;
}

- (void)showDismissButton:(BOOL)showDismiss {
    self.downArrowForDismiss.hidden = !showDismiss;
}

//- (void)disabledAllSubviewsEvents {
//    self.cameraBtnSwitch.enabled = NO;
//    self.captureButton.enabled = NO;
//    self.flashLightBtn.enabled = NO;
//    self.dismissButton.enabled = NO;
//}
//
//- (void)enabledAllSubviewsEvents {
//    self.cameraBtnSwitch.enabled = YES;
//    self.captureButton.enabled = YES;
//    self.flashLightBtn.enabled = YES;
//    self.dismissButton.enabled = YES;
//}

- (void)dealloc
{
    NSLog(@"ZRMediaCaptureView has been deallocated!");
}

@end
 
