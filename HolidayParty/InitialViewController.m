//
//  FirstViewController.m
//  HolidayParty
//
//  Created by Eric Mansfield on 10/29/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "InitialViewController.h"
#import "HttpClient.h"
#import "TSMessageView.h"
#import "UIImage+Resize.h"
#import "Beacon.h"
#import "CoreDataDao.h"
#import "BarTender.h"
#import <AFNetworking/AFNetworking.h>

static float const CLAIMABLE_BEACON_THRESHOLD = 2.0f;   // 2 meters

@interface InitialViewController ()

@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSArray *beacons;
@property (nonatomic, strong) NSMutableArray *rangedBeacons;
@property (nonatomic, assign) BOOL isBluetoothOn;
@property (nonatomic, strong) UIAlertView *networkUnreachableAlertView;

- (void)promptForRegistration;
- (void)registerUser:(NSString *)user;
- (void)updateUsername:(NSString *)username;
- (void)uploadUserImage:(NSData *)data;
- (void)claimBeacon:(Beacon *)beacon;

- (void)loadUserImage;
- (void)startRanging;
- (void)stopRanging;
- (BOOL)networkReachable;

@end

static NSString * const USER_ID_KEY = @"userId";
static NSString * const USER_NAME_KEY = @"userName";
static NSString * const USER_IMAGE_FILE = @"user_image.png";
static NSString * const BAR_SCORE_KEY = @"barScore";

@implementation InitialViewController


- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // intialize the http client, this will start network reachabilty monitoring
    [HttpClient sharedClient];
    
    _networkUnreachableAlertView = [[UIAlertView alloc] initWithTitle:@"Network Unreachable" message:@"Please make sure you have a network connetion." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];

    
    AFNetworkReachabilityManager *reachability = [HttpClient sharedClient].reachabilityManager;
    [reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"reachability changed..... %i", status);
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"..network not reachable....");
                [_networkUnreachableAlertView show];
                break;
                
        
            default:
                break;
        }
    }];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    // put a border around the play button
    [self.playButton.layer setBorderColor:[UIColor colorWithRed:209 green:238 blue:255 alpha:1.0].CGColor];
    [self.playButton.layer setBorderWidth:1.0f];
    
    // get the persistent beacons
    _beacons = [[CoreDataDao sharedDao] beacons];
    
    _rangedBeacons = [NSMutableArray array];
    
    NSString *user = [[NSUserDefaults standardUserDefaults] valueForKey:USER_NAME_KEY];
    if (user) {
        [self.userButton setTitle:[NSString stringWithFormat:@"Hi %@!", user] forState:UIControlStateNormal];

        self.playButton.hidden = NO;
        NSNumber *barScore = [[NSUserDefaults standardUserDefaults] valueForKey:BAR_SCORE_KEY];
        self.barScoreLabel.text = [barScore stringValue];
        
        // load the user's photo
        [self loadUserImage];
    }
    else {
        self.playButton.hidden = YES;
    }
    
    //set the bar score from the defaults
    NSInteger barScore = [[NSUserDefaults standardUserDefaults] integerForKey:BAR_SCORE_KEY];
    self.barScoreLabel.text = [NSString stringWithFormat:@"%li", (long)barScore];
    
    //CM called from the barTender instance
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [center addObserverForName:@"BarScoreUpdate" object:nil
                         queue:mainQueue usingBlock:^(NSNotification *note) {
                             
                             NSLog(@"BarScore Update notification handled");
                             
                             NSDictionary *userInfo = note.userInfo;
                             NSNumber *barScoreData = [userInfo objectForKey:@"barScore"];
                             
                             self.barScoreLabel.text = [NSString stringWithFormat:@"%@", barScoreData];
                             
                             NSLog(@"BarScore Update notification handled %@", barScoreData);
                             
                             
                         }];

        [center addObserverForName:@"UserWelcomeMessage" object:nil
                         queue:mainQueue usingBlock:^(NSNotification *note) {
                             
                             [TSMessage showNotificationInViewController:self
                                                                   title:NSLocalizedString(@"You made it!  Thanks for coming", nil)
                                                                subtitle:NSLocalizedString(@"Grab a drink and update your Bar Score", nil)
                                                                    type:TSMessageNotificationTypeSuccess
                                                                duration:TSMessageNotificationDurationAutomatic
                                                                callback:nil
                                                             buttonTitle:nil
                                                          buttonCallback:nil
                                                              atPosition:TSMessageNotificationPositionTop
                                                     canBeDismisedByUser:YES];
                             
                         }];
    
    [center addObserverForName:@"BarScoreUpdateFailed" object:nil
                         queue:mainQueue usingBlock:^(NSNotification *note) {
                             
                             NSLog(@"BarScore Update Failed");
                             
                             [TSMessage showNotificationInViewController:self
                                                                   title:NSLocalizedString(@"BarScoreUpdate Failed!", nil)
                                                                subtitle:NSLocalizedString(@"Check your network connection", nil)
                                                                    type:TSMessageNotificationTypeError
                                                                duration:TSMessageNotificationDurationAutomatic
                                                                callback:nil
                                                             buttonTitle:nil
                                                          buttonCallback:nil
                                                              atPosition:TSMessageNotificationPositionTop
                                                     canBeDismisedByUser:YES];
                             
                         }];
    
    [center addObserverForName:@"Bluetooth Status" object:nil queue:mainQueue usingBlock:^(NSNotification *note) {
        NSLog(@"..Bluetooth status changed....");
        
        NSDictionary *bluetoothInfo = note.userInfo;
        
        NSNumber *btStatus = [bluetoothInfo objectForKey:@"btState"];
        NSString *btStateString = [bluetoothInfo objectForKey:@"btStateString"];
        
        NSLog(@"btSTatus is %@", btStatus);
        NSLog(@"btStateString is %@", btStateString);
        
        if ([btStatus boolValue]) {
            self.isBluetoothOn = YES;
        }
        else {
            // bluetooth not on
//            [_bluetoothAlertView show];
            self.isBluetoothOn = NO;
            [self stopRanging];
        }
        
        /* note:  btStatus 1 : Bluetooth powered on.
                  btStatus 0 : bluetooth off.  Should disable all ranging operations.
         
                  if btStatus 0 then check the state string
        */
     
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    // see if the user has registered
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_KEY];
    
    if (!userId) {
        // prompt user for registration after slight delay to allow reachability to start monitoring
        [self promptForRegistration];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 40;
    if ([UIScreen mainScreen].bounds.size.height > 500) {
        // iphone 5
        height = 50;
    }
    
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_beacons count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    float y = 15.0;
    if ([UIScreen mainScreen].bounds.size.height > 500) {
        // iphone 5
        y = 20;
    }

    float width = 11.0;
    float heigth = 11.0;
    float maxX = 250;
    
    NSArray *beacons = [_beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tableIndex = %i", indexPath.row]];

    // dot will indicate proximity to beacon
    UIImageView *dotImage = (UIImageView *)[cell.contentView viewWithTag:100];

    if([beacons count]) {
        Beacon *beacon = beacons[0];
        if ([beacon.claimed boolValue]) {
            // beacon is claimed
            cell.imageView.image = [UIImage imageNamed:beacon.imageClaimed];
            cell.textLabel.text = @"Claimed";
            [cell.contentView.layer setBorderWidth:0.0f];
            
            // hide the dot
            [dotImage setHidden:YES];
        }
        else {
            // beacon is unclaimed

            // look for this beacon in the ranged beacon array
            NSArray *rangedBeacons = [_rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"major = %i", [beacon.major intValue]]];
            if ([rangedBeacons count]) {
                CLBeacon *rangedBeacon = rangedBeacons[0];
                NSLog(@"...beacon range is %1.2f", rangedBeacon.accuracy);

                if (rangedBeacon.accuracy > 0.0) {
                    beacon.accuracy = [NSNumber numberWithFloat:rangedBeacon.accuracy];
                }
                
                // postion range is 72 to 250, cap at 50 meters
                float x = 72 + (rangedBeacon.accuracy * 4.0);
                if (x > maxX) {
                    x = maxX;
                }
                if ((rangedBeacon.accuracy >= 0.0) && (rangedBeacon.accuracy <= CLAIMABLE_BEACON_THRESHOLD)) {
                    // user is very close to beacon allow to claim
                    dotImage.frame = CGRectMake(72, y, width, heigth);
                    [dotImage setImage:[UIImage imageNamed:@"dot_green"]];
                    cell.textLabel.text = @"    Claim It";
                    cell.imageView.image = [UIImage imageNamed:beacon.imageClaimed];
                    [cell.contentView.layer setBorderColor:[UIColor colorWithRed:51 green:204 blue:0 alpha:1.0].CGColor];
                    [cell.contentView.layer setBorderWidth:1.0f];
                }
                else if (rangedBeacon.accuracy > CLAIMABLE_BEACON_THRESHOLD) {
                    // user is not close enough to claim beacon
                    dotImage.frame = CGRectMake(x, y, width, heigth);
                    [dotImage setImage:[UIImage imageNamed:@"dot_blue"]];
                    cell.textLabel.text = @"";
                    [cell.contentView.layer setBorderWidth:0.0f];
                    cell.imageView.image = [UIImage imageNamed:beacon.imageUnclaimed];
                }
                
            }
            else {
                // beacon was not found, set to max
                // ignore
                beacon.accuracy = [NSNumber numberWithFloat:50.0];
                
                dotImage.frame = CGRectMake(maxX, y, width, heigth);
                [dotImage setImage:[UIImage imageNamed:@"dot_blue"]];
                cell.textLabel.text = @"";
                cell.imageView.image = [UIImage imageNamed:beacon.imageUnclaimed];
            }
        }
    }

    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // claim the beacon
    NSLog(@"didselect row....");
    
    NSArray *beacons = [_beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tableIndex = %i", indexPath.row]];

    // claim beacon
    if ([beacons count]) {
        Beacon *beacon = beacons[0];
        if (![beacon.claimed boolValue]) {
            if (beacon.accuracy) {
                NSLog(@"beacon accuracy %1.2f", [beacon.accuracy floatValue]);
                if ([beacon.accuracy floatValue] <= CLAIMABLE_BEACON_THRESHOLD) {
                    [self claimBeacon:beacon];
                }
            }
            
            [tableView reloadData];
        }
    }

}

#pragma mark - IBAction messages
- (IBAction)photoButtonTapped:(id)sender {
    if ([self networkReachable]) {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.delegate = self;
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        
        [self presentViewController:controller animated:YES completion:nil];
        
    }
}


- (IBAction)userButtonTapped:(id)sender {
    [self promptForRegistration];
}

- (IBAction)playButtonTapped:(id)sender {
    // make sure bluetooth is on and network connection is good
    if (self.isBluetoothOn) {
        if ([self networkReachable]) {
            [self startRanging];
        }
    }
    else {
        // bluetooth not on
        [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires bluetooth to be enabled. Please turn on Bluetooth in the Settings app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
    
}

#pragma mark - private methods
- (void)claimBeacon:(Beacon *)beacon {
    beacon.claimed = [NSNumber numberWithBool:YES];
    [[CoreDataDao sharedDao] save];
    
    NSInteger userId = [[NSUserDefaults standardUserDefaults] integerForKey:USER_ID_KEY];
    NSString *suserId = [NSString stringWithFormat:@"%li", (long)userId];
    
    NSDictionary *params = @{@"user_id": suserId, @"beacon_id" : [beacon.major stringValue]};

    // update leaderboard
    HttpClient *client = [HttpClient sharedClient];
    [client POST:CLAIM_BEACON_PATH parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"..claim successful....");
        beacon.ack = [NSNumber numberWithBool:YES];
        [[CoreDataDao sharedDao] save];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"claim beacon failed failed at url... %@", operation.request.URL);
        NSLog(@"error %@", error.localizedDescription);
        
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];
    }];
    
    if ([[_beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"claimed = NO"]] count] == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Congratulations" message:@"You claimed all the beacons! Now grab a drink to increase your Bar Score." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        
    }
}

