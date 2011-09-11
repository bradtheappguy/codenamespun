//
//  CodenameSpunAppDelegate.h
//  CodenameSpun
//
//  Created by Jon Bardin on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libspotify/CocoaLibSpotify.h>
#import "audio.h"


@interface CodenameSpunAppDelegate : NSObject <UIApplicationDelegate, UIWebViewDelegate, SPSessionDelegate, SPSessionPlaybackDelegate> {
  audio_fifo_t audiofifo;
  NSMutableDictionary *globalPlaylists;
  NSMutableDictionary *globalTracks;
  NSMutableDictionary *globalBrowsers;
  BOOL didFetchPlaylists;
}


@property (nonatomic, retain) NSMutableDictionary *globalPlaylists;
@property (nonatomic, retain) NSMutableDictionary *globalTracks;
@property (nonatomic, retain) NSMutableDictionary *globalBrowsers;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIWebView *viewController;


@end