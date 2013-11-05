//
//  HttpClient.h
//  HolidayParty
//
//  Created by Eric Mansfield on 10/31/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "AFNetworking.h"

static NSString * const BASE_URL = @"http://ec2-54-200-209-241.us-west-2.compute.amazonaws.com:8080/";
static NSString * const REGISTER_PATH = @"register";
static NSString * const UPLOAD_IMAGE_PATH = @"upload";

@interface HttpClient : AFHTTPClient

+ (HttpClient *)sharedClient;

@end