- (void)promptForRegistration {
    if (![self networkReachable]) {
        return;
    }

    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];

    NSString *cancelButtonTitle = nil;
    if (userName) {
        // overwriting previous user, allow for Cancel
        cancelButtonTitle = @"Cancel";
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome to the Party" message:@" Enter your name. You can change this at anytime." delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *text = [alert textFieldAtIndex:0];
    text.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    text.clearButtonMode = UITextFieldViewModeWhileEditing;
    text.placeholder = @"Your name";
    text.text = userName;
    text.delegate = self;
    [alert show];
    
}

- (void)registerUser:(NSString *)user {
    NSLog(@"..Registering user... %@", user);
    HttpClient *client = [HttpClient sharedClient];
    NSUUID *device = [[UIDevice currentDevice] identifierForVendor];
    NSDictionary *params = @{@"name": user, @"device" : device.UUIDString};
    
    
	[self.navigationController showSGProgressWithDuration:4 andTintColor:[UIColor blueColor]];
    
    [client POST:REGISTER_PATH parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"registration successfull %@", responseObject);
        
        NSDictionary *attributes = responseObject;
        NSInteger userId = [attributes[@"userId"] integerValue];
        NSLog(@"User id from    response %li", (long)userId);
        [self.userButton setTitle:[NSString stringWithFormat:@"Hi %@!", user] forState:UIControlStateNormal];
        
        self.playButton.hidden = NO;
        
        [TSMessage showNotificationInViewController:self
                                              title:@"Yeah!"
                                           subtitle:@"Thanks for registering."
                                               type:TSMessageNotificationTypeSuccess
                                           duration:TSMessageNotificationDurationAutomatic
                                           callback:nil
                                        buttonTitle:nil
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionTop
                                canBeDismisedByUser:YES];
        
        [[NSUserDefaults standardUserDefaults] setInteger:userId forKey:USER_ID_KEY];
        [[NSUserDefaults standardUserDefaults] setValue:user forKey:USER_NAME_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.navigationController finishSGProgress];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"registration failed at url... %@", operation.request.URL);
        NSLog(@"error %@", error.localizedDescription);
        
        [TSMessage showNotificationInViewController:self
                                              title:NSLocalizedString(@"Registration Failed!", nil)
                                           subtitle:NSLocalizedString(@"Check your network connection", nil)
                                               type:TSMessageNotificationTypeError
                                           duration:TSMessageNotificationDurationAutomatic
                                           callback:nil
                                        buttonTitle:nil
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionTop
                                canBeDismisedByUser:YES];
        
        [self.navigationController finishSGProgress];
        
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];
    }];
    
}
- (void)updateUsername:(NSString *)username {
    NSLog(@"..change username... %@", username);
    HttpClient *client = [HttpClient sharedClient];
    
    NSInteger userId = [[NSUserDefaults standardUserDefaults] integerForKey:USER_ID_KEY];
    NSString *suserId = [NSString stringWithFormat:@"%li", (long)userId];

    NSDictionary *params = @{@"user_id": suserId, @"name" : username};
    
    [client POST:CHANGE_USER_PATH parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"update successfull %@", responseObject);
        
        [self.userButton setTitle:[NSString stringWithFormat:@"Hi %@!", username] forState:UIControlStateNormal];
        
        [[NSUserDefaults standardUserDefaults] setValue:username forKey:USER_NAME_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"registration failed at url... %@", operation.request.URL);
        NSLog(@"error %@", error.localizedDescription);
        
        [self.navigationController finishSGProgress];
        
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];
    }];
    
}

