//
//  WFBTwitter.h
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFBTwitterStream : NSObject <NSURLConnectionDelegate>
{
    NSMutableArray *keywords;
    
}

@property(nonatomic, retain) NSArray *keywords;

-(id) initWithKeywords:(NSArray *) keywords;

@end
