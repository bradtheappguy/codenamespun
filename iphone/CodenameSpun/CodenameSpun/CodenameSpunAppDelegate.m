//
//  CodenameSpunAppDelegate.m
//  CodenameSpun
//
//  Created by Jon Bardin on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CodenameSpunAppDelegate.h"
#import "libspotify/SPSession.h"
#import "libspotify/SPAlbum.h"
#import "libspotify/SPTrack.h"
#import "libspotify/SPArtist.h"
#import <AVFoundation/AVFoundation.h>
#import "TouchJSON/JSON/CJSONSerializer.h"
#include "libspotify/appkey.c"

@interface NSString(DataURI)
- (NSString *) pngDataURIWithContent;
- (NSString *) jpgDataURIWithContent;
@end

@implementation NSString(DataURI)

- (NSString *) pngDataURIWithContent;
{
  NSString * result = [NSString stringWithFormat: @"data:image/png;base64,%@", self];
  return result;
}

- (NSString *) jpgDataURIWithContent;
{
  NSString * result = [NSString stringWithFormat: @"data:image/jpg;base64,%@", self];
  return result;
}

@end


@interface NSString (ParseCategory)
- (NSMutableDictionary *)explodeToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue;
@end

@implementation NSString (ParseCategory)

- (NSMutableDictionary *)explodeToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue {
  // Explode based on outter glue
  NSArray *firstExplode = [self componentsSeparatedByString:outterGlue];
  NSArray *secondExplode;
  
  // Explode based on inner glue
  NSInteger count = [firstExplode count];
  NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
  for (NSInteger i = 0; i < count; i++) {
    secondExplode = [(NSString *)[firstExplode objectAtIndex:i] componentsSeparatedByString:innerGlue];
    if ([secondExplode count] == 2) {
      [returnDictionary setObject:[secondExplode objectAtIndex:1] forKey:[secondExplode objectAtIndex:0]];
    }
  }
  
  return returnDictionary;
}

@end

@interface NSData (Base64) 

+ (NSData *)dataWithBase64EncodedString:(NSString *)string;
- (id)initWithBase64EncodedString:(NSString *)string;

- (NSString *)base64Encoding;
- (NSString *)base64EncodingWithLineLength:(unsigned int) lineLength;

@end

