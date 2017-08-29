# TakeVideo
An iOS project that takes video with customized User Interfaces and water mark and compression by AVFoundation.framework , AVCaptureSession, AVAssetWriter, AVCaptureOutput and AVCaptureDeviceInput, AVVideoCompositionInstruction, AVVideoComposition etc.

## Effect Picture
![TakeVideo Effect Photo 1](https://github.com/VictorZhang2014/TakeVideo/blob/master/images/TakeVideo_EffectPicture_00.gif "TakeVideo")
![TakeVideo Effect Photo 1](https://github.com/VictorZhang2014/TakeVideo/blob/master/images/TakeVideo_EffectPicture_11.png "TakeVideo")
![TakeVideo Effect Photo 2](https://github.com/VictorZhang2014/TakeVideo/blob/master/images/TakeVideo_EffectPicture_22.png "TakeVideo")
![TakeVideo Effect Photo 2](https://github.com/VictorZhang2014/TakeVideo/blob/master/images/TakeVideo_EffectPicture_33.png "TakeVideo")

## Let's get started
There're three ways to call. I'm going to show you on how do you call it.

#### First way
Importing this header file
```
#import "ZRMediaCaptureController.h"
```

Then calling the code as shown below. This way is using the default User Interface which means that has done by System Defined
```
    ZRMediaCaptureController *manager = [[ZRMediaCaptureController alloc] init];
    [manager setVideoCaptureType:ZRMediaCaptureTypeDefault completion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            //to do so
            //[self previewVideo:videoURL interval:videoInterval useFirstCompression:YES];
        }
    }];
    [self presentViewController:manager animated:YES completion:nil];
```


#### Second way
Importing this header file
```
#import "ZRMediaCaptureController.h"
```

Then calling the code as shown below. The only difference is `CaptureType`. This way is customized User Interface, and the tailored UI is popular at present, most of apps are using this way.
```
    ZRMediaCaptureController *manager = [[ZRMediaCaptureController alloc] init];
    [manager setVideoCaptureType:ZRMediaCaptureTypeCustomizedUI completion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            //to do so
            //[self previewVideo:videoURL interval:videoInterval useFirstCompression:YES];
        }
    }];
    [self presentViewController:manager animated:YES completion:nil];
```


#### Third way
Importing this header file
```
#import "ZRVideoCaptureViewController.h"
```
Then calling the code as shown below. This is third way to call. The tailored UI(User Interface) that are fitted for the most of apps that is prevalent on WeChat, Snapchat, Instagram, etc. If you want to get deeply tailored UI, you can add some views in this way. This way has been done by AVCaptureSession.
```
    ZRVideoCaptureViewController * videoCapture = [[ZRVideoCaptureViewController alloc] init];
    [videoCapture setCaptureCompletion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            //to do so
            //[self previewVideo:videoURL interval:videoInterval useFirstCompression:YES];
        }
    }];
    [self presentViewController:videoCapture animated:YES completion:nil];
```

#### Fourth way
Importing this header file
```
#import "ZRTakeVideoViewController.h"
```
Then calling the code as shown below. This is fourth way to call. The tailored UI(User Interface) that are fitted for the most of apps that is prevalent on WeChat, Snapchat, Instagram, etc. If you want to get deeply tailored UI, you can add some views in this way.  This way has been done by AVCaptureSession and AVAssetWriter.
```
    ZRTakeVideoViewController *takeVideo = [[ZRTakeVideoViewController alloc] init];
    takeVideo.averageBitRate = 4.0;
    [takeVideo setCaptureCompletion:^(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval) {
        NSLog(@"视频地址：%@", videoURL.absoluteString);
        
        if (errorMessage.length) {
            NSLog(@"拍摄视频失败 %@", errorMessage);
        } else {
            //[self previewVideo:videoURL interval:videoInterval useFirstCompression:NO];
            //to do so
        }
    }];
    [self presentViewController:takeVideo animated:YES completion:nil];
```

## Pay Attention to This compression video file
If you want to compress your video file, you must call one of these snippet code. 
```
[ZRMediaCaptureController videoCompressWithSourceURL:videoURL completion:^(int statusCode, NSString *outputVideoURL) {

}];
```
or using the following way
```
    NSURL *outputFileURL = [NSURL fileURLWithPath:[ZRAssetExportSession generateAVAssetTmpPath]];
    ZRAssetExportSession *encoder = [ZRAssetExportSession.alloc initWithAsset:[AVAsset assetWithURL:self.originalURL]];
    encoder.outputFileType = AVFileTypeMPEG4;
    encoder.outputURL = outputFileURL;
    [encoder exportAsynchronouslyWithCompletionHandler:^
     {
         if (encoder.status == AVAssetExportSessionStatusCompleted)
         {
             
         }
         else if (encoder.status == AVAssetExportSessionStatusCancelled)
         { 
         }
         else
         { 
         }
     }];

```

## Pay Attention to This water print video
Importing the header file
```
#import "ZRWaterPrintComposition.h"
```
Then, call the following code
```
[[ZRWaterPrintComposition new] addVideoWaterprintAtURL:self.playURL WithWaterprintImage:[UIImage imageNamed:@"Icon"] withTitleText:@"Victor" iconSize:CGSizeMake(120, 120) completionHandler:^(int status, NSString *errorMsg, NSURL *finishedVideoURL) {
    if (status == 0) {
        self.playURL = finishedVideoURL;
    } else {
        NSLog(@"%@", errorMsg);
    }
}];
```


