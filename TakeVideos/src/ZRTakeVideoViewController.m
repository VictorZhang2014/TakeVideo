//
//  ZRTakeVideoViewController.m
//  TakeVideos
//
//  Created by VictorZhang on 26/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRTakeVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZRMediaCaptureView.h"
#import "ZRVideoPlayerController.h"


typedef NS_ENUM( NSInteger, ZRRecordingStatus) {
    ZRRecordingStatusIdle = 0,
    ZRRecordingStatusRecording,
    ZRRecordingStatusFinished,
    ZRRecordingStatusFailed,
};

typedef void(^ZRPropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface ZRTakeVideoViewController ()
<
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate,
ZRMediaCaptureDelegate,
ZRVideoPlayerDelegate
>

@property (nonatomic, assign) ZRRecordingStatus recordingStatus;

@property (nonatomic, assign) CGSize outputSize;
@property (nonatomic, copy) NSString *videoFilePath;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *cameraDeviceInput;

@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) dispatch_queue_t audioDataOutputQueue;
@property (nonatomic, strong) dispatch_queue_t writingAssetQueue;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) ZRMediaCaptureView *mediaCaptureView;
@property (nonatomic, strong) UIView *previewer;
@property (nonatomic, strong) UIImageView *focusOnImg;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoAssetWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *audioAssetWriterInput;

@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic) CGAffineTransform videoTrackTransform;

@property (nonatomic, copy) ZRMediaCaptureCompletion captureCompletion;

@end

@implementation ZRTakeVideoViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)setCaptureCompletion:(ZRMediaCaptureCompletion)completion {
    _captureCompletion = completion;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _outputSize = CGSizeMake(540, 960);
        
        _audioDataOutputQueue = dispatch_queue_create("com.victor.media.audio.output", DISPATCH_QUEUE_SERIAL);
        _videoDataOutputQueue = dispatch_queue_create("com.victor.media.video.output", DISPATCH_QUEUE_SERIAL);
        
        _writingAssetQueue = dispatch_queue_create("com.victor.video.assetwriter", DISPATCH_QUEUE_SERIAL);
        
        _videoTrackTransform = CGAffineTransformMakeRotation(M_PI_2);//人像方向
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad]; 
    
    [self addInputDeviceOfCaptureSession];
    [self addOutputDeviceOfCaptureSession];
    [self addPreviewLayerOfCaptureSession];
    [self addFocusOnPreview];
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

//添加输入设备
- (void)addInputDeviceOfCaptureSession { 
    _captureSession = [[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    if (![self addCameraInputToCaptureSession]){
        NSLog(@"加载摄像头失败");
    }
    if (![self addDefaultMicInputToCaptureSession:_captureSession]){
        NSLog(@"加载麦克风失败");
    }
}

- (BOOL)addCameraInputToCaptureSession {
    NSError *error = nil;
    AVCaptureDeviceInput *cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:&error];
    _cameraDeviceInput = cameraDeviceInput;
    
    if (error) {
        NSLog(@"配置摄像头输入错误: %@", [error localizedDescription]);
        return NO;
    } else {
        BOOL success = [self addInputToCaptureSession:cameraDeviceInput];
        return success;
    }
}

- (BOOL)addDefaultMicInputToCaptureSession:(AVCaptureSession *)captureSession {
    NSError *error = nil;
    AVCaptureDeviceInput *micDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
    if (error){
        NSLog(@"配置麦克风输入错误: %@", [error localizedDescription]);
        return NO;
    } else {
        BOOL success = [self addInputToCaptureSession:micDeviceInput];
        return success;
    }
}

- (BOOL)addInputToCaptureSession:(AVCaptureDeviceInput *)input {
    if ([_captureSession canAddInput:input]){
        [_captureSession addInput:input];
        return YES;
    } else {
        NSLog(@"不能添加输入设备: %@", [input description]);
    }
    return NO;
}

//添加输出设备
- (void)addOutputDeviceOfCaptureSession { 
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:self.audioDataOutputQueue];
    
    [self addOutputToCaptureSession:self.videoDataOutput];
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [self addOutputToCaptureSession:self.audioDataOutput];
    self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    
    [self setCompressionSettings];
}

- (BOOL)addOutputToCaptureSession:(AVCaptureOutput *)output {
    if ([self.captureSession canAddOutput:output]){
        [self.captureSession addOutput:output];
        return YES;
    } else {
        NSLog(@"不能添加输出设备 %@", [output description]);
    }
    return NO;
}

- (float)averageBitRate {
    if (_averageBitRate == 0) {
        _averageBitRate = 2.5;
    }
    return _averageBitRate;
}