static char encodingTable[64] = {
  'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
  'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
  'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
  'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

@implementation NSData (VQBase64)

- (id)initWithString:(NSString *)string {
  if ((self = [super init])) {
    [self initWithBase64EncodedString:string];
  }
  return self;
  
}


+ (NSData *) dataWithBase64EncodedString:(NSString *) string {
  return [[[NSData allocWithZone:nil] initWithBase64EncodedString:string] autorelease];
}

- (id) initWithBase64EncodedString:(NSString *) string {
  NSMutableData *mutableData = nil;
  
  if( string ) {
    unsigned long ixtext = 0;
    unsigned long lentext = 0;
    unsigned char ch = 0;
    unsigned char inbuf[4], outbuf[3];
    short i = 0, ixinbuf = 0;
    BOOL flignore = NO;
    BOOL flendtext = NO;
    NSData *base64Data = nil;
    const unsigned char *base64Bytes = nil;
    
    // Convert the string to ASCII data.
    base64Data = [string dataUsingEncoding:NSASCIIStringEncoding];
    base64Bytes = [base64Data bytes];
    mutableData = [NSMutableData dataWithCapacity:[base64Data length]];
    lentext = [base64Data length];
    
    while( YES ) {
      if( ixtext >= lentext ) break;
      ch = base64Bytes[ixtext++];
      flignore = NO;
      
      if( ( ch >= 'A' ) && ( ch <= 'Z' ) ) ch = ch - 'A';
      else if( ( ch >= 'a' ) && ( ch <= 'z' ) ) ch = ch - 'a' + 26;
      else if( ( ch >= '0' ) && ( ch <= '9' ) ) ch = ch - '0' + 52;
      else if( ch == '+' ) ch = 62;
      else if( ch == '=' ) flendtext = YES;
      else if( ch == '/' ) ch = 63;
      else flignore = YES;
      
      if( ! flignore ) {
        short ctcharsinbuf = 3;
        BOOL flbreak = NO;
        
        if( flendtext ) {
          if( ! ixinbuf ) break;
          if( ( ixinbuf == 1 ) || ( ixinbuf == 2 ) ) ctcharsinbuf = 1;
          else ctcharsinbuf = 2;
          ixinbuf = 3;
          flbreak = YES;
        }
        
        inbuf [ixinbuf++] = ch;
        
        if( ixinbuf == 4 ) {
          ixinbuf = 0;
          outbuf [0] = ( inbuf[0] << 2 ) | ( ( inbuf[1] & 0x30) >> 4 );
          outbuf [1] = ( ( inbuf[1] & 0x0F ) << 4 ) | ( ( inbuf[2] & 0x3C ) >> 2 );
          outbuf [2] = ( ( inbuf[2] & 0x03 ) << 6 ) | ( inbuf[3] & 0x3F );
          
          for( i = 0; i < ctcharsinbuf; i++ )
            [mutableData appendBytes:&outbuf[i] length:1];
        }
        
        if( flbreak )  break;
      }
    }
  }
  
  self = [self initWithData:mutableData];
  return self;
}

#pragma mark -

- (NSString *) base64Encoding {
  return [self base64EncodingWithLineLength:0];
}

- (NSString *) base64EncodingWithLineLength:(unsigned int) lineLength {
  const unsigned char     *bytes = [self bytes];
  NSMutableString *result = [NSMutableString stringWithCapacity:[self length]];
  unsigned long ixtext = 0;
  unsigned long lentext = [self length];
  long ctremaining = 0;
  unsigned char inbuf[3], outbuf[4];
  unsigned short i = 0;
  unsigned short charsonline = 0, ctcopy = 0;
  unsigned long ix = 0;
  
  while( YES ) {
    ctremaining = lentext - ixtext;
    if( ctremaining <= 0 ) break;
    
    for( i = 0; i < 3; i++ ) {
      ix = ixtext + i;
      if( ix < lentext ) inbuf[i] = bytes[ix];
      else inbuf [i] = 0;
    }
    
    outbuf [0] = (inbuf [0] & 0xFC) >> 2;
    outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
    outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
    outbuf [3] = inbuf [2] & 0x3F;
    ctcopy = 4;
    
    switch( ctremaining ) {
      case 1:
        ctcopy = 2;
        break;
      case 2:
        ctcopy = 3;
        break;
    }
    
    for( i = 0; i < ctcopy; i++ )
      [result appendFormat:@"%c", encodingTable[outbuf[i]]];
    
    for( i = ctcopy; i < 4; i++ )
      [result appendString:@"="];
    
    ixtext += 3;
    charsonline += 4;
    
    if( lineLength > 0 ) {
      if( charsonline >= lineLength ) {
        charsonline = 0;
        [result appendString:@"\n"];
      }
    }
  }
  
  return [NSString stringWithString:result];
}

@end


@implementation CodenameSpunAppDelegate


@synthesize globalPlaylists;
@synthesize globalTracks;
@synthesize globalBrowsers;
@synthesize window=_window;
@synthesize viewController=_viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
  [[[self viewController].subviews objectAtIndex:0] setScrollEnabled:NO];  //to stop scrolling completely
  [[[self viewController].subviews objectAtIndex:0] setBounces:NO]; //to stop bouncing
  [[self viewController] setScalesPageToFit:NO];
  [[self viewController] setBackgroundColor:[UIColor clearColor]];
  [[self viewController] setAllowsInlineMediaPlayback:YES];
  [[self viewController] setMediaPlaybackRequiresUserAction:NO];
  
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
	
  didFetchPlaylists = NO;
  countOfTracks = 0;

  [self setGlobalPlaylists:[NSMutableDictionary dictionaryWithCapacity:0]];
  [self setGlobalTracks:[NSMutableDictionary dictionaryWithCapacity:0]];
  [self setGlobalBrowsers:[NSMutableDictionary dictionaryWithCapacity:0]];

  audio_init(&audiofifo);
  [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                             userAgent:@"com.spotify.SimplePlayer"
                                                 error:&err];
  [[SPSession sharedSession] setDelegate:self];
  [[SPSession sharedSession] setPlaybackDelegate:self];
  
  [[NSUserDefaults standardUserDefaults]registerDefaults:nil];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"name_preference"];
  NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"password_preference"];
  if (!username || !password) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Set USername and password in settings" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [alert release];
  }
  [[SPSession sharedSession] attemptLoginWithUserName:username password:password rememberCredentials:NO];
  
  [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(checkBrowsers:) userInfo:nil repeats:YES];
  
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
    if ([[[request URL] host] isEqualToString:@"player"]) {
      NSMutableDictionary *parsedQuery = [[[request URL] query] explodeToDictionaryInnerGlue:@"=" outterGlue:@"&"];
      NSString *deplussed = [[parsedQuery objectForKey:@"track"] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
      NSString *track = [deplussed stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      SPTrack *trackToPlay = [globalTracks objectForKey:track];
      NSError *err = nil;
      [[SPSession sharedSession] seekPlaybackToOffset:0];
      [[SPSession sharedSession] playTrack:trackToPlay error:&err];
      NSLog(@"parsedQuery: %@ %@", track, err);
    }
    return NO;
  }
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  //NSLog(@"webView failed %@", error);
}


