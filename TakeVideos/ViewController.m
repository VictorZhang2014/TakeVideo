//
//  ViewController.m
//  TakeVideos
//
//  Created by VictorZhang on 14/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZRMediaCaptureController.h"
#import "ZRVideoCaptureViewController.h"
#import "PreviewerVideoViewController.h"
#import "ZRTakeVideoViewController.h"

@interface ViewController ()

- (IBAction)OpenDefaultMode:(id)sender;
- (IBAction)OpenCustomUI1:(id)sender;
- (IBAction)OpenCustomUI2:(id)sender;
- (IBAction)OpenCustomUI3:(id)sender;

@end

@implementation ViewController


- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)authorize {
    // 询问视频权限
    __block BOOL isVideoAccessible = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
            isVideoAccessible = YES;
        } else {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    isVideoAccessible = YES;
                } else {
                    isVideoAccessible = NO;
                }
            }];
        }
    });
    
    // 询问音频权限
    __block BOOL isAudioAccessible = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusAuthorized) {
            isAudioAccessible = YES;
        } else {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (granted) {
                    isAudioAccessible = YES;
                } else {
                    isAudioAccessible = NO;
                }
            }];
        }
    });
    
    if (isVideoAccessible && isAudioAccessible) {
        
    }
}

- (void)previewVideo:(NSURL *)url interval:(NSTimeInterval)interval useFirstCompression:(BOOL)useFirstCompression {
    dispatch_async(dispatch_get_main_queue(), ^{
        PreviewerVideoViewController *preview = [[PreviewerVideoViewController alloc] init];
        preview.useFirstCompression = useFirstCompression;
        preview.playURL = url;
        preview.videoInterval = interval;
        [self.navigationController pushViewController:preview animated:YES];
    });

}

- (IBAction)OpenDefaultMode:(id)sender { 
    ZRMediaCaptureController *manager = [[ZRMediaCaptureController alloc] init];
    [manager setVideoCaptureType:ZRMediaCaptureTypeDefault completion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            [self previewVideo:videoURL interval:videoInterval useFirstCompression:YES];
        }
    }];
    [self presentViewController:manager animated:YES completion:nil];
}

- (IBAction)OpenCustomUI1:(id)sender {
    ZRMediaCaptureController *manager = [[ZRMediaCaptureController alloc] init];
    [manager setVideoCaptureType:ZRMediaCaptureTypeCustomizedUI completion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            [self previewVideo:videoURL interval:videoInterval useFirstCompression:YES];
        }
    }];
    [self presentViewController:manager animated:YES completion:nil];
}

- (IBAction)OpenCustomUI2:(id)sender {
    ZRVideoCaptureViewController * videoCapture = [[ZRVideoCaptureViewController alloc] init];
    [videoCapture setCaptureCompletion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            [self previewVideo:videoURL interval:videoInterval useFirstCompression:YES];
        }
    }];
    videoCapture.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:videoCapture animated:YES completion:nil];
}

- (IBAction)OpenCustomUI3:(id)sender {
    ZRTakeVideoViewController *takeVideo = [[ZRTakeVideoViewController alloc] init];
    takeVideo.averageBitRate = 4.0;
    [takeVideo setCaptureCompletion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            [self previewVideo:videoURL interval:videoInterval useFirstCompression:NO];
        }
    }];
    takeVideo.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:takeVideo animated:YES completion:nil];
}

@end
