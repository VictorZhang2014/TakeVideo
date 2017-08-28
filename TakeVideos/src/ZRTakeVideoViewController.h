//
//  ZRTakeVideoViewController.h
//  TakeVideos
//
//  Created by VictorZhang on 26/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ZRMediaCaptureCompletion)(int statusCode, NSString *errorMessage, NSURL *videoURL, NSTimeInterval videoInterval);

@interface ZRTakeVideoViewController : UIViewController

/**
 * 视频比特率
 * 建议值：2.5 - 6.0
 *       最低2.5，普通模式，也是默认值
 *       最高6.0，视频文件大小不会占用太多
 **/
@property (nonatomic, assign) float averageBitRate;

- (void)setCaptureCompletion:(ZRMediaCaptureCompletion)completion;

@end
