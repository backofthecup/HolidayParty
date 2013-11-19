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
static NSString * const USER_WELCOMED = @"userWelcomed";
static float const BAR_BEACON_THRESHOLD = 6.5f;


NSInteger const kBarScoreUpdateNotificationType = 1;
NSInteger const kUserWelcomeNotificationType = 2;

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
        
        _centralMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(40.71972369, -73.99946627);
        
        _barGPSRegion = [[CLCircularRegion alloc]initWithCenter:location radius:15.0 identifier:@"com.appsontheside.HolidayParty.BarGPSRegion"];

        
        _btReady = NO;
        
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


- (BOOL) userWelcomeMessage {
    
    NSInteger userWelcomed = [[NSUserDefaults standardUserDefaults] integerForKey:USER_WELCOMED];
    
    if (userWelcomed == 0) {
        
        //user now welcomed!
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:USER_WELCOMED];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"You made it!  Grab a drink and update your Bar Score.";
        
        NSString *notificationType = @"notificationType";
        NSNumber *notificationValue = [NSNumber numberWithInt:2];
        
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:notificationValue forKey:notificationType];
        notification.userInfo = userInfoDict;
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }

    
    return TRUE;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    //self.cBReady = false;
    NSString *stateString = nil;
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            stateString = @"Bluetooth is powered off.  If you want to play, go to settings and turn it on.";
            _btReady = NO;
            [self stopMonitoring];
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            stateString = @"Bluetooth hardware is powered on and ready";
            _btReady = YES;
               //start the bar beacon region monitoring
                [ self startMonitoring];

            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CoreBluetooth BLE hardware is resetting");
            _btReady = NO;
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            stateString = @"The app is not authorized to use Bluetooth Low Energy";
            _btReady = NO;
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE state is unknown");
            stateString = @"The bluetooth LE state unknown, disabling for now.. update pending.";
            _btReady = NO;
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            stateString = @"Bluetooth Low Energy is unsupported on this platform";
            _btReady = NO;
            break;
        default:
            break;
    }
    
    if  (stateString) {
        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hey" message:stateString delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
 //[alert show];        
        
        NSNumber *btState = [NSNumber numberWithBool:_btReady];
        
        NSDictionary *btStateDict = [NSDictionary dictionaryWithObjectsAndKeys:stateString, @"btStateString", btState, @"btState", nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Bluetooth Status"
                                                            object:nil
                                                          userInfo:btStateDict];
        
    }
    
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"didRangeBeacons is CALLED!!!!");
    
    if ([self checkForBarProximity:beacons] == TRUE) {
        
        NSLog(@"in range.. call background update ");
        
        [manager stopRangingBeaconsInRegion:region];
        
        [self updateBarScoreInBackground];
    }
 
}

#pragma CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {

    //check if they're greeted..
    
    NSLog(@"Did Enter Region");
    
    [self userWelcomeMessage];
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
            
            //range beacons for 10 seconds.. 
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
    else if ([region isKindOfClass:[CLCircularRegion class]]) {
        NSLog(@"CLCircularRegion Found");
        
        if (state == CLRegionStateInside ) {
            
            NSLog(@"CLRegion STate INSIDE HERE!!!! ");
        }
        else if(state == CLRegionStateOutside) {
                
            NSLog(@" CL Region State outside");
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
    
    _barRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityId identifier:regionID];
    
    _barRegion.notifyOnEntry = YES;
    _barRegion.notifyOnExit = YES;
    _barRegion.notifyEntryStateOnDisplay = YES;
    
    [_locationManager startMonitoringForRegion:_barRegion];
    [_locationManager startMonitoringForRegion:_barGPSRegion];
    
    return TRUE;
}

- (BOOL) stopMonitoring
{
    return TRUE;
}

- (BOOL) checkForBarProximity:(NSArray*)barBeacons
{
    
    NSLog(@"Checking for barscore update.. check proximity to bar beacons");
    
    for (id myArrayElement in barBeacons) {
        CLBeacon *beacon = (CLBeacon*)myArrayElement;
        
        NSLog(@"beacon major %@", beacon.major);
        NSLog(@"beacon minor %@", beacon.minor);
        NSLog(@"beacon accuracy is %.2fm", beacon.accuracy);
        
        if ((beacon.accuracy < BAR_BEACON_THRESHOLD) && (beacon.accuracy > 0.0f) ) {
            _needsBarScoreUpdate = YES;
        }
        else
            _needsBarScoreUpdate = NO;
    }
  
    NSArray *farBeacons = [barBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count]) {
        
        [self userWelcomeMessage];
    }

    
    return _needsBarScoreUpdate;
}

- (BOOL) startUpdateTimer {
    
    self.barUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(updateBarScoreInBackground) userInfo:nil repeats:YES];
    
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
    
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

    });

    return TRUE;
    
}

- (BOOL) updateBarScore
{
 
    if (_needsBarScoreUpdate == NO) return FALSE;
    
    HttpClient *client = [HttpClient sharedClient];
    NSInteger userId = [[NSUserDefaults standardUserDefaults] integerForKey:USER_ID];
    
    //if user id == 0, they haven't registered yet
    if (userId == 0 ) { return FALSE; }
    
    NSString *updateUrl = [NSString stringWithFormat:@"increment_bar_score/%li", (long)userId];
    
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
        
            //kick this back to the main UI thread
            dispatch_async(dispatch_get_main_queue(), ^(void){
            //send an update to whoever's listening
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BarScoreUpdate"
                                                                object:nil
                                                              userInfo:barScoreData];
        

        });
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            // send a local notification that their bar score is updated
            
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertBody = @"Your Bar score is updated!";
            
            NSString *notificationType = @"notificationType";
            NSNumber *notificationValue = [NSNumber numberWithInt:1];
            
            NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:notificationValue forKey:notificationType];
            notification.userInfo = userInfoDict;
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
            _needsBarScoreUpdate = NO;
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"registration failed at url... %@", operation.request.URL);
        NSLog(@"error %@", error.localizedDescription);
        
        _needsBarScoreUpdate = NO;
        
        //kick this back to the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BarScoreUpdateFailed" object:nil];
        });
        
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];
    }];

    
    return TRUE;
}

@end
