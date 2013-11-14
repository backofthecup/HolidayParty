//
//  Beacon.h
//  HolidayParty
//
//  Created by Eric Mansfield on 11/12/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Beacon : NSManagedObject

@property (nonatomic, retain) NSNumber * major;
@property (nonatomic, retain) NSNumber * tableIndex;
@property (nonatomic, retain) NSNumber * claimed;
@property (nonatomic, retain) NSNumber * ack;
@property (nonatomic, retain) NSNumber * accuracy;
@property (nonatomic, retain) NSString * imageClaimed;
@property (nonatomic, retain) NSString * imageUnclaimed;


@end
