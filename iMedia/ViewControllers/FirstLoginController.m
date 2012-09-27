//
//  FirstLoginController.m
//  iMedia
//
//  Created by Xiaosi Li on 9/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "FirstLoginController.h"
#import "AppDelegate.h"

NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";


@implementation FirstLoginController


- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View lifecycle
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    jidField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setField:(UITextField *)field forKey:(NSString *)key
{
    if (field.text != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:field.text forKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)loginPressed:(id)sender
{
    [self setField:jidField forKey:kXMPPmyJID];
    [self setField:passwordField forKey:kXMPPmyPassword];
    
    //bypass the client library bug that : if manual fetch roster before authentication end, no msg
    //will be sent. This set autofetch property before connection.
    [self appDelegate].xmppRoster.autoFetchRoster = YES;
    
    if (![[self appDelegate] connect]) {
        self.passwordField.text = nil;
    } else {
        [self appDelegate].xmppRoster.autoFetchRoster = YES;
        [self performSegueWithIdentifier:@"WelcomeMsg" sender:self];
    }
}




- (IBAction)hideKeyboard:(id)sender {
    [sender resignFirstResponder];
    [self loginPressed:sender];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Getter/setter methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize jidField;
@synthesize passwordField;

@end
