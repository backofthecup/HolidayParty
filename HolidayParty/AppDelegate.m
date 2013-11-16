//
//  AppDelegate.m
//  HolidayParty
//
//  Created by Eric Mansfield on 10/29/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "AppDelegate.h"
#import "BarTender.h"
#import "CoreDataDao.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
//    //start the bar beacon region monitoring
//    [[BarTender sharedInstance] startMonitoring];

    
    NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
    NSLog(@"... UUID %@", [uuid UUIDString]);
    
    // seed db id necessary
    NSArray *beacons = [[CoreDataDao sharedDao] beacons];
    if ([beacons count] < 1) {
        [[CoreDataDao sharedDao] seedDatabase];
    }
    return YES;
    
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[BarTender sharedInstance] stopUpdateTimer];

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[BarTender sharedInstance] startUpdateTimer];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"didReceiveLocalNotification app in foreground.. check the notification type");
    
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *notificationValue = [userInfo objectForKey:@"notificationType"];
    NSLog(@"Notification Type is %@", notificationValue);

    
    if (notificationValue.integerValue == kUserWelcomeNotificationType) {

            //send a notification to welcome the user if the app in foreground
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UserWelcomeMessage" object:nil];
        
    }

    
    // If the application is in the foreground, we will notify the user of the region's state via an alert.
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:notification.alertBody message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
}


@end
