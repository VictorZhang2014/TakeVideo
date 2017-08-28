//
//  PreviewerVideoViewController.h
//  TakeVideos
//
//  Created by VictorZhang on 25/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewerVideoViewController : UIViewController

@property (nonatomic, strong) NSURL *playURL;

@property (nonatomic, assign) NSTimeInterval videoInterval;

@property (nonatomic, assign) BOOL useFirstCompression;

@end
