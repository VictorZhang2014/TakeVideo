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
    /*
    
    https://www.google.com/search?q=iOS%E8%A7%86%E9%A2%91%E6%B0%B4%E5%8D%B0&oq=iOS%E8%A7%86%E9%A2%91%E6%B0%B4%E5%8D%B0&gs_l=psy-ab.3...153273.160125.0.160278.26.19.3.0.0.0.613.3529.2-4j1j1j3.9.0....0...1.1j4.64.psy-ab..17.7.1267...0j0i12k1.g3Qudbt8JIA
    
    http://www.hudongdong.com/ios/546.html
    
    http://www.jianshu.com/p/5433143cccd8
    
    http://blog.csdn.net/likendsl/article/details/7595611
    
    http://www.jianshu.com/p/16cb14f53933
    
    http://blog.csdn.net/hherima/article/details/72725395
    
     */
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
    [self presentViewController:takeVideo animated:YES completion:nil];
}

@end
