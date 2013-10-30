//
//  FirstViewController.m
//  HolidayParty
//
//  Created by Eric Mansfield on 10/29/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    // see if the user has registered
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    
    if (!userId) {
        // prompt user for registration
        UINavigationController *registrationController = [self.storyboard instantiateViewControllerWithIdentifier:@"RegistrationNavigationController"];
        [self presentViewController:registrationController animated:NO completion:nil];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
