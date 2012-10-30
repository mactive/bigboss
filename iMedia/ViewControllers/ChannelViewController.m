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

@interface ChannelViewController ()

@end

@implementation ChannelViewController

@synthesize channel;
@synthesize jsonData;
@synthesize nameLabel = _nameLabel;
@synthesize delegate;
@synthesize managedObjectContext;
@synthesize sendMsgButton = _sendMsgButton;

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
    
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(LARGE_GAP, SMALL_GAP, 200.0f, 40.0f)];
    _nameLabel.backgroundColor = [UIColor redColor];
    _nameLabel.textColor = [UIColor blackColor];
    [_nameLabel setText:@"label"];
    [_nameLabel setMinimumFontSize:20.0];
    [self.view addSubview:self.nameLabel];
    
    self.sendMsgButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 300.0f, 80.0f, 30.0f)];
    [self.sendMsgButton setTag:0];
    [self.sendMsgButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.sendMsgButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.sendMsgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.sendMsgButton setBackgroundColor:[UIColor yellowColor]];
    
    [self.view addSubview:self.sendMsgButton];
    
    // Now set content. Either user or jsonData must have value
    if (self.channel == nil) {
        self.title = [jsonData valueForKey:@"receive_jid"];
        [self.sendMsgButton setTitle:NSLocalizedString(@"subscribe", nil) forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(subscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        
    } else {
        self.title = self.channel.ePostalID;
        [self.sendMsgButton setTitle:NSLocalizedString(@"Send Msg", nil) forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
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
