//
//  AddFriendByIDController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/14/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AddFriendByIDController.h"
#import "AppNetworkAPIClient.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#import "User.h"
#import "ModelHelper.h"
#import "ContactDetailController.h"
#import "ChannelViewController.h"

@interface AddFriendByIDController () <UITextFieldDelegate>

@property (strong, nonatomic) UILabel *desc;
@property (strong, nonatomic) UITextField *field;

@end

@implementation AddFriendByIDController

@synthesize desc;
@synthesize field;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
     }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    desc = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 280, 40)];
    
    desc.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    desc.text = @"JID/GUID";
    desc.textColor = [UIColor blueColor];

    field = [[UITextField alloc]initWithFrame:CGRectMake(10, 60, 320, 40)];
    field.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];;
    field.placeholder = @"input here";
    field.textColor = [UIColor blueColor];
    field.backgroundColor = [UIColor whiteColor];
    field.delegate = self;
    
    self.view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:desc];
    [self.view addSubview:field];
    
    [field becomeFirstResponder];

    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
   
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (field.text == nil) {
        return NO;
    }
    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: field.text, @"guid", @"1", @"op", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get config JSON received: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        if ([type isEqualToString:@"user"]) {
            ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
            controller.jsonData = responseObject;
            
            // Pass the selected object to the new view controller.
            [self.navigationController pushViewController:controller animated:YES];
            
        } else if ([type isEqualToString:@"channel"]) {
            ChannelViewController *controller = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
            controller.jsonData = responseObject;
            [self.navigationController pushViewController:controller animated:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"error received: %@", error);
    }];

    
    [field resignFirstResponder];
    
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //
    ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
