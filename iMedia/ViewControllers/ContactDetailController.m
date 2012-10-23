//
//  ContactDetailController.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ContactDetailController.h"
#import "User.h"
#import "Channel.h"
#import "ChatWithIdentity.h"
#import "ModelHelper.h"
#import "XMPPNetworkCenter.h"
#import "DDLog.h"
#import <QuartzCore/QuartzCore.h>

@interface ContactDetailController ()

@end

@implementation ContactDetailController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize sendMsgButton = _sendMsgButton;
@synthesize deleteUserButton;
@synthesize nameLabel = _nameLabel;
@synthesize user =_user;
@synthesize delegate = _delegate;
@synthesize jsonData;
@synthesize albumView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

#define ALBUM_WIDTH 75
#define ALBUM_WIDTH 75
#define ALBUM_OFFSET 2.5


- (void)loadView
{
    [super loadView];
    
    self.albumView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 160)];
    UIImageView *albumViewBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_image_bg.png"]];
    [self.albumView addSubview:albumViewBg];
    
    UIImageView *albumAvatar;

    NSArray *albumArray = [[NSArray alloc] initWithObjects:
                           @"profile_face_1.png",@"profile_face_2.png",@"profile_face_1.png",@"profile_face_2.png",
                           @"profile_face_1.png",@"profile_face_2.png",@"profile_face_1.png",@"profile_face_2.png",nil ];
    for (int i = 0; i< [albumArray count]; i++) {
        albumAvatar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[albumArray objectAtIndex:i] ]];
        [albumAvatar setFrame:CGRectMake(ALBUM_OFFSET * (i%4*2 + 1) + ALBUM_WIDTH * (i%4), ALBUM_OFFSET * (floor(i/4)*2+1) + ALBUM_WIDTH * floor(i/4), ALBUM_WIDTH, ALBUM_WIDTH)];
        [albumAvatar.layer setMasksToBounds:YES];
        [albumAvatar.layer setCornerRadius:3.0];
        [self.albumView addSubview:albumAvatar];
    }
    
    NSLog(@"%@",self.user);
    
    
    [self.view addSubview:self.albumView];

 
    self.sendMsgButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 300.0f, 80.0f, 30.0f)];
    [self.sendMsgButton setTag:0];
    [self.sendMsgButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.sendMsgButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.sendMsgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.sendMsgButton setBackgroundColor:[UIColor yellowColor]];
    
    [self.view addSubview:self.sendMsgButton];
    
    
    // Now set content. Either user or jsonData must have value
    if (self.user == nil) {
        self.title = [jsonData valueForKey:@"jid"];
        [self.sendMsgButton setTitle:NSLocalizedString(@"Add as a friend", nil) forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(addFriendButtonPushed:) forControlEvents:UIControlEventTouchUpInside];

    } else {
        self.title = self.user.displayName;
        [self.sendMsgButton setTitle:NSLocalizedString(@"Send Msg", nil) forState:UIControlStateNormal];
        [self.sendMsgButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.deleteUserButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP+200.0f, 300.0f, 80.0f, 30.0f)];
        [self.deleteUserButton setTag:2];
        [self.deleteUserButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
        [self.deleteUserButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.deleteUserButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.deleteUserButton setBackgroundColor:[UIColor yellowColor]];
        [self.deleteUserButton setTitle:NSLocalizedString(@"BlockUser", nil) forState:UIControlStateNormal];
        [self.deleteUserButton addTarget:self action:@selector(deleteUserButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.deleteUserButton];
    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

-(void)sendMsgButtonPushed:(id)sender
{
    [self.delegate viewController:self didChatIdentity:self.user];
}

-(void)addFriendButtonPushed:(id)sender
{
    NSLog(@"addFriendButtonPushed %@", jsonData);
    
    NSString *userJid = [jsonData valueForKey:@"jid"];

    User *newUser = [ModelHelper findUserWithEPostalID:userJid inContext:self.managedObjectContext];
    
    if (newUser == nil) {
        newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    }
    
    NSLog(@"NewUSer %@",newUser);
    
    if (newUser.state.intValue != IdentityStateActive) {
        [ModelHelper populateUser:newUser withJSONData:jsonData];
        newUser.state = [NSNumber numberWithInt:IdentityStatePendingAddFriend];
        NSLog(@"userJid %@",userJid);

        [[XMPPNetworkCenter sharedClient] addBuddy:userJid withCallbackBlock:nil];
    }
}

-(void)deleteUserButtonPushed:(id)sender
{
    self.user.state = [NSNumber numberWithInt:IdentityStatePendingRemoveFriend];
    [[XMPPNetworkCenter sharedClient] removeBuddy:self.user.ePostalID withCallbackBlock:nil];
}

@end
