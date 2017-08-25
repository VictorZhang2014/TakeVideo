//
//  ZRVideoCaptureViewController.h
//  TakeVideos
//
//  Created by VictorZhang on 14/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger) {
    ZRMediaCaptureTypeDefault,
    ZRMediaCaptureTypeCustomizedUI
} ZRMediaCaptureType;

typedef void(^ZRMediaCaptureCompletion)(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval);

@interface ZRMediaCaptureController : UIImagePickerController

- (instancetype)initWithViewController:(UIViewController *)viewController;

- (void)setVideoCaptureType:(ZRMediaCaptureType)captureType completion:(ZRMediaCaptureCompletion)completion;

+ (void)videoCompressWithSourceURL:(NSURL*)sourceURL completion:(void(^)(int statusCode, NSString *outputVideoURL))completion;

@end
