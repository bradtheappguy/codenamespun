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
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UIWebView *viewController;

@end
