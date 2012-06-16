//
//  WFBTwitterStreamDelegate.h
//  TwitterSynth
//
//  Created by William Barksdale on 6/15/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WFBTwitterStreamListener <NSObject>

- (void) receiveTweet:(NSDictionary *) tweet;

@end
