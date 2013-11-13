//
//  CoreDataDao.m
//  HolidayParty
//
//  Created by Eric Mansfield on 11/12/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "CoreDataDao.h"

@interface CoreDataDao ()

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CoreDataDao

+(CoreDataDao *)sharedDao
{
    static CoreDataDao *_sharedDao = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDao = [[CoreDataDao alloc] init];
    });
    
    return _sharedDao;
}


-(id)init {
	self = [super init];
	if (self != nil) {
		// initialize stuff here
	}
	
	return self;
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
    if (_managedObjectContext != nil) {
        return self.managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return _managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
	
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"HolidayParty"]];
	NSLog(@"%@", [storeUrl description]);
	
	NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Core Data Error"
														message:@"An error occurred that is likely due to upgrading to a newer version. Removing the application and re-installing will fix this error. Sorry for the inconvenience."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		//		abort();
    }
	
    return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark - intance methods
- (id)createManagedObject:(NSString *)entity {
	NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:self.managedObjectContext];
	
	return object;
}

#pragma mark - Save and roolback
- (BOOL)save {
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		if (error) {
			NSLog(@"ERROR.......Core Data error occurred %@ %@", [error userInfo], [error localizedDescription]);
			NSLog(@"%@", [error debugDescription]);
			return NO;
		}
	}
	else {
		NSLog(@"...CoreDataDao save was successful....");
	}
    
	return YES;
}

- (void)delete:(NSManagedObject *)managedObject {
    [self.managedObjectContext deleteObject:managedObject];
}

- (void)rollback {
	[self.managedObjectContext rollback];
}



- (NSArray *)executeFetchRequest:(NSFetchRequest *)request {
	NSError *error = nil;
	NSArray *list = [self.managedObjectContext executeFetchRequest:request error:&error];
	if (error) {
		NSLog(@"........Core Data error occurred %@", [error localizedDescription]);
	}
	
	return list;
}




@end
