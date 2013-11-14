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

static float const CLAIMABLE_BEACON_THRESHOLD = 2.0f;   // 2 meters

@interface InitialViewController ()

@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSArray *beacons;
@property (nonatomic, strong) NSMutableArray *rangedBeacons;
@property (nonatomic, strong) NSString *originalWelcomeText;

- (void)promptForRegistration;
- (void)registerUser:(NSString *)user;
- (void)updateUsername:(NSString *)username;
- (void)uploadUserImage:(NSString *)imagePath;
- (void)claimBeacon:(Beacon *)beacon;

- (void)loadUserImage;
- (void)startRanging;
- (void)stopRanging;

@end

static NSString * const USER_ID_KEY = @"userId";
static NSString * const USER_NAME_KEY = @"userName";
static NSString * const USER_IMAGE_FILE = @"user_image.png";
static NSString * const BAR_SCORE_KEY = @"barScore";

@implementation InitialViewController


- (void)viewDidLoad
{
    _originalWelcomeText = self.welcomeLabel.text;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    // get the persistent beacons
    _beacons = [[CoreDataDao sharedDao] beacons];
    
    _rangedBeacons = [NSMutableArray array];
    
    NSString *user = [[NSUserDefaults standardUserDefaults] valueForKey:USER_NAME_KEY];
    if (user) {
        [self.userButton setTitle:[NSString stringWithFormat:@"Hi %@!", user] forState:UIControlStateNormal];

        // load the user's photo
        [self loadUserImage];
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
    
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    // see if the user has registered
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_KEY];
    
    if (!userId) {
        // prompt user for registration
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_beacons count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    float y = 20.0;
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
                    cell.textLabel.text = @"   Claim It";
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
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.delegate = self;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//        controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    [self presentViewController:controller animated:YES completion:nil];
    
    NSLog(@"this is a change");
    NSLog(@"this is another change");
}



- (IBAction)startOverTapped:(id)sender {
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:USER_NAME_KEY];
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:USER_ID_KEY];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    
    // remove user photo
    NSString *imagePath = [docsDir stringByAppendingPathComponent:USER_IMAGE_FILE];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:imagePath isDirectory:NO]) {
        // remove the file
        NSError *error = nil;
        [fileManager removeItemAtPath:imagePath error:&error];
    
    }
    
    [self loadUserImage];
    
    [self promptForRegistration];
    
}

- (IBAction)rangingSwitchChanged:(id)sender {
    if (_rangingSwitch.on) {
        [self startRanging];
    }
    else {
        [self stopRanging];
    }
    
}

- (IBAction)userButtonTapped:(id)sender {
    [self promptForRegistration];
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
}

- (void)promptForRegistration {
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];

    NSString *cancelButtonTitle = nil;
    if (userName) {
        // overwriting previous user, allow for Cancel
        cancelButtonTitle = @"Cancel";
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ObjectLab Holiday Party" message:@"Welcome to the party. Please enter your name (You can change this at anytime):" delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:@"OK", nil];
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
        [self.photoButton setBackgroundImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        
        [self.photoButton setTitle:@"" forState:UIControlStateNormal];
    }
    else {
//        [self.photoButton setBackgroundImage:nil forState:UIControlStateNormal];
//        [self.photoButton setTitle:@"Tap for Photo" forState:UIControlStateNormal];
    }
   
}

- (void)uploadUserImage:(NSString *)imagePath {
    NSInteger userId = [[NSUserDefaults standardUserDefaults] integerForKey:USER_ID_KEY];
    NSString *suserId = [NSString stringWithFormat:@"%li", (long)userId];
    
    NSLog(@"upload image for user %li with %@", (long)userId, imagePath);
    
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    
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
    self.tableView.hidden = NO;
    
    self.image1.hidden = YES;
    self.image2.hidden = YES;
    self.image3.hidden = YES;
    self.image4.hidden = YES;
    self.image5.hidden = YES;
    self.image6.hidden = YES;
    
    
    // This location manager will be used to demonstrate how to range beacons.
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];

    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
}

- (void)stopRanging {
    NSLog(@"..stopping ranging.....");
    [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
    
    self.welcomeLabel.hidden = NO;
    self.tableView.hidden = YES;
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
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    //CM for new resize and image orientation fixes 
    CGSize constraint = CGSizeMake(400, 400);
    UIImage *newImage = [image resizedImage:constraint interpolationQuality:kCGInterpolationHigh ];
    
    NSData *data = [NSData dataWithData:UIImagePNGRepresentation(newImage)];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    
    // write the image to disk
    NSString *imagePath = [docsDir stringByAppendingPathComponent:USER_IMAGE_FILE];
    [data writeToFile:imagePath atomically:YES];
    
    [self loadUserImage];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self uploadUserImage:imagePath];

}

#pragma mark - CLLocationManagerDelegate 
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"...locationManager didRangeBeacons....%lu", (unsigned long)[beacons count]);
    

    _rangedBeacons.array = beacons;
    
    [self.tableView reloadData];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    BOOL allow = !((textField.text.length >= 11) && range.length == 0);

    return allow;
}

@end
