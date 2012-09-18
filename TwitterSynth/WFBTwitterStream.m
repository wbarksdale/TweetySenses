//
//  WFBTwitter.m
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBTwitterStream.h"

@interface WFBTwitterStream()

@property(readonly) NSString* twitterUsername;
@property(readonly) NSString* twitterPassword;
@property(readonly) NSString* nonce;

@end

@implementation WFBTwitterStream

@synthesize keywords;
@synthesize listener;
@synthesize swCorner;
@synthesize neCorner;
@synthesize twitterConnection;
@synthesize streaming;
@synthesize twitterPassword;
@synthesize twitterUsername;

-(NSString *) nonce{
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0U; i < 32; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return [s copy];
}

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

//POST /1/statuses/update.json?include_entities=true HTTP/1.1
//Accept: */*
//          Connection: close
//          User-Agent: OAuth gem v0.4.4
//          Content-Type: application/x-www-form-urlencoded
//          Authorization:
//          OAuth oauth_consumer_key="xvz1evFS4wEEPTGEFPHBog",
//          oauth_nonce="kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
//          oauth_signature="tnnArxj06cWHq44gCs1OSKk%2FjLY%3D",
//          oauth_signature_method="HMAC-SHA1",
//          oauth_timestamp="1318622958",
//          oauth_token="370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
//          oauth_version="1.0"
//          Content-Length: 76
//          Host: api.twitter.com
//
//          status=Hello%20Ladies%20%2b%20Gentlemen%2c%20a%20signed%20OAuth%20request%21


//oauth

//percent encode values?
#define OAUTH_FORMAT_STRING @"OAuth oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature=\"%@\", oauth_signature_method=\"%@\", oauth_timestamp=\"%@\", oauth_token=\"%@\", oauth_version=\"%@\""

#define kConsumerKey    @"aTJtrm0GNlb2Fw1IZ8WA"
#define kNonce          @"blahblahblah"
#define kSignature  



-(void) sendTwitterStreamingRequestWithBody:(NSString *) body{
    //set up the request
    NSData* postData = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:@"https://stream.twitter.com/1/statuses/filter.json"];
    NSMutableURLRequest *request= [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    NSString *authString = NSString stringWithFormat:OAUTH_FORMAT_STRING, 
    [request setValue:authString forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:postData];
    NSLog(@"request:\n%@", [request HTTPBody]);
    //wait for twitterConnection to get killed
    while(self.twitterConnection){
        [NSThread sleepForTimeInterval:.25];
    }
    self.twitterConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

//Authorization: OAuth oauth_consumer_key="aTJtrm0GNlb2Fw1IZ8WA", oauth_nonce="b7493ca1a07270ef1162260a671e6a58", oauth_signature="utzEgmEmsnijZ9sEfgMDhyUKK3g%3D", oauth_signature_method="HMAC-SHA1", oauth_timestamp="1347933466", oauth_token="sillytoken", oauth_version="1.0"

////basic auth
//-(void) sendTwitterStreamingRequestWithBody:(NSString *) body{
//    //set up the request
//    NSData* postData = [body dataUsingEncoding:NSUTF8StringEncoding];
//    NSURL *url = [NSURL URLWithString:@"https://stream.twitter.com/1/statuses/filter.json"];
//    NSMutableURLRequest *request= [[NSMutableURLRequest alloc] initWithURL:url];
//    [request setHTTPMethod:@"POST"];
//    NSString *userpass = [self.twitterUsername stringByAppendingString:[NSString stringWithFormat:@":%@", self.twitterPassword]];
//    NSLog(@"USERPASS: %@", userpass);
//    NSString *authString = [self Base64Encode:[userpass dataUsingEncoding:NSUTF8StringEncoding]];
//    [request setValue:authString forHTTPHeaderField:@"Authorization"];
//    [request setHTTPBody:postData];
//    
//    NSLog(@"request:\n%@", [request HTTPBody]);
//    //wait for twitterConnection to get killed
//    while(self.twitterConnection){
//        [NSThread sleepForTimeInterval:.25]; 
//    }
//    self.twitterConnection = [NSURLConnection connectionWithRequest:request delegate:self];
//}



-(void) stopStream{
    [self.twitterConnection cancel];
    self.twitterConnection = nil;
}
          
-(void) startStreamWithSWCorner:(CLLocationCoordinate2D) southWest NECorner: (CLLocationCoordinate2D) northEast{
    NSLog(@"\n-------- INITIATING TWITTER STREAM ---------");
    self.swCorner = southWest;
    self.neCorner = northEast;
    
    NSMutableString *geoBoxSpec = [[NSMutableString alloc] initWithString:@"locations="];
    [geoBoxSpec appendString:[NSString stringWithFormat:@"%f,%f,%f,%f", southWest.longitude, southWest.latitude, northEast.longitude, northEast.latitude]];
    [geoBoxSpec appendString:@"&stall_warings=true"];
    NSString *requestBody = [NSString stringWithString:geoBoxSpec];
    NSLog(@"twitter request body: \n%@\n\n", requestBody);
    [self sendTwitterStreamingRequestWithBody:requestBody];
    NSLog(@"\n-------- TWITTER STREAM INITIATED ---------");
}

#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"AUTH FAILED, SOMETHING IS WRONG");
    if ([challenge previousFailureCount] == 0) {
        NSLog(@"received authentication challenge");
        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:self.twitterUsername
                                                                    password:self.twitterPassword
                                                                 persistence:NSURLCredentialPersistenceForSession];
        NSLog(@"credential created");
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
        NSLog(@"responded to authentication challenge");    
    }
    else {
        NSLog(@"previous authentication failure");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *) response;
    NSLog(@"\n\tresponse: %d\n\t%@", [resp statusCode], [resp allHeaderFields]);
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //pul
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
    //self.twitterConnection = nil;
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

#pragma mark private property getters

-(NSString *) twitterUsername{
    NSLog(@"getting username");
    NSData *data = [WFBKeychainWrapper load:@"username"];
    if(data == nil) return (NSString *)data;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

-(NSString *) twitterPassword{
    NSLog(@"getting password");
    NSData *data = [WFBKeychainWrapper load:@"password"];
    if(data == nil){
        return (NSString *)data;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
