//
//  HttpClient.h
//  HolidayParty
//
//  Created by Eric Mansfield on 10/31/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "AFNetworking.h"

static NSString * const REGISTER_PATH = @"register";

@interface HttpClient : AFHTTPClient

+ (HttpClient *)sharedClient;

@end