- (void)setCompressionSettings {
    
    NSInteger numPixels = self.outputSize.width * self.outputSize.height;
    
    //每像素比特
    CGFloat bitsPerPixel = self.averageBitRate;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264Main41 };
    
    //这是系统推荐的使用的视频参数，但是我们不适用，因为不同的屏幕拍摄的大小肯定不一样
    self.videoCompressionSettings = [self.videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoWidthKey : @(self.outputSize.height),
                                       AVVideoHeightKey : @(self.outputSize.width),
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    
    // 音频设置
    self.audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
}

- (void)addPreviewLayerOfCaptureSession {
    //创建摄像头预览层，用于实时展示摄像头状态
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CGRect rect = [UIScreen mainScreen].bounds;
    UIView *preview = [[UIView alloc] initWithFrame:rect];
    [self.view addSubview:preview];
    _previewer = preview;
    
    CALayer *layer = preview.layer;
    layer.masksToBounds = YES;
    
    _videoPreviewLayer.frame = layer.bounds;
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //将视频预览层添加到界面中
    [layer addSublayer:_videoPreviewLayer];
    
    ZRMediaCaptureView *captureView = [[ZRMediaCaptureView alloc] init];
    captureView.hidden = YES;
    captureView.mediaCaptureDelegate = self;
    _mediaCaptureView = captureView;
    [preview addSubview:captureView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _mediaCaptureView.hidden = NO;
    });
}

#pragma mark - ZRMediaCaptureDelegate
- (void)cameraDeviceAlternativelyRearOrFront {
    AVCaptureDevice *currentDevice = [self.cameraDeviceInput device];
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
    [self.captureSession removeInput:self.cameraDeviceInput];
    
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.cameraDeviceInput = toChangeDeviceInput;
    }
    
    //提交会话配置
    [self.captureSession commitConfiguration];
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

- (void)startCapture {
    [self startCapturing];
}

- (void)stopCapture {
    [self stopCapturing];
}

- (void)closeCaptureView {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate 和 AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (connection == self.videoConnection){
        if (!self.outputVideoFormatDescription) {
            @synchronized(self) {
                CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                self.outputVideoFormatDescription = formatDescription;
            }
        } else {
            @synchronized(self) {
                if (self.recordingStatus == ZRRecordingStatusRecording) {
                    [self appendVideoSampleBuffer:sampleBuffer];
                }
            }
        }
    } else if (connection == self.audioConnection ){
        if (!self.outputAudioFormatDescription) {
            @synchronized(self) {
                CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                self.outputAudioFormatDescription = formatDescription;
            }
        }
        @synchronized(self) {
            
            if (self.recordingStatus == ZRRecordingStatusRecording) {
                [self appendAudioSampleBuffer:sampleBuffer];
            }
        }
    }
}

- (void)startCapturing {
    //NSAssert(TARGET_IPHONE_SIMULATOR, @"Do not support Simulator when capturing video!");
    
    NSString *tempFileName = [NSProcessInfo processInfo].globallyUniqueString;
    self.videoFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[tempFileName stringByAppendingPathExtension:@"mp4"]];
    
    //静止自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self.mediaCaptureView showDismissButton:NO];
    [self resetAssetWriter];
    
    [self addAssetWriter];
}

- (void)stopCapturing {
    //静止自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self finishWritingVideo];
}

- (void)addAssetWriter {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.videoFilePath]) {
        [fileManager removeItemAtPath:self.videoFilePath error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    }
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.videoFilePath] fileType:AVFileTypeMPEG4 error:&error];
    if (!error) {
        [self setupAssetWriterVideoInputWithError:&error];
    }
    if (!error) {
        [self setupAssetWriterAudioInputWithError:&error];
    }
    if (!error) {
        BOOL success = [self.assetWriter startWriting];
        if (!success) {
            error = self.assetWriter.error;
            NSLog(@"%@", error);
        }
        self.recordingStatus = ZRRecordingStatusRecording;
    } else {
        self.recordingStatus = ZRRecordingStatusFailed;
    }
}

- (BOOL)setupAssetWriterVideoInputWithError:(NSError **)errorOut {
    if ([self.assetWriter canApplyOutputSettings:self.videoCompressionSettings forMediaType:AVMediaTypeVideo]){
        self.videoAssetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings sourceFormatHint:self.outputVideoFormatDescription];
        self.videoAssetWriterInput.expectsMediaDataInRealTime = YES;
        self.videoAssetWriterInput.transform = _videoTrackTransform;
        
        if ([self.assetWriter canAddInput:self.videoAssetWriterInput]){
            [self.assetWriter addInput:self.videoAssetWriterInput];
        } else {
            if (errorOut) {
                *errorOut = [self cannotSetupInputError];
            }
            return NO;
        }
    } else {
        if (errorOut) {
            *errorOut = [self cannotSetupInputError];
        }
        return NO;
    }
    return YES;
}

