//
//  RegisterViewController.m
//  HolidayParty
//
//  Created by Eric Mansfield on 10/31/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "HttpClient.h"
#import "RegisterViewController.h"

@interface RegisterViewController ()

@end

@implementation RegisterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)registerTapped:(id)sender {
    NSLog(@"...register tapped....");
    
    HttpClient *client = [HttpClient sharedClient];
    NSUUID *device = [[UIDevice currentDevice] identifierForVendor];
    NSDictionary *params = @{@"firstNm": @"eric", @"lastNm" : @"kasfd", @"email" : device.UUIDString};
    
    [client postPath:REGISTER_PATH parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"registration successfulle %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"registration failed at url... %@", operation.request.URL);
        NSLog(@"error %@", error.localizedDescription);
        
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];
    }];
}

@end
