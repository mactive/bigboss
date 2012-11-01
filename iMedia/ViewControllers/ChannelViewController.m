//
//  ChannelViewController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/14/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ChannelViewController.h"

#import "XMPPNetworkCenter.h"

#import "Channel.h"
#import "ModelHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+AFNetworking.h"

@interface ChannelViewController ()

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIButton *confirmButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIView *requestView;
@end

@implementation ChannelViewController

@synthesize channel;
@synthesize jsonData;
@synthesize nameLabel = _nameLabel;
@synthesize delegate;
@synthesize managedObjectContext;
@synthesize sendMsgButton = _sendMsgButton;
@synthesize contentView;
@synthesize confirmButton;
@synthesize cancelButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = BGCOLOR;
    
    self.requestView = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 300,300)];
    [self.requestView setBackgroundColor:[UIColor whiteColor]];
    [self.requestView.layer setMasksToBounds:YES];
    [self.requestView.layer setCornerRadius:10.0];
        

    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 200, 275, 40)];
    [self.confirmButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.confirmButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.confirmButton setTitle:T(@"加为好友") forState:UIControlStateNormal];
    [self.confirmButton setBackgroundImage:[UIImage imageNamed:@"button_arrow_bg.png"] forState:UIControlStateNormal];
    
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 250, 275, 40)];
    [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.cancelButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.cancelButton setTitle:T(@"取消") forState:UIControlStateNormal];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    // Now set content. Either user or jsonData must have value
    if (self.channel == nil) {
        self.title = [jsonData valueForKey:@"receive_jid"];
        [self.confirmButton setTitle:T(@"订阅此频道") forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(subscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.title = self.channel.ePostalID;
        [self.confirmButton setTitle:T(@"发送信息") forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 75, 75)];
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
    //    avatarImage setImage: //self.channel.avatar
    [avatarImage setImageWithURL:[NSURL URLWithString:@"http://ww1.sinaimg.cn/bmiddle/48933ee4jw1dydaveb47tj.jpg"]];
    [self.requestView addSubview:avatarImage];
    
    
    UILabel *label;
    label = [[UILabel alloc] initWithFrame:CGRectMake(110, 45, 170, 30)];
	label.font = [UIFont boldSystemFontOfSize:20.0];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(127, 127, 127);
    label.backgroundColor = [UIColor clearColor];
    label.text = self.channel.displayName;
    [self.requestView addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 260, 60)];
	label.font = [UIFont boldSystemFontOfSize:12.0];
    label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(158, 158, 158);
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.text = @"Li Qianming on the system construction of trial operation made summary speech.";//self.channel.signature;
    [self.requestView addSubview:label];
    
    
    [self.requestView addSubview:self.nameLabel];
    [self.requestView addSubview:self.confirmButton];
    [self.requestView addSubview:self.cancelButton];
    
    [self.view addSubview:self.requestView];
}

- (void)cancelRequest
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)sendMsgButtonPushed:(id)sender
{
    [self.delegate viewController:self didChatIdentity:self.channel];
}
-(void)subscribeButtonPushed:(id)sender
{
    NSString *nodeStr = [jsonData valueForKey:@"node_address"];
    Channel *newChannel = [ModelHelper findChannelWithNode:nodeStr inContext:self.managedObjectContext];
    if (newChannel == nil) {
        newChannel = [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:self.managedObjectContext];
        [ModelHelper populateIdentity:newChannel withJSONData:jsonData];
        newChannel.state = [NSNumber numberWithInt:IdentityStatePendingAddSubscription];
    }
    
    newChannel.subrequestID = [[XMPPNetworkCenter sharedClient] subscribeToChannel:nodeStr withCallbackBlock:nil];
}
@end
