//
//  WFBTwitter.h
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "WFBTwitterStreamListener.h"
@interface WFBTwitterStream : NSObject <NSURLConnectionDelegate>
{
    NSMutableArray *keywords;
    id<WFBTwitterStreamListener> listener;
    
    CLLocationCoordinate2D swCorner;
    CLLocationCoordinate2D neCorner;
}

@property(nonatomic) CLLocationCoordinate2D swCorner;
@property(nonatomic) CLLocationCoordinate2D neCorner;

@property(nonatomic, retain) NSArray *keywords;
@property (nonatomic) id<WFBTwitterStreamListener> listener;

-(id) initWithKeywords:(NSArray *) keywords andListener:(id<WFBTwitterStreamListener>)listener_id;
-(id) initWithSWCorner:(CLLocationCoordinate2D) southWest NECorner: (CLLocationCoordinate2D) northEast listener:(id<WFBTwitterStreamListener>)listener_id;
@end
