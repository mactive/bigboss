//
//  RequestViewController.m
//  iMedia
//
//  Created by qian meng on 12-10-29.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "RequestViewController.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+timesince.h"
#import "UIImageView+AFNetworking.h"
#import "XMPPNetworkCenter.h"
#import "UIImageView+AFNetworking.h"
#import "ServerDataTransformer.h"

@interface RequestViewController ()

@end

@implementation RequestViewController

@synthesize requestView;
@synthesize titleLabel;
@synthesize timeLabel;
@synthesize contentView;
@synthesize confirmButton;
@synthesize cancelButton;
@synthesize requestDict;
@synthesize jsonData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"Request");
    self.view.backgroundColor = BGCOLOR;
    NSLog(@"%@",self.jsonData);
    // fake data
    NSDate * date = [ServerDataTransformer getDateFromServerJSON:jsonData];
    NSURL * avatarUrl = [[NSURL alloc] initWithString:[ServerDataTransformer getAvatarFromServerJSON:jsonData]]; 
    self.requestDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [ServerDataTransformer getNicknameFromServerJSON:jsonData],@"name",
                            date,@"date",
                            avatarUrl,@"avatar",
                            [ServerDataTransformer getSignatureFromServerJSON:jsonData],@"signature", nil];

	// Do any additional setup after loading the view.
    
    self.requestView = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 300,300)];
    [self.requestView setBackgroundColor:[UIColor whiteColor]];
    [self.requestView.layer setMasksToBounds:YES];
    [self.requestView.layer setCornerRadius:10.0];
    
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 250, 20)];
	self.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	self.titleLabel.textAlignment = UITextAlignmentLeft;
    self.titleLabel.textColor = RGBCOLOR(107, 107, 107);
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.text = [[NSString alloc] initWithFormat:@" %@  %@",[self.jsonData objectForKey:@"guid"], T(@"请求加你为好友") ];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 40, 250, 20)];
	self.timeLabel.font = [UIFont boldSystemFontOfSize:14.0];
	self.timeLabel.textAlignment = UITextAlignmentLeft;
    self.timeLabel.textColor = RGBCOLOR(153, 153, 153);
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.text = [[self.requestDict objectForKey:@"date"] timesince];
    
    [self initContentView];
    
    self.confirmButton = 
    
    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 200, 275, 40)];
    [self.confirmButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.confirmButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.confirmButton setTitle:T(@"加为好友") forState:UIControlStateNormal];
    [self.confirmButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    [self.confirmButton addTarget:self action:@selector(confirmRequest) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 250, 275, 40)];
    [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.cancelButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.cancelButton setTitle:T(@"取消") forState:UIControlStateNormal];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.requestView addSubview:self.titleLabel];
    [self.requestView addSubview:self.timeLabel];
    [self.requestView addSubview:self.confirmButton];
    [self.requestView addSubview:self.cancelButton];
    
    
    [self.view addSubview:self.requestView];
}

- (void)initContentView
{
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(15, 70, 270, 100)];
    self.contentView.backgroundColor = RGBCOLOR(235, 235, 235);
    [self.contentView.layer setMasksToBounds:YES];
    [self.contentView.layer setCornerRadius:5.0];
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 75, 75)];
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
//    avatarImage setImage:
    [avatarImage setImageWithURL:[self.requestDict objectForKey:@"avatar"]];
    [self.contentView addSubview:avatarImage];

    
    UILabel *label;
    label = [[UILabel alloc] initWithFrame:CGRectMake(100, 10, 170, 20)];
	label.font = [UIFont boldSystemFontOfSize:14.0];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(127, 127, 127);
    label.backgroundColor = [UIColor clearColor];
    label.text = [self.requestDict objectForKey:@"name"];
    [self.contentView addSubview:label];

    label = [[UILabel alloc] initWithFrame:CGRectMake(100, 30, 170, 60)];
	label.font = [UIFont boldSystemFontOfSize:12.0];
    label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(158, 158, 158);
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.text = [self.requestDict objectForKey:@"signature"];
    [self.contentView addSubview:label];   

    [self.requestView addSubview:self.contentView];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mask - button action
////////////////////////////////////////////////////////////////////////////////////////////////

- (void)confirmRequest
{
    NSString *jidStr = [self.jsonData valueForKey:@"ePostalID"];
    [[XMPPNetworkCenter sharedClient] acceptPresenceSubscriptionRequestFrom:jidStr andAddToRoster:YES];
}

- (void)cancelRequest
{
    NSString *jidStr = [self.jsonData valueForKey:@"ePostalID"];
    [[XMPPNetworkCenter sharedClient] rejectPresenceSubscriptionRequestFrom:jidStr];
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
