/**
 * Copyright (C) 2014 The Simlar Authors.
 *
 * This file is part of Simlar. (https://www.simlar.org)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "SMLRVerifyNumberViewController.h"

#import "SMLRCreateAccount.h"
#import "SMLRCredentials.h"
#import "SMLRLog.h"
#import "SMLRPhoneNumber.h"
#import "SMLRSettings.h"

@interface SMLRVerifyNumberViewController ()

@property (weak, nonatomic) IBOutlet UITextField *countryNumber;
@property (weak, nonatomic) IBOutlet UITextField *telephoneNumber;

- (IBAction)continueButtonPressed:(id)sender;

@end

@implementation SMLRVerifyNumberViewController

- (instancetype)initWithCoder:(NSCoder *const)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self == nil) {
        SMLRLogE(@"unable to create SMLRVerifyNumberViewController");
        return nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _countryNumber.text = [SMLRPhoneNumber getCountryNumberBasedOnCurrentLocale];

    [SMLRSettings saveCreateAccountStatus:SMLRCreateAccountStatusAgreed];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/// hide keyboard if background is touched
- (void)touchesBegan:(NSSet *const)touches withEvent:(UIEvent *const)event
{
    [self.view endEditing:YES];
}

+ (void)showErrorAlertMessage:(NSString *const)message
{
    [[[UIAlertView alloc] initWithTitle:@"Create Account Error" message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
}

- (IBAction)continueButtonPressed:(id)sender
{
    if ([_countryNumber.text length] == 0) {
        [SMLRVerifyNumberViewController showErrorAlertMessage:@"Please enter your country code"];
        return;
    }

    if ([_telephoneNumber.text length] == 0) {
        [SMLRVerifyNumberViewController showErrorAlertMessage:@"Please enter your telephone number"];
        return;
    }

    /// Verify and store region
    NSString *const region = [SMLRPhoneNumber getRegionWithNumber:_countryNumber.text];
    if ([region length] == 0) {
        SMLRLogI(@"Could not parse country code: number=%@", _countryNumber.text);
        [SMLRVerifyNumberViewController showErrorAlertMessage:@"Could not parse country code"];
        return;
    }
    SMLRLogI(@"default region: %@", region);
    [SMLRSettings saveDefaultRegion:region];

    /// Verify telephone number
    SMLRPhoneNumber *const phoneNumber = [[SMLRPhoneNumber alloc] initWithNumber:[NSString stringWithFormat:@"+%@%@", _countryNumber.text, _telephoneNumber.text]];
    if (![phoneNumber isValid]) {
        [SMLRVerifyNumberViewController showErrorAlertMessage:@"The telephone number you have entered is not valid. Please check."];
        return;
    }


    [SMLRCreateAccount requestWithTelephoneNumber:[phoneNumber getRegistrationNumber] completionHandler:^(NSString *const simlarId, NSString *const password, NSError *const error)
     {
         if (error != nil) {
             SMLRLogI(@"failed account creation request: error=%@", error);
             [SMLRVerifyNumberViewController showErrorAlertMessage:error.localizedDescription];
             return;
         }

         SMLRLogI(@"successful account creation request with new simlarId=%@ => saving credentials and opening create account view controller", simlarId);
         if (![SMLRCredentials saveWithTelephoneNumber:[phoneNumber getGuiNumber] simlarId:simlarId password:password]) {
             SMLRLogI(@"Failed to save credentials");
             [SMLRVerifyNumberViewController showErrorAlertMessage:@"Failed to save credentials"];
             return;
         }
         [SMLRSettings saveCreateAccountStatus:SMLRCreateAccountStatusWaitingForSms];

         UIViewController *viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"SMLRCreateAccountViewController"];
         [self presentViewController:viewController animated:YES completion:nil];
     }];
}

@end
