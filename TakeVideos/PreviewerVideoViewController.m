//
//  PreviewerVideoViewController.m
//  TakeVideos
//
//  Created by VictorZhang on 25/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "PreviewerVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ZRMediaCaptureController.h"
#import "ZRVideoPlayerController.h"



@interface PreviewerVideoViewController ()

@property (weak, nonatomic) IBOutlet UIView *videoView;

@property (weak, nonatomic) IBOutlet UILabel *videoPath;

@property (weak, nonatomic) IBOutlet UILabel *videoSize;

@property (weak, nonatomic) IBOutlet UILabel *videoLength;

@property (weak, nonatomic) IBOutlet UILabel *videoResolution;

- (IBAction)playVideo:(id)sender;


@end

@implementation PreviewerVideoViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoPath.numberOfLines = 0;
    
    
    [ZRMediaCaptureController videoCompressWithSourceURL:self.playURL completion:^(int statusCode, NSString *outputVideoURL) {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError * error;
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        int random = arc4random() % 10000001;
        NSString *filename = [NSString stringWithFormat:@"%@/%d.mp4", path, random];
        
        BOOL success = [fileManager copyItemAtURL:[NSURL URLWithString:outputVideoURL] toURL:[NSURL fileURLWithPath:filename isDirectory:NO] error:&error];
        if (!success) {
            success = [fileManager copyItemAtPath:outputVideoURL toPath:filename error:&error];
        }
        NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:filename error:&error];
        long fileSize = [[fileAttr objectForKey:NSFileSize] longValue];
        NSString *bytes = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
        float fileMB = fileSize / 1024.0 / 1024.0;
        NSLog(@"video_path = %lf   bytes=%@", fileMB, bytes);
    
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoPath.text = [NSString stringWithFormat:@"Video Path: %@", filename];
            self.videoSize.text = [NSString stringWithFormat:@"Video Size: %@  ---  %f", bytes, fileMB];
            self.videoLength.text = [NSString stringWithFormat:@"Video Length: %f 秒", self.videoInterval];
            self.videoResolution.text = [NSString stringWithFormat:@"Video Resolution: 1280x720"];
        });

    }];
}

- (IBAction)playVideo:(id)sender {
    [self previewVideoByURL:self.playURL];
}

- (void)previewVideoByURL:(NSURL *)url {
    ZRVideoPlayerController *moviePlayer = [[ZRVideoPlayerController alloc] initWithURL:url];
    moviePlayer.playVideOnly = YES;
    [self presentViewController:moviePlayer animated:NO completion:nil];
}

@end
