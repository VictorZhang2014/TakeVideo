//
//  ZRVideoCaptureViewController.m
//  TakeVideos
//
//  Created by VictorZhang on 19/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRVideoCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ZRMediaCaptureView.h"
#import "ZRVideoPlayerController.h"


typedef void(^ZRPropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface ZRVideoCaptureViewController ()<AVCaptureFileOutputRecordingDelegate, ZRMediaCaptureDelegate, ZRVideoPlayerDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *captureMovieFileOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, strong) UIView *previewer;
@property (nonatomic, strong) UIImageView *focusOnImage;

@property (nonatomic, strong) ZRMediaCaptureView *mediaCaptureView;

@property (nonatomic, strong) NSURL *videoFileURL;

@property (nonatomic, copy) ZRMediaCaptureCompletion captureCompletion;

@end

@implementation ZRVideoCaptureViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)setCaptureCompletion:(ZRMediaCaptureCompletion)completion {
    _captureCompletion = completion;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _captureSession = [[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    //获取后置摄像头设备
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    if (!captureDevice) {
        NSLog(@"获取后置摄像头设备时出现问题。");
        return;
    }
    
    //获取语音设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    //获取摄像头视频输入
    NSError *error = nil;
    _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"获取摄像头输入时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //获取摄像头语音输入
    AVCaptureDeviceInput *audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"获取摄像头语音输入时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //获取摄像头输出
    _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    //将输入和输出设备添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        
        
        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将输出设备添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    //创建摄像头预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CGRect rect = [UIScreen mainScreen].bounds;
    UIView *preview = [[UIView alloc] initWithFrame:rect];
    [self.view addSubview:preview];
    _previewer = preview;
    
    CALayer *layer = preview.layer;
    layer.masksToBounds = YES;
    
    _captureVideoPreviewLayer.frame = layer.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    //将视频预览层添加到界面中
    [layer addSublayer:_captureVideoPreviewLayer];
    
    ZRMediaCaptureView *captureView = [[ZRMediaCaptureView alloc] init];
    captureView.hidden = YES;
    captureView.mediaCaptureDelegate = self;
    _mediaCaptureView = captureView;
    [preview addSubview:captureView];
    
    [self addGenstureRecognizer];
    
    //设置聚焦点图片
    UIImageView *focusOnImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zr_camera_focus_rectangle"]];
    focusOnImg.transform = CGAffineTransformIdentity;
    focusOnImg.alpha = 0;
    [preview addSubview:focusOnImg];
    self.focusOnImage = focusOnImg;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _mediaCaptureView.hidden = NO;
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopCapture];
    [self.captureSession stopRunning];
}

#pragma mark - ZRMediaCaptureDelegate
- (void)cameraDeviceAlternativelyRearOrFront {
    AVCaptureDevice *currentDevice = [self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;
    }
    AVCaptureDevice *toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    
    //重新获取摄像头视频输入
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    
    //移除原有输入对象
    [self.captureSession removeInput:self.captureDeviceInput];
    
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.captureDeviceInput = toChangeDeviceInput;
    }
    
    //提交会话配置
    [self.captureSession commitConfiguration];
}

- (void)startCapture {
    [self.mediaCaptureView showDismissButton:NO];
    
    //连接到摄像头的视频输出设备
    AVCaptureConnection *captureConnection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (![self.captureMovieFileOutput isRecording]) {
        
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation = [self.captureVideoPreviewLayer connection].videoOrientation;
        
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        int random = arc4random() % 10000001;
        NSString *filename = [NSString stringWithFormat:@"%@/%d.mov", path, random];
        self.videoFileURL = [NSURL fileURLWithPath:filename];
        
        [self.captureMovieFileOutput startRecordingToOutputFileURL:self.videoFileURL recordingDelegate:self];
    }
}

- (void)stopCapture {
    [self.mediaCaptureView showDismissButton:YES];
    
    if ([self.captureMovieFileOutput isRecording]) {
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
}

- (void)closeCaptureView {
    [self stopCapture];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ZRVideoPlayerDelegate
- (void)videoPlayerWithRetakingVideo
{
    [self.mediaCaptureView resetTimer];
    [self.mediaCaptureView showCameraSwitch];
}

- (void)videoPlayerWithChoseVideo:(NSURL *)url videoInterval:(NSTimeInterval)videoInterval
{
    [self.mediaCaptureView resetTimer];
    
    if (self.captureCompletion) {
        self.captureCompletion(0, nil, url, videoInterval);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"开始录制...");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    if (error) {
        if (self.captureCompletion)
            self.captureCompletion((int)error.code, error.localizedDescription, outputFileURL, 0);
    } else {
        [self previewVideoByURL:outputFileURL];
    }
}

- (void)previewVideoByURL:(NSURL *)url {
    ZRVideoPlayerController *moviePlayer = [[ZRVideoPlayerController alloc] initWithURL:url];
    moviePlayer.videoPlayerDelegate = self;
    moviePlayer.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:moviePlayer animated:NO completion:nil];
}

- (void)addGenstureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
    [self.previewer addGestureRecognizer:tapGesture];
}

- (void)tapScreen:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.previewer];
    
    CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

//设置聚焦点
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point {
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

//改变摄像头的属性前，一定更要先lock，改完后，再unlock
- (void)changeDeviceProperty:(ZRPropertyChangeBlock)propertyChange {
    AVCaptureDevice *captureDevice = [self.captureDeviceInput device];
    NSError *error = nil;
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    } else {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

//设置聚焦点图片的位置
- (void)setFocusCursorWithPoint:(CGPoint)point {
    self.focusOnImage.center = point;
    self.focusOnImage.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusOnImage.alpha = 1.0;
    
    [UIView animateWithDuration:1.0 animations:^{
        self.focusOnImage.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusOnImage.alpha = 0;
    }];
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position {
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

- (void)dealloc {
    NSLog(@"ZRVideoCaptureViewController has been deallocated!");
}

@end
