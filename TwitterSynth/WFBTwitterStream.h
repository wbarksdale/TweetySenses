//
//  WFBTwitter.h
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFBTwitterStreamListener.h"
@interface WFBTwitterStream : NSObject <NSURLConnectionDelegate>
{
    NSMutableArray *keywords;
    id<WFBTwitterStreamListener> listener;
    
}

@property(nonatomic, retain) NSArray *keywords;
@property (nonatomic) id<WFBTwitterStreamListener> listener;

-(id) initWithKeywords:(NSArray *) keywords andListener:(id<WFBTwitterStreamListener>)listener_id;

@end
