//
//  CoreDataDao.h
//  HolidayParty
//
//  Created by Eric Mansfield on 11/12/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataDao : NSObject


+ (CoreDataDao *)sharedDao;

- (NSString *)applicationDocumentsDirectory;

- (id)createManagedObject:(NSString *)entity;

- (BOOL)save;

- (void)delete:(NSManagedObject *)managedObject;

- (void)rollback;

- (NSArray *)beacons;

- (void)seedDatabase;


@end