- (void)loadUserImage {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    
    // write the image to disk
    NSString *imagePath = [docsDir stringByAppendingPathComponent:USER_IMAGE_FILE];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:imagePath isDirectory:NO]) {
        NSLog(@"..loading image from %@", imagePath);
        
        /** cropping some of the image here */
//        CGRect cropRect = CGRectMake(0, 0, 320, 480);
        
        UIImage *original =[UIImage imageWithContentsOfFile:imagePath];
        
//        UIImage *newImage = [original croppedImage:cropRect];
        
     //  CM [self.photoButton setBackgroundImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        [self.photoButton setBackgroundImage:nil forState:UIControlStateNormal];
        self.photoButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.photoButton setBackgroundImage:original forState:UIControlStateNormal];
        
        [self.photoButton setTitle:@"" forState:UIControlStateNormal];
    }
    else {
//        [self.photoButton setBackgroundImage:nil forState:UIControlStateNormal];
//        [self.photoButton setTitle:@"Tap for Photo" forState:UIControlStateNormal];
    }
   
}

- (void)uploadUserImage:(NSData *)data {
    NSInteger userId = [[NSUserDefaults standardUserDefaults] integerForKey:USER_ID_KEY];
    NSString *suserId = [NSString stringWithFormat:@"%li", (long)userId];
    
    [self.navigationController showSGProgressWithDuration:4 andTintColor:[UIColor blueColor]];
    
    HttpClient *client = [HttpClient sharedClient];
    [client POST:UPLOAD_IMAGE_PATH parameters:@{@"userid" : suserId} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"filename" fileName:@"user.png" mimeType:@"image/png"];
    }
    success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"...content upload success.... %@", responseObject);
        [self.navigationController finishSGProgress];
        
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"..Failure uploading content .. %@", error.localizedDescription);
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];
        
        [self.navigationController finishSGProgress];
        
        [[[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"Please make sure you have a valid network connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
    
    
}

- (void)startRanging {
    NSLog(@"...starting to range.....");
    self.welcomeLabel.hidden = YES;
    self.playButton.hidden = YES;
    self.tableView.hidden = NO;
    self.iconBarImage.hidden = YES;
    
    
    // This location manager will be used to demonstrate how to range beacons.
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];

    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
    
    //CM start ranging the bar beacon when app is active
    [_locationManager startRangingBeaconsInRegion:[[BarTender sharedInstance] barRegion] ];

}

- (void)stopRanging {
    NSLog(@"..stopping ranging.....");
    [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
    [_locationManager stopRangingBeaconsInRegion:[[BarTender sharedInstance] barRegion] ];

    self.welcomeLabel.hidden = NO;
    self.playButton.hidden = NO;
    self.iconBarImage.hidden = NO;

    self.tableView.hidden = YES;
}

- (BOOL)networkReachable {
    BOOL reachable = NO;
    AFNetworkReachabilityManager *reachability = [HttpClient sharedClient].reachabilityManager;
    if (reachability.reachableViaWiFi || reachability.reachableViaWWAN) {
        reachable = YES;
        NSLog(@"...http client thinks network is REACHABLE......");
    }
    else {
        [_networkUnreachableAlertView show];
    }
    
    
    return reachable;
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"..alert view responder...");
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    
    // user tapped register
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *user = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_KEY];
    
    if (userId) {
        // change user name
        [self updateUsername:user];
    }
    else {
        // register user
        [self registerUser:user];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL enabled = YES;
    
    UITextField *user = [alertView textFieldAtIndex:0];
    enabled = ([[user.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0);
    
    return enabled;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"image picker delegate.....");
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
 
    // resize image
    image = [image resizedImage:CGSizeMake(image.size.width, image.size.height) interpolationQuality:kCGInterpolationHigh];
    
    // write the image to disk
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    NSString *imagePath = [docsDir stringByAppendingPathComponent:USER_IMAGE_FILE];
    NSData *fileData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    [fileData writeToFile:imagePath atomically:YES];
    
    // resize image for upload
    UIImage *newImage = [image resizedImage:CGSizeMake(400, 400) interpolationQuality:kCGInterpolationHigh ];
    
    NSData *data = [NSData dataWithData:UIImagePNGRepresentation(newImage)];
    
    [self loadUserImage];

    [self uploadUserImage:data];
}

#pragma mark - CLLocationManagerDelegate 
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"...locationManager didRangeBeacons....%lu", (unsigned long)[beacons count]);
    
    //CM should be two beacons if the region is the bar region
    if ([[region.proximityUUID UUIDString] isEqualToString:[[[BarTender sharedInstance] defaultProximityUUID] UUIDString]]) {
        [[BarTender sharedInstance] checkForBarProximity:beacons];
     
        //return out of this if it's the bar UUID
        return;
    }
    else {
        // claimable beacons
        _rangedBeacons.array = beacons;
        [self.tableView reloadData];
    }
    
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    BOOL allow = !((textField.text.length >= 11) && range.length == 0);

    return allow;
}

@end
