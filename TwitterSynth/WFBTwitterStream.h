//
//  WFBTwitter.h
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Twitter/Twitter.h>
#import "WFBTwitterStreamListener.h"
#import <Accounts/Accounts.h>

@interface WFBTwitterStream : NSObject <NSURLConnectionDelegate>
{
    NSMutableArray *keywords;
    id<WFBTwitterStreamListener> listener;
    
    BOOL streaming;
    NSURLConnection *twitterConnection;
    CLLocationCoordinate2D swCorner;
    CLLocationCoordinate2D neCorner;
}

@property(nonatomic, readonly) BOOL streaming;
@property(nonatomic, readonly) BOOL streamInitiated;

@property(strong) NSURLConnection *twitterConnection;
@property(nonatomic) CLLocationCoordinate2D swCorner;
@property(nonatomic) CLLocationCoordinate2D neCorner;

@property(nonatomic, retain) NSArray *keywords;
@property(nonatomic) id<WFBTwitterStreamListener> listener;

-(id) initWithKeywords:(NSArray *) keywords andListener:(id<WFBTwitterStreamListener>)listener_id;
-(id) initWithListener:(id<WFBTwitterStreamListener>)listener_id;

-(void) startStreamWithSWCorner:(CLLocationCoordinate2D) southWest NECorner: (CLLocationCoordinate2D) northEast;
-(void) stopStream;

@end
