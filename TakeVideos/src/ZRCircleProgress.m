//
//  ZRCircleProgress.m
//  TakeVideos
//
//  Created by VictorZhang on 28/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRCircleProgress.h"

@interface ZRCircleProgress()

@property (nonatomic, strong) CAShapeLayer *spLayer;
@property (nonatomic, assign) float progress;

@end

@implementation ZRCircleProgress

- (instancetype)init 
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.frame = [UIScreen mainScreen].bounds;
        
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        backgroundView.backgroundColor = [UIColor blackColor];
        backgroundView.alpha = 0.2;
        [self addSubview:backgroundView];
        NSDictionary *bgDic = NSDictionaryOfVariableBindings(backgroundView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[backgroundView]-(0)-|" options:0 metrics:nil views:bgDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[backgroundView]-(0)-|" options:0 metrics:nil views:bgDic]];
        
        UIView *rectangleView = [[UIView alloc] init];
        rectangleView.translatesAutoresizingMaskIntoConstraints = NO;
        rectangleView.backgroundColor = [UIColor blackColor];
        rectangleView.alpha = 0.7;
        rectangleView.layer.cornerRadius = 10;
        [self addSubview:rectangleView];
        NSDictionary *rectangleDic = NSDictionaryOfVariableBindings(rectangleView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[rectangleView(==100)]" options:0 metrics:nil views:rectangleDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[rectangleView(==90)]" options:0 metrics:nil views:rectangleDic]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:rectangleView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:rectangleView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        
        UILabel *uploadView = [[UILabel alloc] init];
        uploadView.translatesAutoresizingMaskIntoConstraints = NO;
        uploadView.textAlignment = NSTextAlignmentCenter;
        uploadView.backgroundColor = [UIColor clearColor];
        uploadView.text = @"压缩中...";
        uploadView.textColor = [UIColor whiteColor];
        uploadView.font = [UIFont systemFontOfSize:14];
        [self addSubview:uploadView];
        NSDictionary *uploadDic = NSDictionaryOfVariableBindings(uploadView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadView(==100)]" options:0 metrics:nil views:uploadDic]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[uploadView(==22)]" options:0 metrics:nil views:uploadDic]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:uploadView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:uploadView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:33.0]];
    }
    return self;
}

- (void)startWithProgressing:(float)progress {
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

- (void)drawRect:(CGRect)rect {
    CGFloat circleWidth = 40;
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
        self.spLayer.lineWidth = 2.f;
        self.spLayer.lineCap = kCALineCapRound;
        self.spLayer.path = circleBezier.CGPath;
    }
}

- (void)dismiss {
    [self removeFromSuperview];
}

- (void)dealloc {
    NSLog(@"ZRCircleProgress has been deallocated!");
}

@end
