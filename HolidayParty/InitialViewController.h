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

@property (strong, nonatomic) IBOutlet UIButton *userButton;
@property (strong, nonatomic) IBOutlet UIButton *photoButton;
@property (strong, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (strong, nonatomic) IBOutlet UILabel *barScoreLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIImageView *iconBarImage;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) id barScoreObserver;
@property (strong, nonatomic) id barScoreFailedObserver;
@property (strong, nonatomic) id bluetoothStatusObserver;
@property (strong, nonatomic) id welcomeMessageObserver;


- (IBAction)photoButtonTapped:(id)sender;
- (IBAction)userButtonTapped:(id)sender;
- (IBAction)playButtonTapped:(id)sender;

@end
