//
//  BarTender.h
//  HolidayParty
//
//  Created by chris mollis on 11/8/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "HttpClient.h"


@interface BarTender : NSObject <CLLocationManagerDelegate>

+ (BarTender *)sharedInstance;

@property (nonatomic, copy, readonly) NSUUID *defaultProximityUUID;
@property (nonatomic, copy, readonly) NSString *defaultRegionId;
@property (nonatomic, copy, readonly) NSNumber *defaultPower;
@property (nonatomic, assign, readonly) BOOL needsBarScoreUpdate;
@property (nonatomic, strong, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic) NSTimer *barUpdateTimer;

- (BOOL) startMonitoring;
- (BOOL) stopMonitoring;
- (BOOL) startUpdateTimer;
- (BOOL) stopUpdateTimer;
- (BOOL) checkForBarProximity:(NSArray*)barBeacons;
- (BOOL) updateBarScore;
- (BOOL) updateBarScoreInBackground;

@end