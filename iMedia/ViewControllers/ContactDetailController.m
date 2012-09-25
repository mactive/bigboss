//
//  ContactDetailController.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ContactDetailController.h"
#import "LayoutConst.h"
#import "User.h"

@interface ContactDetailController ()

@end

@implementation ContactDetailController

@synthesize sendMsgButton = _sendMsgButton;
@synthesize nameLabel = _nameLabel;
@synthesize user =_user;
@synthesize delegate = _delegate;

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
    
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(LARGE_GAP, SMALL_GAP, 200.0f, 40.0f)];
    _nameLabel.backgroundColor = [UIColor redColor];
    _nameLabel.textColor = [UIColor blackColor];
    [_nameLabel setText:@"label"];
    [_nameLabel setMinimumFontSize:20.0];
    [self.view addSubview:self.nameLabel];
    
    self.sendMsgButton = [[UIButton alloc] initWithFrame:CGRectMake(SMALL_GAP, 300.0f, 80.0f, 30.0f)];
    [self.sendMsgButton setTag:0];
    [self.sendMsgButton setTitle:NSLocalizedString(@"Send Msg", nil) forState:UIControlStateNormal];
    [self.sendMsgButton.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_HEIGHT]];
    [self.sendMsgButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.sendMsgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.sendMsgButton setBackgroundColor:[UIColor yellowColor]];
    [self.sendMsgButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.sendMsgButton];

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
    [self.delegate contactDetailController:self didChatUser:self.user];
}

@end
