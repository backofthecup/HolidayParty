//
//  HttpClient.h
//  HolidayParty
//
//  Created by Eric Mansfield on 10/31/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "AFNetworking.h"

static NSString * const BASE_URL = @"http://ec2-54-200-209-241.us-west-2.compute.amazonaws.com:9080/";
static NSString * const REGISTER_PATH = @"register";
static NSString * const CHANGE_USER_PATH = @"update_name";
static NSString * const UPLOAD_IMAGE_PATH = @"upload";
static NSString * const CLAIM_BEACON_PATH = @"claim";

@interface HttpClient : AFHTTPRequestOperationManager

+ (HttpClient *)sharedClient;

@end