-(void)sessionDidLoginSuccessfully:(SPSession *)aSession {
  //NSLog(@"sessionDidLoginSuccessfully %@", [aSession user]);
}


-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
  //NSLog(@"WTF!!!!!!!!!!!!!!!!");
}


-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage{
  NSLog(@"session: %@, message: %@", aSession, aMessage);
}


-(void)sessionDidChangeMetadata:(SPSession *)aSession {
  @synchronized(self) {
  int c = 0;
  SPPlaylistContainer *playlists = [aSession userPlaylists];  
  if ([playlists isLoaded] && [[playlists playlists] count] > 0) {    
    for (id playlist_or_folder in [playlists playlists]) {
      if ([playlist_or_folder isKindOfClass:[SPPlaylistFolder class]]) {
        //NSLog(@"folder, wtf is afolder");
      } else if ([playlist_or_folder isKindOfClass:[SPPlaylist class]]) {
        c += [[playlist_or_folder tracks] count];
        if ([playlist_or_folder isLoaded]) {
          for (SPTrack *track in [playlist_or_folder tracks]) {
            if ([track isLoaded]) {
              SPArtist *fa = [[track artists] objectAtIndex:0];
              SPAlbum *a = [track album];
              [[a cover] image];
              SPAlbumBrowse *alb = [SPAlbumBrowse browseAlbum:a inSession:[SPSession sharedSession]];
              SPArtistBrowse *arb = [SPArtistBrowse browseArtist:fa inSession:[SPSession sharedSession]];
              if (alb == nil || arb == nil) {
                NSLog(@"asfsdfsdF@#$#@$@#$@#@#$@#$");
              } else {
                [globalTracks setObject:track forKey:[track name]];
                [globalBrowsers setObject:[NSArray arrayWithObjects:alb, arb, nil] forKey:[track name]];
              }
            }
          }
        }
      }
    }
  }
  
  NSLog(@"c: %d", c);
  
  countOfTracks = c;
  }
}


-(void)tracksInPlaylistDidUpdateMetadata:(SPPlaylist *)aPlaylist {
  NSLog(@"wtf!@#");
}


-(void)checkBrowsers:(id)userInfo {
  @synchronized(self) {
  NSMutableArray *remove = [NSMutableArray arrayWithCapacity:0];
  if ([globalBrowsers count] > 0) {
    for (id track_name in [globalBrowsers allKeys]) {
      NSArray *arb_alb = [globalBrowsers objectForKey:track_name];
      if ([[arb_alb objectAtIndex:0] isLoaded] && [[arb_alb objectAtIndex:1] isLoaded]) {
        SPTrack *track = [globalTracks objectForKey:track_name];      
        SPArtist *fa = [[track artists] objectAtIndex:0];
        SPAlbum *a = [track album];
        if ([[a cover] isLoaded]) {
          NSData *imgData = UIImagePNGRepresentation([[a cover] image]);          
          NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
          NSString *documents = [paths objectAtIndex:0];
          NSString *filePath = [documents stringByAppendingPathComponent:track_name];
          [imgData writeToFile:filePath atomically: YES];           
          NSString *url = [[NSURL fileURLWithPath:filePath] absoluteString];
          [globalPlaylists setObject:[NSArray arrayWithObjects:[track name], [fa name], [a name], url, nil] forKey:track_name];
          [remove addObject:track_name];
          break;
        }
      }
    }
  }
  
  for (id remove_name in remove) {
    [globalBrowsers removeObjectForKey:remove_name];
  }
    
  if (countOfTracks > 0 && countOfTracks == [globalTracks count] && [globalBrowsers count] == 0 && didFetchPlaylists == NO) {    
    NSError *error = NULL;
    NSData *jsonData = [[CJSONSerializer serializer] serializeObject:globalPlaylists error:&error];
    NSString *jsonPlaylists = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *didLoadPlaylistsCallback = [NSString stringWithFormat:@"javascript:didFetchPlaylists(%@);", jsonPlaylists];
    NSLog(@"%@", didLoadPlaylistsCallback);
    [self.viewController stringByEvaluatingJavaScriptFromString:didLoadPlaylistsCallback];
    didFetchPlaylists = YES;
  } else {
    NSLog(@"fetched: %d waiting:%d", [globalPlaylists count], [globalBrowsers count]);
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
