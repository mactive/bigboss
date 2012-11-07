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
#import "MBProgressHUD.h"
#import "ServerDataTransformer.h"
#import "AppNetworkAPIClient.h"

@interface ChannelViewController ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}

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
        

    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(12.5, 200, 275, 40)];
    [self.confirmButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.confirmButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.confirmButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(12.5, 250, 275, 40)];
    [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.cancelButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];

    
    
     
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 75, 75)];
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];

    [self.requestView addSubview:avatarImage];
    
    
    UILabel *nameLabel;
    nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 45, 170, 30)];
	nameLabel.font = [UIFont boldSystemFontOfSize:20.0];
	nameLabel.textAlignment = UITextAlignmentLeft;
    nameLabel.textColor = RGBCOLOR(127, 127, 127);
    nameLabel.backgroundColor = [UIColor clearColor];
    
    [self.requestView addSubview:nameLabel];
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 260, 60)];
	infoLabel.font = [UIFont boldSystemFontOfSize:12.0];
    infoLabel.textAlignment = UITextAlignmentLeft;
    infoLabel.textColor = RGBCOLOR(158, 158, 158);
    infoLabel.numberOfLines = 0;
    infoLabel.backgroundColor = [UIColor clearColor];

    [self.requestView addSubview:infoLabel];
    
    
    // Now set content. Either user or jsonData must have value
    if (self.channel == nil) {
        self.title = [ServerDataTransformer getNicknameFromServerJSON:jsonData];
        nameLabel.text = [ServerDataTransformer getNicknameFromServerJSON:jsonData];
        infoLabel.text = [ServerDataTransformer getSelfIntroductionFromServerJSON:jsonData];
        NSString *thumbnail = [ServerDataTransformer getThumbnailFromServerJSON:jsonData];
        if (StringHasValue(thumbnail)) {
            [avatarImage setImageWithURL:[NSURL URLWithString:thumbnail] placeholderImage:[UIImage imageNamed:@"company_thumbnail_placeholder.png"]];
        } else {
            [avatarImage setImage:[UIImage imageNamed:@"company_thumbnail_placeholder.png"]];
        }
        [self.confirmButton setTitle:T(@"订阅此频道") forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(subscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setTitle:T(@"取消") forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelRequest:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.title = self.channel.displayName;
        infoLabel.text = self.channel.selfIntroduction;
        nameLabel.text = self.channel.displayName;
        if (channel.thumbnailImage != nil) {
            [avatarImage setImage:channel.thumbnailImage];
        } else if (StringHasValue(channel.thumbnailURL)) {
            [[AppNetworkAPIClient sharedClient] loadImage:channel.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
                [avatarImage setImage:image];
                self.channel.thumbnailImage = image;
            }];
        } else {
            [avatarImage setImage:[UIImage imageNamed:@"company_thumbnail_placeholder.png"]];
        }
        
        [self.confirmButton setTitle:T(@"发送信息") forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setTitle:T(@"取消订阅") forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(unSubscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    }

    
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
    Channel *newChannel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
    if (newChannel == nil) {
        newChannel = [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:self.managedObjectContext];
        [[ModelHelper sharedInstance] populateIdentity:newChannel withJSONData:jsonData];
        newChannel.state = [NSNumber numberWithInt:IdentityStatePendingAddSubscription];
    }
    
    newChannel.subrequestID = [[XMPPNetworkCenter sharedClient] subscribeToChannel:nodeStr withCallbackBlock:^(NSError *error) {
        
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.labelText = T(@"订阅中");
        
        [HUD showAnimated:YES whileExecutingBlock:^{
            sleep(2);
            [HUD hide:YES];
        } completionBlock:^{
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
            HUD.mode = MBProgressHUDModeCustomView;
            HUD.labelText = T(@"订阅成功");
            [HUD hide:YES afterDelay:2];
            
            [self.confirmButton setTitle:T(@"退订此频道") forState:UIControlStateNormal];
            [self.confirmButton removeTarget:self action:@selector(subscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
            [self.confirmButton addTarget:self action:@selector(unSubscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];

        }];

    }];
}

-(void)unSubscribeButtonPushed:(id)sender
{
    if (self.channel == nil) {
        NSLog(@"CRITICAL ERROR: Display unsubscribe button with empty channel object");
        return;
    }
    
    if (self.channel.state.intValue != IdentityStateActive) {
        return;
        
    }
    self.channel.subrequestID = [[XMPPNetworkCenter sharedClient] unsubscribeToChannel:self.channel.node withCallbackBlock:^(NSError *error) {

        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.labelText = T(@"退定中");

        [HUD showAnimated:YES whileExecutingBlock:^{
            sleep(2);
            [HUD hide:YES];
        } completionBlock:^{
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
            HUD.mode = MBProgressHUDModeCustomView;
            HUD.labelText = T(@"退订成功");
            [HUD hide:YES afterDelay:1];
            [self.confirmButton setTitle:T(@"订阅此频道") forState:UIControlStateNormal];
            [self.confirmButton removeTarget:self action:@selector(unSubscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
            [self.confirmButton addTarget:self action:@selector(subscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        }];
    }];
    
}
@end
