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
#import "MBProgressHUD.h"
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
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface AddFriendByIDController () <UITextFieldDelegate,MBProgressHUDDelegate>
{
    MBProgressHUD * HUD;
}

@property (strong, nonatomic) UILabel *desc;
@property (strong, nonatomic) UITextField *field;
@property (strong, nonatomic) UIButton *doneButton;

@end

@implementation AddFriendByIDController

@synthesize desc;
@synthesize field;
@synthesize doneButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
     }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = BGCOLOR;
    
    self.desc = [[UILabel alloc]initWithFrame:CGRectMake(30, 20, 300 , 30)];
    
    [self.desc setFont:[UIFont boldSystemFontOfSize:20.0]];
    self.desc.text = T(@"用户名,用户ID");
    [self.desc setBackgroundColor:[UIColor clearColor]];
    self.desc.textColor = [UIColor grayColor];
    self.desc.shadowColor = [UIColor whiteColor];
    self.desc.shadowOffset = CGSizeMake(0, 1);

    self.field = [[UITextField alloc]initWithFrame:CGRectMake(22.5 , 60, 275, 40)];
    self.field.font = [UIFont systemFontOfSize:26.0];
    [self.field setBorderStyle:UITextBorderStyleRoundedRect];
//    [self.field.layer setMasksToBounds:YES];
//    [self.field.layer setCornerRadius:5.0];
    self.field.textColor = [UIColor grayColor];
    self.field.backgroundColor = [UIColor whiteColor];
    self.field.delegate = self;
    self.field.autocorrectionType = UITextAutocorrectionTypeNo;
    self.field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.field.returnKeyType = UIReturnKeyGo;
    
    
    self.doneButton  = [[UIButton alloc] initWithFrame:CGRectMake(22.5, 115, 275, 40)];
    [self.doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.doneButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.doneButton setTitle:T(@"搜索") forState:UIControlStateNormal];
    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"button_arrow_bg.png"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.doneButton];
    [self.view addSubview:self.desc];
    [self.view addSubview:self.field];
    
    [field becomeFirstResponder];

    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)getDict
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: field.text, @"guid", @"1", @"op", nil];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = T(@"正在搜索");
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get config JSON received: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        if ([type isEqualToString:@"user"]) {
            sleep(1);
            [HUD hide:YES];
            
            ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
            controller.jsonData = responseObject;
            controller.managedObjectContext = [self appDelegate].context;
            NSLog(@"self delegate %@",[self appDelegate]);
            
            // Pass the selected object to the new view controller.
            [controller setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:controller animated:YES];
            
        } else if ([type isEqualToString:@"channel"]) {
            sleep(1);
            [HUD hide:YES];

            ChannelViewController *controller = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
            controller.jsonData = responseObject;
            controller.managedObjectContext = [self appDelegate].context;
            
            [self.navigationController pushViewController:controller animated:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"error received: %@", error);
    }];

}


- (void)doneAction{
    if (field.text == nil) {
        return;
    }else {
        [self getDict];
    }
    [field resignFirstResponder];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (field.text == nil) {
        return NO;
    }
    
    [self getDict];
    
    if ([self.field isEqual:textField]) {
        return [field resignFirstResponder];
    }
    
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
