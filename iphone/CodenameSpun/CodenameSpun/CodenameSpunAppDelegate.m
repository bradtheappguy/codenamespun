//
//  CodenameSpunAppDelegate.m
//  CodenameSpun
//
//  Created by Jon Bardin on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CodenameSpunAppDelegate.h"
#import "libspotify/SPSession.h"
#import <AVFoundation/AVFoundation.h>

#include "libspotify/appkey.c"




@implementation CodenameSpunAppDelegate

//@synthesize session = _session;

//@synthesize playlist = _playlist;

@synthesize window=_window;

@synthesize viewController=_viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
  
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:@"web"];
  
  [[self viewController] loadRequest:[NSURLRequest requestWithURL:url]];
    
	NSError *err = nil;

	[[AVAudioSession sharedInstance] setDelegate:self];
	BOOL success = YES;
	success &= [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&err];
	success &= [[AVAudioSession sharedInstance] setActive:YES error:&err];
	if(!success)
		NSLog(@"Failed to activate audio session: %@", err);
	
  
  
  audio_init(&audiofifo);
  
  
  [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                             userAgent:@"com.spotify.SimplePlayer"
                                                 error:&err];
  
  [[SPSession sharedSession] setDelegate:self];
  [[SPSession sharedSession] setPlaybackDelegate:self];
  [[SPSession sharedSession] attemptLoginWithUserName:@"diclophis" password:@"qwerty123" rememberCredentials:NO];
  

  NSLog(@"spotify session error: %@", err);

  
  
	NSLog(@"Finished launching");
  
  
  //[_session loginUser:@"diclophis" password:@"qwerty123"];

  
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  /*
   Called when the application is about to terminate.
   Save data if appropriate.
   See also applicationDidEnterBackground:.
   */
}

- (void)dealloc
{
  [_window release];
  [_viewController release];
    [super dealloc];
}

-(BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  NSLog(@"webView %@", [request URL]);
  if ([[[request URL] scheme] isEqualToString:@"file"]) {
    return YES;
  } else {
    return NO;
  }
}



- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"webView failed %@", error);
}

- (void)beginInterruption {
}


- (void)endInterruptionWithFlags:(NSUInteger)flags NS_AVAILABLE_IPHONE(4_0) {
}


-(void)sessionDidLoginSuccessfully:(SPSession *)aSession {
  NSLog(@"sessionDidLoginSuccessfully %@", [aSession user]);
}


-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
  NSLog(@"WTF!!!!!!!!!!!!!!!!");
}


-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage{
  NSLog(@"session: %@, message: %@", aSession, aMessage);
}


-(void)sessionDidChangeMetadata:(SPSession *)aSession {
  SPPlaylistContainer *playlists = [aSession userPlaylists];  
  if ([playlists isLoaded]) {
    SPPlaylist *first = [[playlists playlists] objectAtIndex:1];
    if (first && [first isLoaded]) {
      SPTrack *track = [[first tracks] objectAtIndex:0];
      if (track && [track isLoaded]) {
        NSError *err = nil;        
        [[SPSession sharedSession] seekPlaybackToOffset:0];
        [[SPSession sharedSession] playTrack:track error:&err];
      }
    }
  }
}

-(NSInteger)session:(SPSession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
  audio_fifo_t *af = &audiofifo;
  audio_fifo_data_t *afd = NULL;
  size_t s;
  
  if (frameCount == 0) {
    return 0; // Audio discontinuity, do nothing
  }
  
  pthread_mutex_lock(&af->mutex);
  
  /* Buffer one second of audio */
  if (af->qlen > audioFormat->sample_rate) {
    pthread_mutex_unlock(&af->mutex);    
    return 0;
  }
  
  s = frameCount * sizeof(int16_t) * audioFormat->channels;
  
  afd = malloc(sizeof(audio_fifo_data_t) + s);
  memcpy(afd->samples, audioFrames, s);
  
  afd->nsamples = frameCount;
  
  afd->rate = audioFormat->sample_rate;
  afd->channels = audioFormat->channels;
  
  TAILQ_INSERT_TAIL(&af->q, afd, link);
  af->qlen += frameCount;
  
  pthread_cond_signal(&af->cond);
  pthread_mutex_unlock(&af->mutex);
  
  return frameCount;
  
}

@end