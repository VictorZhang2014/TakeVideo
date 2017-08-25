//
//  ZRVideoCaptureViewController.h
//  TakeVideos
//
//  Created by VictorZhang on 19/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ZRMediaCaptureCompletion)(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval);

@interface ZRVideoCaptureViewController : UIViewController 

- (void)setCaptureCompletion:(ZRMediaCaptureCompletion)completion;

@end
