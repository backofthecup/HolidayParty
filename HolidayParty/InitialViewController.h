//
//  FirstViewController.h
//  HolidayParty
//
//  Created by Eric Mansfield on 10/29/13.
//  Copyright (c) 2013 Eric Mansfield. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InitialViewController : UIViewController<UITextFieldDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *userButton;
@property (strong, nonatomic) IBOutlet UIButton *photoButton;
@property (strong, nonatomic) IBOutlet UILabel *welcomeLabel;

- (IBAction)photoButtonTapped:(id)sender;
- (IBAction)userButtonTapped:(id)sender;
@end
