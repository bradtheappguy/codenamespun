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
#import "TouchJSON/JSON/CJSONSerializer.h"
#include "libspotify/appkey.c"


@implementation CodenameSpunAppDelegate


@synthesize globalPlaylists;
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
	if(!success) {
		NSLog(@"Failed to activate audio session: %@", err);
  }
	
  
  [self setGlobalPlaylists:[NSMutableDictionary dictionaryWithCapacity:0]];
  audio_init(&audiofifo);
  [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                             userAgent:@"com.spotify.SimplePlayer"
                                                 error:&err];
  [[SPSession sharedSession] setDelegate:self];
  [[SPSession sharedSession] setPlaybackDelegate:self];
  [[SPSession sharedSession] attemptLoginWithUserName:@"diclophis" password:@"qwerty123" rememberCredentials:NO];
  
  [self.window makeKeyAndVisible];
  return YES;
}


- (void)dealloc
{
  [_window release];
  [_viewController release];
    [super dealloc];
}


-(BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  //NSLog(@"webView %@", [request URL]);
  if ([[[request URL] scheme] isEqualToString:@"file"]) {
    return YES;
  } else {
    return NO;
  }
}



- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  //NSLog(@"webView failed %@", error);
}


- (void)beginInterruption {
}


- (void)endInterruptionWithFlags:(NSUInteger)flags NS_AVAILABLE_IPHONE(4_0) {
}


-(void)sessionDidLoginSuccessfully:(SPSession *)aSession {
  //NSLog(@"sessionDidLoginSuccessfully %@", [aSession user]);
}


-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
  //NSLog(@"WTF!!!!!!!!!!!!!!!!");
}


-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage{
  //NSLog(@"session: %@, message: %@", aSession, aMessage);
}


-(void)addPlaylistToGlobalPlaylists:(SPPlaylist *)thePlaylist {
  if ([globalPlaylists objectForKey:[thePlaylist name]]) {
  } else {
    SPPlaylistContainer *playlists = [[SPSession sharedSession] userPlaylists];
    [globalPlaylists setObject:thePlaylist forKey:[thePlaylist name]];
    NSInteger g_count = [globalPlaylists count];
    NSInteger l_count = [[playlists playlists] count] - 1;
    if (g_count == l_count) {
      NSError *error = NULL;
      NSData *jsonData = [[CJSONSerializer serializer] serializeObject:[globalPlaylists allKeys] error:&error];
      NSString *jsonPlaylists = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      NSString *didLoadPlaylistsCallback = [NSString stringWithFormat:@"javascript:didFetchPlaylists([], %@);", jsonPlaylists];
      NSLog(@"wtf: %@", didLoadPlaylistsCallback);
      [self.viewController stringByEvaluatingJavaScriptFromString:didLoadPlaylistsCallback];
    }
  }
}


-(void)sessionDidChangeMetadata:(SPSession *)aSession {
  SPPlaylistContainer *playlists = [aSession userPlaylists];  
  if ([playlists isLoaded]) {    
    for (id playlist_or_folder in [playlists playlists]) {
      if ([playlist_or_folder isKindOfClass:[SPPlaylistFolder class]]) {
        //NSLog(@"folder, wtf is afolder");
      } else if ([playlist_or_folder isKindOfClass:[SPPlaylist class]]) {
        if ([playlist_or_folder isLoaded]) {
          //NSLog(@"list: %@", playlist_or_folder);
          [self performSelectorOnMainThread:@selector(addPlaylistToGlobalPlaylists:) withObject:playlist_or_folder waitUntilDone:NO];
        }
      }
    }
  }
}


/*
 SPPlaylist *first = [[playlists playlists] objectAtIndex:1];
 if (first && [first isLoaded]) {
 SPTrack *track = [[first tracks] objectAtIndex:0];
 if (track && [track isLoaded]) {
 
 
 //NSError *err = nil;        
 //[[SPSession sharedSession] seekPlaybackToOffset:0];
 //[[SPSession sharedSession] playTrack:track error:&err];
 
 
 
 
 }
 }
 */

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