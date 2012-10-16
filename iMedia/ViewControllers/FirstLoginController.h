//
//  FirstLoginController.h
//  iMedia
//
//  Created by Xiaosi Li on 9/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface FirstLoginController : UIViewController
{
    UITextField *jidField;
    UITextField *passwordField;
}

@property (nonatomic,strong) IBOutlet UITextField *jidField;
@property (nonatomic,strong) IBOutlet UITextField *passwordField;

- (IBAction)loginPressed:(id)sender;
- (IBAction)hideKeyboard:(id)sender;

@end
