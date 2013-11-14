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

@interface InitialViewController : UIViewController<UITextFieldDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *slideToBeginLabel;
@property (strong, nonatomic) IBOutlet UIButton *userButton;
@property (strong, nonatomic) IBOutlet UIButton *photoButton;
@property (strong, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (strong, nonatomic) IBOutlet UISwitch *rangingSwitch;
@property (strong, nonatomic) IBOutlet UILabel *beaconsFoundLabel;
@property (strong, nonatomic) IBOutlet UILabel *barScoreLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIImageView *image1;
@property (strong, nonatomic) IBOutlet UIImageView *image2;
@property (strong, nonatomic) IBOutlet UIImageView *image3;
@property (strong, nonatomic) IBOutlet UIImageView *image4;
@property (strong, nonatomic) IBOutlet UIImageView *image5;
@property (strong, nonatomic) IBOutlet UIImageView *image6;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

- (IBAction)photoButtonTapped:(id)sender;
- (IBAction)rangingSwitchChanged:(id)sender;
- (IBAction)userButtonTapped:(id)sender;
- (IBAction)playButtonTapped:(id)sender;

@end
