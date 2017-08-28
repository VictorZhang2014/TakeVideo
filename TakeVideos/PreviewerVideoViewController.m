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
#import "ZRAssetExportSession.h"



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
    
    [self calculateFizeSize];
    
    if (self.useFirstCompression) {
        [self compressVideo];
    } 
}

- (void)compressVideo {
    
    NSURL *outputFileURL = [NSURL fileURLWithPath:[ZRAssetExportSession generateAVAssetTmpPath]];
    ZRAssetExportSession *encoder = [ZRAssetExportSession.alloc initWithAsset:[AVAsset assetWithURL:self.playURL]];
    encoder.outputFileType = AVFileTypeMPEG4;
    encoder.outputURL = outputFileURL;
    [encoder exportAsynchronouslyWithCompletionHandler:^
     {
         if (encoder.status == AVAssetExportSessionStatusCompleted)
         {
             
             AVAssetTrack *videoTrack = nil;
             AVURLAsset *asset = (AVURLAsset *)[AVAsset assetWithURL:encoder.outputURL];
             NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
             videoTrack = [videoTracks firstObject];
             float frameRate = [videoTrack nominalFrameRate];
             float bps = [videoTrack estimatedDataRate];
             NSLog(@"Frame rate == %f",frameRate);
             NSLog(@"bps rate == %f",bps/(1024.0 * 1024.0));
             NSLog(@"Video export succeeded");
             // encoder.outputURL <- this is what you want!!
             
             
             NSFileManager *fileManager = [NSFileManager defaultManager];
             NSError * error;
             NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
             int random = arc4random() % 10000001;
             NSString *filename = [NSString stringWithFormat:@"%@/%d.mp4", path, random];
             
             BOOL success = [fileManager copyItemAtURL:encoder.outputURL toURL:[NSURL fileURLWithPath:filename isDirectory:NO] error:&error];
             if (!success) {
                 success = [fileManager copyItemAtPath:encoder.outputURL.absoluteString toPath:filename error:&error];
             }
             NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:filename error:&error];
             long fileSize = [[fileAttr objectForKey:NSFileSize] longValue];
             NSString *bytes = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
             float fileMB = fileSize / 1024.0 / 1024.0;
             NSLog(@"压缩后视频文件大小 fileMB = %lf   bytes=%@", fileMB, bytes);
             
             self.playURL = [NSURL fileURLWithPath:filename];
             
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.playURL = [NSURL fileURLWithPath:filename];
                 self.videoPath.text = [NSString stringWithFormat:@"Video Path: %@", filename];
                 self.videoSize.text = [NSString stringWithFormat:@"Video Size: %@  ---  %f", bytes, fileMB];
                 self.videoLength.text = [NSString stringWithFormat:@"Video Length: %f 秒", self.videoInterval];
                 self.videoResolution.text = [NSString stringWithFormat:@"Video Resolution: 540 * 960"];
             });
             
         }
         else if (encoder.status == AVAssetExportSessionStatusCancelled)
         {
             NSLog(@"Video export cancelled");
         }
         else
         {
             NSLog(@"Video export failed with error: %@ (%ld)", encoder.error.localizedDescription, encoder.error.code);
         }
     }];
}

- (void)compressVideo2 {
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
        NSLog(@"压缩后视频文件大小 fileMB  = %lf   bytes=%@", fileMB, bytes);
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playURL = [NSURL fileURLWithPath:outputVideoURL];
            self.videoPath.text = [NSString stringWithFormat:@"Video Path: %@", filename];
            self.videoSize.text = [NSString stringWithFormat:@"Video Size: %@  ---  %f", bytes, fileMB];
            self.videoLength.text = [NSString stringWithFormat:@"Video Length: %f 秒", self.videoInterval];
            self.videoResolution.text = [NSString stringWithFormat:@"Video Resolution: 1280x720"];
        });
        
    }];
}

- (void)calculateFizeSize {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError * error;
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    int random = arc4random() % 10000001;
    NSString *filename = [NSString stringWithFormat:@"%@/%d.mp4", path, random];

    BOOL success = [fileManager copyItemAtURL:self.playURL toURL:[NSURL fileURLWithPath:filename isDirectory:NO] error:&error];
    if (!success) {
        success = [fileManager copyItemAtPath:self.playURL.absoluteString toPath:filename error:&error];
    }
    NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:filename error:&error];
    long fileSize = [[fileAttr objectForKey:NSFileSize] longValue];
    NSString *bytes = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
    float fileMB = fileSize / 1024.0 / 1024.0;
    NSLog(@"压缩前视频文件大小 fileMB = %lf   bytes=%@", fileMB, bytes);
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