- (BOOL)setupAssetWriterAudioInputWithError:(NSError **)errorOut {
    if ([self.assetWriter canApplyOutputSettings:self.audioCompressionSettings forMediaType:AVMediaTypeAudio]){
        self.audioAssetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings sourceFormatHint:self.outputAudioFormatDescription];
        self.audioAssetWriterInput.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:self.audioAssetWriterInput]){
            [self.assetWriter addInput:self.audioAssetWriterInput];
        } else {
            if (errorOut) {
                *errorOut = [self cannotSetupInputError];
            }
            return NO;
        }
    }
    else {
        if (errorOut) {
            *errorOut = [self cannotSetupInputError];
        }
        return NO;
    }
    return YES;
}

- (NSError *)cannotSetupInputError {
    NSDictionary *errorDict = @{ NSLocalizedDescriptionKey : @"AVAssetWriterInput cannot be added",
                                 NSLocalizedFailureReasonErrorKey : @"Failed to initialize in AVAssetWriterInput" };
    return [NSError errorWithDomain:@"com.victor.TakeVideo" code:0 userInfo:errorDict];
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
}

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType {
    if (sampleBuffer == NULL){
        NSLog(@"sampleBuffer is NULL!");
        return;
    }
    if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
        return;
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(self.writingAssetQueue, ^{
        @autoreleasepool {
            
            if (mediaType == AVMediaTypeVideo) {
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            
                AVAssetWriterInput *input =
                (mediaType == AVMediaTypeVideo) ? self.videoAssetWriterInput : self.audioAssetWriterInput;
                
                if (input.readyForMoreMediaData){
                    BOOL success = [input appendSampleBuffer:sampleBuffer];
                    if (!success){
                        NSError *error = self.assetWriter.error;
                        @synchronized(self){
                            NSLog(@"%@", error);
                        }
                    } else {
                        NSLog(@"视频录制中...");
                    }
                } else {
                    NSLog( @"%@ 输入不能添加更多数据了，抛弃 buffer", mediaType );
                }
            }
            CFRelease(sampleBuffer);
        }
    });
}

- (void)finishWritingVideo {
    self.recordingStatus = ZRRecordingStatusFinished;
    
    switch (self.assetWriter.status) {
        case AVAssetWriterStatusCompleted:
            break;
        case AVAssetWriterStatusWriting:
        {
            dispatch_async(_writingAssetQueue, ^{
                @autoreleasepool {
                    [self.assetWriter finishWritingWithCompletionHandler:^{
                        @synchronized(self) {
                            NSError *error = self.assetWriter.error;
                            if (error) {
                                NSLog(@"%@", error);
                            }
                            
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self.mediaCaptureView showDismissButton:YES];
                                [self previewVideo];
                            });
                        }
                    }];
                }
            });
        }
            break; 
        case AVAssetWriterStatusFailed:
        case AVAssetWriterStatusCancelled:
            self.recordingStatus = ZRRecordingStatusFailed;
            NSLog(@"%@", self.assetWriter.error);
            break;
        default:
            break;
    }

}

- (void)previewVideo {
    ZRVideoPlayerController *moviePlayer = [[ZRVideoPlayerController alloc] initWithURL:[NSURL fileURLWithPath:self.videoFilePath]];
    moviePlayer.videoPlayerDelegate = self;
    moviePlayer.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:moviePlayer animated:NO completion:nil];
}

- (void)videoPlayerWithRetakingVideo {
    [self.mediaCaptureView resetTimer];
    [self.mediaCaptureView showCameraSwitch];
}

- (void)videoPlayerWithChoseVideo:(NSURL *)url videoInterval:(NSTimeInterval)videoInterval {
    [self.mediaCaptureView resetTimer];
    
    if (self.captureCompletion) {
        self.captureCompletion(0, nil, url, videoInterval);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addFocusOnPreview {
    [self addGenstureRecognizer];
    
    //设置聚焦点图片
    UIImageView *focusOnImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zr_camera_focus_rectangle"]];
    focusOnImg.transform = CGAffineTransformIdentity;
    focusOnImg.alpha = 0;
    [self.previewer addSubview:focusOnImg];
    self.focusOnImg = focusOnImg;
}

- (void)addGenstureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
    [self.previewer addGestureRecognizer:tapGesture];
}

- (void)tapScreen:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.previewer];
    
    CGPoint cameraPoint = [self.videoPreviewLayer captureDevicePointOfInterestForPoint:point];
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
    AVCaptureDevice *captureDevice = [self.cameraDeviceInput device];
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
    self.focusOnImg.center = point;
    self.focusOnImg.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusOnImg.alpha = 1.0;
    
    [UIView animateWithDuration:1.0 animations:^{
        self.focusOnImg.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusOnImg.alpha = 0;
    }];
}

- (void)resetAssetWriter {
    self.assetWriter = nil;
    self.videoAssetWriterInput = nil;
    self.audioAssetWriterInput = nil;
}

- (void)dealloc {
    NSLog(@"ZRTakeVideoViewController has been deallocated!");
    [self resetAssetWriter];
    [self.captureSession stopRunning];
}





@end
