//
//  ZRMoviePlayerController.h
//  TakeVideos
//
//  Created by VictorZhang on 20/08/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ZRVideoPlayerDelegate <NSObject>

- (void)videoPlayerWithRetakingVideo;

- (void)videoPlayerWithChoseVideo:(NSURL *)url videoInterval:(NSTimeInterval)videoInterval;

@end



@interface ZRVideoPlayerController : UIViewController

@property (nonatomic, weak) id<ZRVideoPlayerDelegate> videoPlayerDelegate;

- (instancetype)initWithURL:(NSURL *)url;

/**
 * 播放指定的视频
 * @replacedUrl, 视频的URL
 */
- (void)replaceCurrentPlayerItem:(NSURL *)replacedUrl;

//仅仅只播放视频
@property (nonatomic, assign) BOOL playVideOnly;

@end
