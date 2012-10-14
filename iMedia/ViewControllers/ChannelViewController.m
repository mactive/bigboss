//
//  ChannelViewController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/14/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ChannelViewController.h"

#import "Channel.h"

@interface ChannelViewController ()

@end

@implementation ChannelViewController

@synthesize channel;
@synthesize jsonData;

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
        self.title = [jsonData valueForKey:@"jid"];
        [self.sendMsgButton setTitle:NSLocalizedString(@"subscribe", nil) forState:UIControlStateNormal];
        
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

@end
