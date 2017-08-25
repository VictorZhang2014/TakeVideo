//
//  ViewController.m
//  TakeVideos
//
//  Created by VictorZhang on 14/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ViewController.h"
#import "ZRMediaCaptureController.h"
#import "ZRVideoCaptureViewController.h"
#import "PreviewerVideoViewController.h"

@interface ViewController ()

- (IBAction)OpenDefaultMode:(id)sender;
- (IBAction)OpenCustomUI1:(id)sender;
- (IBAction)OpenCustomUI2:(id)sender;

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

- (void)previewVideo:(NSURL *)url interval:(NSTimeInterval)interval {
    dispatch_async(dispatch_get_main_queue(), ^{
        PreviewerVideoViewController *preview = [[PreviewerVideoViewController alloc] init];
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
            [self previewVideo:videoURL interval:videoInterval];
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
            [self previewVideo:videoURL interval:videoInterval];
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
            [self previewVideo:videoURL interval:videoInterval];
        }
    }];
    [self presentViewController:videoCapture animated:YES completion:nil];
}

@end
