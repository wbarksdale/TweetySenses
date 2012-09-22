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

#define WFBTwitterConnectionFailure     @"WFBTwitterConnectionFailure"
#define WFBTwitterConnectionSuccess     @"WFBTwitterConnectionSuccess"
#define WFBLocationAquired              @"WFBLocationAquired"
#define WFBFailedToAquireLocation       @"WFBFailedToAquireLocation"

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


-(void) startStreamWithSWCorner:(CLLocationCoordinate2D) southWest NECorner: (CLLocationCoordinate2D) northEast{
    NSLog(@"\n-------- INITIATING TWITTER STREAM ---------");
    self.swCorner = southWest;
    self.neCorner = northEast;
    NSString *location = [NSString stringWithFormat:@"%f,%f,%f,%f", southWest.longitude, southWest.latitude, northEast.longitude, northEast.latitude];
    
    //  First, we need to obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request permission from the user to access the available Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType
                     withCompletionHandler:^(BOOL granted, NSError *error) {
                         if (!granted) {
                             // The user rejected your request
                             NSLog(@"User rejected access to the account.");
                             [[NSNotificationCenter defaultCenter] postNotificationName:WFBTwitterConnectionFailure object:self];
                         }
                         else {
                             // Grab the available accounts
                             NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
                             if ([twitterAccounts count] == 0){
                                 NSLog(@"no twitter Accounts");
                                 [[NSNotificationCenter defaultCenter] postNotificationName:WFBTwitterConnectionFailure object:self];
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Twitter Accounts"
                                                                                     message:@"There are no Twitter accounts configured. You can add or create a Twitter account in Settings."
                                                                                    delegate:nil
                                                                           cancelButtonTitle:@"OK"
                                                                           otherButtonTitles:nil];
                                     [alert show];
                                 });
                             } else if ([twitterAccounts count] > 0) {
                                 // this can be set in settings, default is to use the first account
                                 NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"TwitterAccount"];
                                 NSLog(@"username was set to %@", username);
                                 ACAccount *account = [twitterAccounts objectAtIndex:0];
                                 NSLog(@"default account was %@", account.username);
                                 for(ACAccount *tempAcct in twitterAccounts){
                                     if([tempAcct.username isEqualToString:username]) account = tempAcct;
                                 }
                                 NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                                 [params setObject:@"1" forKey:@"include_entities"];
                                 [params setObject:location forKey:@"locations"];
                                 [params setObject:@"true" forKey:@"stall_warnings"];
                                 //set any other criteria to track
                                 //params setObject:@"words, to track" forKey@"track"];
                                 
                                 //  The endpoint that we wish to call
                                 NSURL *url = [NSURL URLWithString:@"https://stream.twitter.com/1.1/statuses/filter.json"];
                                 
                                 //  Build the request with our parameter
                                 TWRequest *request = [[TWRequest alloc] initWithURL:url
                                                                          parameters:params
                                                                       requestMethod:TWRequestMethodPOST];
                                 
                                 // Attach the account object to this request
                                 [request setAccount:account];
                                 NSURLRequest *signedReq = request.signedURLRequest;
                                 
                                 // make the connection, ensuring that it is made on the main runloop
                                 self.twitterConnection = [[NSURLConnection alloc] initWithRequest:signedReq delegate:self startImmediately: NO];
                                 [self.twitterConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                                       forMode:NSDefaultRunLoopMode];
                                 [self.twitterConnection start];
                                 [[NSNotificationCenter defaultCenter] postNotificationName:WFBTwitterConnectionSuccess object:self];
                                 NSLog(@"\n-------- TWITTER STREAM INITIATED ---------");
                             }
                         }
                     }];
}

#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"AUTH FAILED, SOMETHING IS WRONG");
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"Response Recieved");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSError *error;
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *tweetStrings = [response componentsSeparatedByString:@"\r\n"];
    for(NSString *tweet in tweetStrings){
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData: [tweet dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONWritingPrettyPrinted error:&error];
        NSDictionary *warning = [jsonDictionary objectForKey:@"warning"];
        if(warning){
            [listener laggingStream:[warning objectForKey:@"message"]];
        }
        [listener receiveTweet:jsonDictionary];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connection loaded");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"connection failed with error:\n %@", error);
    self.twitterConnection = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:WFBTwitterConnectionFailure object:self];
}

//currently not used
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
