//
//  ZRWaterPrintComposition.m
//  TakeVideos
//
//  Created by VictorZhang on 29/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//  添加水印

#import "ZRWaterPrintComposition.h"
#import <AVFoundation/AVFoundation.h>

@implementation ZRWaterPrintComposition

- (void)addVideoWaterprintAtURL:(NSURL *)originalURL WithWaterprintImage:(UIImage *)waterprintImage withTitleText:(NSString*)titleText iconSize:(CGSize)iconSize completionHandler:(void(^)(int status, NSString *errorMsg, NSURL *finishedVideoURL))completionHandler
{
    if (!originalURL) {
        if (completionHandler) {
            completionHandler(-1, @"originalPath cannot be nil or empty!", nil);
        }
        return;
    }
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    //视频采集
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:originalURL options:opts];
    
    //声音采集
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:originalURL options:opts];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    //视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //音频通道
    AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime startTime = CMTimeMakeWithSeconds(0.2, 600);
    CMTime endTime = CMTimeMakeWithSeconds(videoAsset.duration.value/videoAsset.duration.timescale-0.2, videoAsset.duration.timescale);
    
    //把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
    [videoTrack insertTimeRange:CMTimeRangeMake(startTime, endTime)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    
    //音频采集通道
    AVAssetTrack * audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration);
    // 3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    //    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
    //        videoAssetOrientation_ =  UIImageOrientationUp;
    //    }
    //    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
    //        videoAssetOrientation_ = UIImageOrientationDown;
    //    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:endTime];
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    //AVMutableVideoComposition：管理所有视频轨道，可以决定最终视频的尺寸，裁剪需要在这里进行
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 25);
    
    [self applyVideoEffectsToComposition:mainCompositionInst WithWaterprintImage:waterprintImage withTitleText:titleText size:CGSizeMake(renderWidth, renderHeight) iconSize:iconSize];
    
    // 4 - 输出路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"victor-%d.mp4", arc4random() * 1000000]];
    
    unlink([myPathDocs UTF8String]);
    
    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
    
    // 5 - 视频文件输出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch ([exporter status]) {
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusUnknown:
                {
                    if (completionHandler) {
                        completionHandler(-2, [NSString stringWithFormat:@"render Export failed: %@", [exporter error]], nil);
                    }
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    if (completionHandler) {
                        completionHandler(-3, [NSString stringWithFormat:@"render Export canceled: %@", [exporter error]], nil);
                    }
                }
                    break;
                default:
                {
                    if (completionHandler) {
                        completionHandler(0, nil, videoUrl);
                    }
                }
                    break;
            }
        });
    }];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition WithWaterprintImage:(UIImage*)img withTitleText:(NSString*)titleText size:(CGSize)size iconSize:(CGSize)iconSize {
    
    //添加水印  也可以添加多个
    CGFloat imgLayerWidth = iconSize.width;
    CGFloat imgLayerHeight = iconSize.height;
    CALayer *imgLayer = [CALayer layer];
    imgLayer.contents = (id)img.CGImage;
    imgLayer.frame = CGRectMake(size.width - imgLayerWidth, size.height - imgLayerWidth - 25, imgLayerWidth, imgLayerHeight);
    
    //添加文字
    UIFont *font = [UIFont systemFontOfSize:30.0];
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFontSize:30];
    [subtitle1Text setString:titleText];
    [subtitle1Text setAlignmentMode:kCAAlignmentLeft];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    //    [subtitle1Text setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor];
    CGSize textSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    CGFloat txtH = textSize.height + 10;
    CGFloat txtY = size.height - txtH - imgLayerWidth - 25;
    [subtitle1Text setFrame:CGRectMake(imgLayer.frame.origin.x + 5, txtY, imgLayerWidth, txtH)];
    
    //把文字和图标都添加到layer
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    [overlayLayer addSublayer:imgLayer];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    //设置封面
    //    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"opacity"];
    //    anima.fromValue = [NSNumber numberWithFloat:1.0f];
    //    anima.toValue = [NSNumber numberWithFloat:0.0f];
    //    anima.repeatCount = 0;
    //    anima.duration = 5.0f;  //5s之后消失
    //    [anima setRemovedOnCompletion:NO];
    //    [anima setFillMode:kCAFillModeForwards];
    //    anima.beginTime = AVCoreAnimationBeginTimeAtZero;
    //    [coverImgLayer addAnimation:anima forKey:@"opacityAniamtion"];
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

@end
