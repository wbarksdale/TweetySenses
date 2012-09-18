//
//  WFBTwitter.m
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBTwitterStream.h"

@interface WFBTwitterStream()

@end

@implementation WFBTwitterStream

@synthesize keywords;
@synthesize listener;
@synthesize swCorner;
@synthesize neCorner;
@synthesize twitterConnection;
@synthesize streaming;
@synthesize streamInitiated;

-(BOOL) streaming{
    if(self.twitterConnection)
        return true;
    return false;
}

-(id) initWithListener:(id<WFBTwitterStreamListener>)listener_id;
{
    if(self = [super init]){
        self.listener = listener_id;
    }
    return self;
}

-(void) stopStream{
    [self.twitterConnection cancel];
    self.twitterConnection = nil;
}
   
//-(void) sendTwitterStreamingRequestWithBody:(NSString *) body{
//    //set up the request
//    NSData* postData = [body dataUsingEncoding:NSUTF8StringEncoding];
//    NSURL *url = [NSURL URLWithString:@"https://stream.twitter.com/1/statuses/filter.json"];
//    NSMutableURLRequest *request= [[NSMutableURLRequest alloc] initWithURL:url];
//    [request setHTTPMethod:@"POST"];
//    NSString *authString = NSString stringWithFormat:OAUTH_FORMAT_STRING,
//    [request setValue:authString forHTTPHeaderField:@"Authorization"];
//    [request setHTTPBody:postData];
//    NSLog(@"request:\n%@", [request HTTPBody]);
//    //wait for twitterConnection to get killed
//    while(self.twitterConnection){
//        [NSThread sleepForTimeInterval:.25];
//    }
//    self.twitterConnection = [NSURLConnection connectionWithRequest:request delegate:self];
//}


-(void) startStreamWithSWCorner:(CLLocationCoordinate2D) southWest NECorner: (CLLocationCoordinate2D) northEast{
    NSLog(@"\n-------- INITIATING TWITTER STREAM ---------");
    self.swCorner = southWest;
    self.neCorner = northEast;
    NSString *location = [NSString stringWithFormat:@"%f,%f,%f,%f", southWest.longitude, southWest.latitude, northEast.longitude, northEast.latitude];
    //[[NSMutableString alloc] initWithString:@"locations="];
    //[geoBoxSpec appendString:@"&stall_warings=true"];
    //NSString *requestBody = [NSString stringWithString:geoBoxSpec];
    
    //  First, we need to obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request permission from the user to access the available Twitter accounts
    WFBTwitterStream __block *tweetyStream = self;
    [store requestAccessToAccountsWithType:twitterAccountType
                     withCompletionHandler:^(BOOL granted, NSError *error) {
                         if (!granted) {
                             // The user rejected your request
                             NSLog(@"User rejected access to the account.");
                         }
                         else {
                             // Grab the available accounts
                             NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
                             
                             if ([twitterAccounts count] > 0) {
                                 // Use the first account for simplicity
                                 ACAccount *account = [twitterAccounts objectAtIndex:2];
                                 NSLog(@"Account: %@\n", account.accountDescription)
                                 // Now make an authenticated request to our endpoint
                                 NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                                 [params setObject:@"1" forKey:@"include_entities"];
                                 [params setObject:location forKey:@"locations"];
                                 [params setObject:@"true" forKey:@"stall_warnings"];
                                 //  The endpoint that we wish to call
                                 NSURL *url = [NSURL URLWithString:@"https://stream.twitter.com/1.1/statuses/filter.json"];
                                 
                                 //  Build the request with our parameter
                                 TWRequest *request = [[TWRequest alloc] initWithURL:url
                                                                          parameters:params
                                                                       requestMethod:TWRequestMethodPOST];
                                 
                                 // Attach the account object to this request
                                 [request setAccount:account];
                                 NSURLRequest *signedReq = request.signedURLRequest;
                                 NSLog(@"signed req %@",signedReq.description);
                                 NSLog(@"HEADER: %@",   signedReq.allHTTPHeaderFields);
                                 NSLog(@"BODY  : %@", [[NSString alloc] initWithData:signedReq.HTTPBody encoding:NSUTF8StringEncoding]);
                                 tweetyStream.twitterConnection = [[NSURLConnection alloc] initWithRequest:signedReq delegate:tweetyStream startImmediately: NO];
                                 
                                 [tweetyStream.twitterConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                                       forMode:NSDefaultRunLoopMode];
                                 [tweetyStream.twitterConnection start];
                                 
                             } // if ([twitterAccounts count] > 0)
                         } // if (granted) 
                     }];
    
    NSLog(@"\n-------- TWITTER STREAM INITIATED ---------");
}

#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"AUTH FAILED, SOMETHING IS WRONG");
    if ([challenge previousFailureCount] == 0) {
        NSLog(@"received authentication challenge");
    }
    else {
        NSLog(@"previous authentication failure");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"got reponse");
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *) response;
    NSLog(@"\n\tresponse: %d\n\t%@", [resp statusCode], [resp allHeaderFields]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //NSLog(@"got some data: \n\n %@ \n\n", [data description]);
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&error];
    NSDictionary *warning = [jsonDictionary objectForKey:@"warning"];
    if(warning){
        [listener laggingStream:[warning objectForKey:@"message"]];
    }
    [listener receiveTweet:jsonDictionary];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connection loaded");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.twitterConnection = nil;
    NSLog(@"connection failed with error:\n %@", error);
}

-(NSString *)Base64Encode:(NSData *)data{
    //Point to start of the data and set buffer sizes
    int inLength = [data length];
    int outLength = ((((inLength * 4)/3)/4)*4) + (((inLength * 4)/3)%4 ? 4 : 0);
    const char *inputBuffer = (const char *) [data bytes];
    char *outputBuffer = (char *) malloc(outLength);
    outputBuffer[outLength] = 0;
    
    //64 digit code
    static char Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    //start the count
    int cycle = 0;
    int inpos = 0;
    int outpos = 0;
    char temp;
    
    //Pad the last to bytes, the outbuffer must always be a multiple of 4
    outputBuffer[outLength-1] = '=';
    outputBuffer[outLength-2] = '=';
    
    /* http://en.wikipedia.org/wiki/Base64
     Text content   M           a           n
     ASCII          77          97          110
     8 Bit pattern  01001101    01100001    01101110
     
     6 Bit pattern  010011  010110  000101  101110
     Index          19      22      5       46
     Base64-encoded T       W       F       u
     */
    
    
    while (inpos < inLength){
        switch (cycle) {
            case 0:
                outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
                cycle = 1;
                break;
            case 1:
                temp = (inputBuffer[inpos++]&0x03)<<4;
                outputBuffer[outpos] = Encode[temp];
                cycle = 2;
                break;
            case 2:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>> 4];
                temp = (inputBuffer[inpos++]&0x0F)<<2;
                outputBuffer[outpos] = Encode[temp];
                cycle = 3;                  
                break;
            case 3:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
                cycle = 4;
                break;
            case 4:
                outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
                cycle = 0;
                break;                          
            default:
                cycle = 0;
                break;
        }
    }
    NSString *pictemp = [NSString stringWithUTF8String:outputBuffer];
    free(outputBuffer); 
    return pictemp;
}

@end
