//
//  FirstLoginController.m
//  iMedia
//
//  Created by Xiaosi Li on 9/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "FirstLoginController.h"
#import "AppDelegate.h"

#import "AppNetworkAPIClient.h"
#import "XMPPNetworkCenter.h"
#import "SBJson.h"
#import "DDLog.h"
#import <unistd.h>

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


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
    
    jidField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyUsername];
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
    
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    self.view.backgroundColor = [UIColor redColor];
    [self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.labelText = @"Loading";
//    [HUD showWhileExecuting:@selector(myTask) onTarget:self withObject:nil animated:YES];

    [[AppNetworkAPIClient sharedClient] loginWithUsername:jidField.text andPassword:passwordField.text withBlock:^(id responseObject, NSError *error) {
        if (error == nil) {
            
            NSString* jid = [responseObject valueForKey:@"jid"];
            NSString *jPassword = [responseObject valueForKey:@"jpass"];
            NSString *guid= [[responseObject valueForKey:@"guid"] stringValue];
            
            [self performSegueWithIdentifier:@"WelcomeMsg" sender:self];
            
            if (![[XMPPNetworkCenter sharedClient] connectWithUsername:jid andPassword:jPassword])
            {
                DDLogVerbose(@"%@: %@ cannot connect to XMPP server", THIS_FILE, THIS_METHOD);
            }
            
            [HUD hide:YES afterDelay:2];
            if (HUD.hidden){
                [[self appDelegate] createMeWithUsername:jidField.text password:passwordField.text jid:jid jidPasswd:jPassword andGUID:guid];
            }

            
        } else {
            DDLogError(@"NSError received during login: %@", error);
        }
        
    }];
    
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
