//
//  FirstViewController.m
//  HolidayParty
//
//  Created by Eric Mansfield on 10/29/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import "InitialViewController.h"
#import "HttpClient.h"

@interface InitialViewController ()
- (void)promptForRegistration;
- (void)registerUser:(NSString *)user;
- (void)uploadUserImage:(NSString *)imagePath;;
- (void)loadUserImage;

@end

static NSString * const USER_ID_KEY = @"userId";
static NSString * const USER_NAME_KEY = @"userName";
static NSString * const USER_IMAGE_FILE = @"user_image.png";

@implementation InitialViewController


- (void)viewDidLoad
{
    NSString *user = [[NSUserDefaults standardUserDefaults] valueForKey:USER_NAME_KEY];
    if (user) {
        [self.userButton setTitle:user forState:UIControlStateNormal];
        self.userButton.hidden = NO;

        // load the user's photo
        [self loadUserImage];
    }
    
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    // see if the user has registered
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_KEY];
    
    if (!userId) {
//        // prompt user for registration
//        UINavigationController *registrationController = [self.storyboard instantiateViewControllerWithIdentifier:@"RegistrationNavigationController"];
//        [self presentViewController:registrationController animated:NO completion:nil];
        
        [self promptForRegistration];
        
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)photoButtonTapped:(id)sender {
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.delegate = self;
    controller.mediaTypes = @[(NSString *) kUTTypeImage];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)userButtonTapped:(id)sender {
    [self promptForRegistration];
}

- (IBAction)startOverTapped:(id)sender {
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:USER_NAME_KEY];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.userButton.hidden = YES;
    
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

#pragma mark - private methods
- (void)promptForRegistration {
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];

    NSString *cancelButtonTitle = nil;
    if (userName) {
        // overwriting previous user, allow for Cancel
        cancelButtonTitle = @"Cancel";
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ObjectLab Holiday Party" message:@"Welcome to the ObjectLab Holiday Party. Please reigster by entering your name (You can change this at anytime):" delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:@"Register", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *text = [alert textFieldAtIndex:0];
    text.placeholder = @"Your name";
    text.delegate = self;
    [alert show];
    
}

- (void)registerUser:(NSString *)user {
    NSLog(@"..Registering user... %@", user);
    HttpClient *client = [HttpClient sharedClient];
    NSUUID *device = [[UIDevice currentDevice] identifierForVendor];
    NSDictionary *params = @{@"name": @"eric", @"device" : device.UUIDString};
    
    [client postPath:REGISTER_PATH parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"registration successfull %@", responseObject);
        
        NSDictionary *attributes = responseObject;
        NSInteger userId = [attributes[@"userId"] integerValue];
        NSLog(@"User id from response %i", userId);
        [self.userButton setTitle:user forState:UIControlStateNormal];
        
        self.userButton.hidden = NO;
        
        [[NSUserDefaults standardUserDefaults] setInteger:userId forKey:USER_ID_KEY];
        [[NSUserDefaults standardUserDefaults] setValue:user forKey:USER_NAME_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"registration failed at url... %@", operation.request.URL);
        NSLog(@"error %@", error.localizedDescription);
        
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
        [self.photoButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.photoButton setTitle:@"Tap for Photo" forState:UIControlStateNormal];
    }
   
}

- (void)uploadUserImage:(NSString *)imagePath {
    NSInteger userId = [[NSUserDefaults standardUserDefaults] integerForKey:USER_ID_KEY];
    NSString *suserId = [NSString stringWithFormat:@"%i", userId];
    
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    
    HttpClient *client = [HttpClient sharedClient];
    NSMutableURLRequest *request = [client multipartFormRequestWithMethod:@"POST" path:UPLOAD_IMAGE_PATH parameters:@{@"userId": suserId} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"upload" fileName:@"filename" mimeType:@"image/png"];
    }];
    
    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"...content upload success.... %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"..Failure uploading content .. %@", error.localizedDescription);
        NSDictionary *userInfo = error.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            NSLog(@"%@ - %@", key, obj);
        }];

        [[[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"Please make sure you have a valid network connection. You can retry this by tapping the Log tab at the bottom." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        
    }];
    
    [client enqueueHTTPRequestOperation:operation];
    
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
    
    [self registerUser:user];
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
    NSData *data = [NSData dataWithData:UIImagePNGRepresentation(image)];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    
    // write the image to disk
    NSString *imagePath = [docsDir stringByAppendingPathComponent:USER_IMAGE_FILE];
    [data writeToFile:imagePath atomically:YES];

    [self loadUserImage];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self uploadUserImage:imagePath];

}


@end
