//
//  BarTender.m
//  HolidayParty
//
//  Created by chris mollis on 11/8/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "BarTender.h"
#import "CoreLocation/CoreLocation.h"

static NSString * const BAR_SCORE = @"barScore";
static NSString * const USER_ID = @"userId";

@implementation BarTender

- (id)init
{
    self = [super init];
    if(self)
    {
        _defaultProximityUUID = [[NSUUID alloc] initWithUUIDString:@"5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"];
        _defaultPower = @-54;
        _defaultRegionId = @"com.appsontheside.HolidayParty.BarRegion";
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        _needsBarScoreUpdate = FALSE;
    }
    
    return self;
}


+ (BarTender *)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}


- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"didRangeBeacons is CALLED!!!!");
    
    if ([self checkForBarProximity:beacons] == TRUE) {
        
        NSLog(@"in range.. call background update ");
        
        [manager stopRangingBeaconsInRegion:region];
        
        [self updateBarScoreInBackground];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSLog(@"BarTender: didDetermineState is called.. for ");
    
    if ([region isKindOfClass:[CLBeaconRegion class]] ) {
        
        NSLog(@"didDetermineState for CLBeaconRegion");
    
        if(state == CLRegionStateInside)
        {
        // If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
        // If its not, iOS will display the notification to the user.
        //[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
        {
            NSLog(@"application in background");            //notification.alertBody = @"You're inside the region";
            
            [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
            
        }
        else{
        
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                NSLog(@"application in active state");
            }
            else
                NSLog(@"application in inactive state");
        }
        }
        else if(state == CLRegionStateOutside)
        {
        //  notification.alertBody = @"You're outside the region";
        NSLog(@"You're outside of the region");

        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
        {
            NSLog(@"application in background");            //notification.alertBody = @"You're inside the region";
        }
        else{
            
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                NSLog(@"application in active state");
            }
            else
                NSLog(@"application in inactive state");
        }

        }
        else
        {
            return;
        }
    
    }
}

- (BOOL) startMonitoring
{
    NSLog(@"Start Monitoring for Bar Region.. YEAH!");
    NSLog(@"Default proximity UUID %@", [_defaultProximityUUID UUIDString]);
    NSLog(@"Default region ID %@", _defaultRegionId);
    
    NSUUID *proximityId =_defaultProximityUUID;
    NSString *regionID =_defaultRegionId;
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityId identifier:regionID];
    
    region.notifyOnEntry = YES;
    region.notifyOnExit = YES;
    region.notifyEntryStateOnDisplay = YES;
    
    [_locationManager startMonitoringForRegion:region];
    
    return TRUE;
}

- (BOOL) stopMonitoring
{
    return TRUE;
}

- (BOOL) checkForBarProximity:(NSArray*)barBeacons
{
    
    //this could get called from InitialViewController during app foreground checks, or when application wakes up
    
    NSLog(@"Checking for barscore update.. check proximity to bar beacons");
    
    /* there should be two here.. 
     
     If you're immediate to any one of the bar beacons, then we're available for update
    
     if near:  
     
     check  beacon.major
            beacon.minor
            beacon.accuracy (in meters)
     
     If close enough:
            _needsBarScoreUpdate = TRUE;
     else:
            _needsBarScoreUpdate = FALSE;
     
     if 
    */
    
    // immediate
    NSArray *immediateBeacons = [barBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count]) {
        NSLog(@"..immediate beacon found...");
        
        _needsBarScoreUpdate = TRUE;
    }
    
    NSArray *nearBeacons = [barBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count]){

        NSLog(@"..Near beacons found");
        
        _needsBarScoreUpdate = TRUE;
    }
    
    NSArray *farBeacons = [barBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count]) {
        
        NSLog(@"far beacons found.. check to see if they've been welcomed");
//        [_beacons setObject:farBeacons forKey:[NSNumber numberWithInt:CLProximityFar]];
//        self.welcomeLabel.text = self.originalWelcomeText;
//        self.claimBeaconButton.hidden = YES;
        
        _needsBarScoreUpdate = FALSE;

    }
  
    return _needsBarScoreUpdate;
}

- (BOOL) startUpdateTimer {
    
    self.barUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(updateBarScore) userInfo:nil repeats:YES];
    
    return TRUE;
}

- (BOOL) stopUpdateTimer {
    
    [self.barUpdateTimer invalidate];
    self.barUpdateTimer = nil;
    
    return TRUE;
}

- (BOOL) updateBarScoreInBackground
{
    
    // we're using background tasks because normally there is only 5 seconds to do something when transitioning to
    // a background state.  A server update may take longer.
    
    UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;;
    
    bgTask = [[UIApplication sharedApplication]
              beginBackgroundTaskWithExpirationHandler:^{
                  [[UIApplication sharedApplication] endBackgroundTask:bgTask];
              }];

    
    NSLog(@"calling update bar score in background ");
    [self updateBarScore];
    
    
    if (bgTask != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }


    return TRUE;
    
}

- (BOOL) updateBarScore
{
 
    if (_needsBarScoreUpdate == NO) return FALSE;
    
    HttpClient *client = [HttpClient sharedClient];

    NSInteger userId = [[NSUserDefaults standardUserDefaults] integerForKey:USER_ID];
    
    //if user id == 0, they haven't registered yet
    if (userId == 0 ) { return FALSE; }
    
   // NSLog(@"Bar score is %ld ", (long)barScoreValue);
    
    //barScoreValue = barScoreValue + 1;
    
    NSString *updateUrl = [NSString stringWithFormat:@"increment_bar_score/%d", userId];
    
    NSLog(@"Update Url is %@", updateUrl);
    
    [client GET:updateUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"bar score update successfull %@", responseObject);
        
        NSDictionary *attributes = responseObject;
        NSInteger barScoreUpdate = [attributes[@"bar_score"] integerValue];
        NSLog(@"barScore From    response %li", (long)barScoreUpdate);

        
        //get the bar score, save it and then notify the UI to update if running in the foreground
        
            [[NSUserDefaults standardUserDefaults] setInteger:barScoreUpdate forKey:BAR_SCORE];
        
            [[NSUserDefaults standardUserDefaults] synchronize];
        
            NSNumber *barScore = [NSNumber numberWithLong:barScoreUpdate];
            NSDictionary *barScoreData = [NSDictionary dictionaryWithObject:barScore
                                                                 forKey:@"barScore"];
        
        
            //send an update to whoever's listening
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BarScoreUpdate"
                                                                object:nil
                                                              userInfo:barScoreData];
        

        
            _needsBarScoreUpdate = NO;
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"registration failed at url... %@", operation.request.URL);
        NSLog(@"error %@", error.localizedDescription);
        
        _needsBarScoreUpdate = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BarScoreUpdateFailed" object:nil];
        
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];
    }];

    
    return TRUE;
}

@end