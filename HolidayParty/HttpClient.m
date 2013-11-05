//
//  HttpClient.m
//  HolidayParty
//
//  Created by Eric Mansfield on 10/31/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "HttpClient.h"

@implementation HttpClient


+ (HttpClient *)sharedClient {
    static HttpClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@".configuring HTTP Client ....");
        
        NSString *baseUrl = BASE_URL;
        NSLog(@"..Properties BaseUrl %@", baseUrl);
        
        _sharedClient = [[HttpClient alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
    });
    
    return _sharedClient;
}

#pragma mark - Overriden methods
- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    self.parameterEncoding = AFJSONParameterEncoding;

    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
//    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/json", @"image/png", @"audio/wav", nil]];
    
    //    [self setDefaultSSLPinningMode:AF];
    
    
    return self;
}

@end
