//
//  FirstViewController.h
//  HolidayParty
//
//  Created by Eric Mansfield on 10/29/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "UINavigationController+SGProgress.h"

@interface InitialViewController : UIViewController<UITextFieldDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *userButton;
@property (strong, nonatomic) IBOutlet UIButton *photoButton;
@property (strong, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (strong, nonatomic) IBOutlet UISwitch *rangingSwitch;
@property (strong, nonatomic) IBOutlet UIButton *claimBeaconButton;
@property (strong, nonatomic) IBOutlet UILabel *beaconsFoundLabel;

- (IBAction)photoButtonTapped:(id)sender;
- (IBAction)claimBeaconTapped:(id)sender;
- (IBAction)userButtonTapped:(id)sender;
- (IBAction)startOverTapped:(id)sender;
- (IBAction)rangingSwitchChanged:(id)sender;

@end
