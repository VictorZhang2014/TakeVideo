//
//  ZRMediaCaptureView.h
//  TakeVideos
//
//  Created by VictorZhang on 14/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ZRMediaCaptureDelegate <NSObject>

//前/后摄像头切换
- (void)cameraDeviceAlternativelyRearOrFront;

//开始捕获视频
- (void)startCapture;

//停止捕获视频
- (void)stopCapture;

//关闭捕获视频界面
- (void)closeCaptureView;

@end


@interface ZRMediaCaptureView : UIView

@property (nonatomic, assign) id<ZRMediaCaptureDelegate> mediaCaptureDelegate;


- (void)resetTimer;

- (void)showCameraSwitch;

- (void)showDismissButton:(BOOL)showDismiss;

@end

