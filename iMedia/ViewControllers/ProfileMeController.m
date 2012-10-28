//
//  ProfileMeController.m
//  iMedia
//
//  Created by qian meng on 12-10-28.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ProfileMeController.h"
#import "Me.h"
#import "Avatar.h"
#import "Channel.h"
#import "ChatWithIdentity.h"
#import "ModelHelper.h"
#import "XMPPNetworkCenter.h"
#import "DDLog.h"
#import <QuartzCore/QuartzCore.h>
#import "AlbumViewController.h"
#import "UIImage+Resize.h"
#import "AppDelegate.h"

@interface ProfileMeController ()

@end

@implementation ProfileMeController
@synthesize managedObjectContext;
@synthesize sendMsgButton = _sendMsgButton;
@synthesize deleteUserButton;
@synthesize reportUserButton;
@synthesize nameLabel = _nameLabel;
@synthesize me;
@synthesize contentView;

@synthesize albumView;
@synthesize albumArray;
@synthesize albumViewController;

@synthesize statusView;
@synthesize snsView;
@synthesize infoArray;
@synthesize infoDescArray;
@synthesize infoView;
@synthesize infoTableView;
@synthesize addedImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.me = [self appDelegate].me ;
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}


#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_OFFSET 2.5

#define VIEW_PADDING_LEFT 12
#define VIEW_ALBUM_HEIGHT 160
#define VIEW_STATUS_HEIGHT 15
#define VIEW_SNS_HEIGHT 30
#define VIEW_ACTION_HEIGHT 41
#define VIEW_UINAV_HEIGHT 44

#define VIEW_COMMON_WIDTH 296

- (void)loadView
{
    [super loadView];
    self.contentView = [[UIScrollView alloc]initWithFrame:
                        CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - VIEW_ACTION_HEIGHT - VIEW_UINAV_HEIGHT)];
    [self.contentView setContentSize:CGSizeMake(self.view.frame.size.width, 600)];
    [self.contentView setScrollEnabled:YES];
    self.contentView.backgroundColor = RGBCOLOR(222, 224, 227);
    
    
    [self initAlbumView];
    [self initStatusView];
    [self initSNSView];
    [self initInfoView];
    
    [self.view addSubview:self.contentView];
    
}
////////////////////////////////////////////////////////////////////////////////
#pragma mark -  ablum view
////////////////////////////////////////////////////////////////////////////////

- (void)initAlbumView
{
    self.albumView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, VIEW_ALBUM_HEIGHT)];
    UIImageView *albumViewBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_image_bg.png"]];
    [self.albumView addSubview:albumViewBg];
    
    UIButton *albumButton;
    
    self.albumArray = [[NSMutableArray alloc] initWithArray: [self.me getOrderedAvatars]];
    
//    self.albumArray = [[NSMutableArray alloc] initWithObjects:
//                       @"profile_face_1.png",@"profile_face_2.png",@"profile_face_1.png",@"profile_face_2.png", nil ];
    
    BOOL ALBUM_ADD = NO;
    
    if ([self.albumArray count] < 8) {
        [self.albumArray addObject:@"profile_add.png"];
        ALBUM_ADD = YES;
    }
    
    for (int i = 0; i< [albumArray count]; i++) {
        albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [albumButton setImage:[UIImage imageNamed:[albumArray objectAtIndex:i] ] forState:UIControlStateNormal];
        [albumButton setFrame:CGRectMake(VIEW_ALBUM_OFFSET * (i%4*2 + 1) + VIEW_ALBUM_WIDTH * (i%4), VIEW_ALBUM_OFFSET * (floor(i/4)*2+1) + VIEW_ALBUM_WIDTH * floor(i/4), VIEW_ALBUM_WIDTH, VIEW_ALBUM_WIDTH)];
        [albumButton.layer setMasksToBounds:YES];
        [albumButton.layer setCornerRadius:3.0];
        albumButton.tag = i;
        if (ALBUM_ADD && i == [albumArray count] - 1 ) {
            [albumButton addTarget:self action:@selector(addAlbum:) forControlEvents:UIControlEventTouchUpInside];
        }else {
            [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [self.albumView addSubview:albumButton];
    }
    
    [self.contentView addSubview:self.albumView];
    
}

- (void)albumClick:(UIButton *)sender
{
    self.albumViewController = [[AlbumViewController alloc] init];
    self.albumViewController.albumArray = self.albumArray;
    [self.albumViewController setHidesBottomBarWhenPushed:YES];
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:self.albumViewController animated:YES];
    NSLog(@"%d",sender.tag);
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actionsheet when add album
/////////////////////////////////////////////////////////////////////////////////////////

- (void)addAlbum:(UIButton *)sender
{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]  
                                  initWithTitle:nil  
                                  delegate:self  
                                  cancelButtonTitle:T(@"取消")  
                                  destructiveButtonTitle:nil 
                                  otherButtonTitles:T(@"用户相册"), T(@"摄像头"),nil];  
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;  
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {  
        [self takePhotoFromLibaray];  
    }else if (buttonIndex == 1) {  
        [self takePhotoFromCamera];  
    }
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImagePickerControllerDelegateMethods
//////////////////////////////////////////////////////////////////////////////////////////
#define kCameraSource       UIImagePickerControllerSourceTypeCamera
- (void)takePhotoFromLibaray
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
	picker.allowsEditing = YES;
    [self presentModalViewController:picker animated:YES];
}

- (void)takePhotoFromCamera
{
    if (![UIImagePickerController isSourceTypeAvailable:kCameraSource]) {
        UIAlertView *cameraAlert = [[UIAlertView alloc] initWithTitle:T(@"cameraAlert") message:T(@"Camera is not available.") delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [cameraAlert show];
		return;
	}
    
    //    self.tableView.allowsSelection = NO;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	picker.delegate = self;
	picker.allowsEditing = YES;

    [self presentModalViewController:picker animated:YES];    
}

// UIImagePickerControllerSourceTypeCamera and UIImagePickerControllerSourceTypePhotoLibrary
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    //    self.image = image;
    
    UIImage *thumbnail = [image resizedImageToSize:CGSizeMake(75, 75)];
    
    Avatar *insertAvatar = [NSEntityDescription insertNewObjectForEntityForName:@"ImageLocal" inManagedObjectContext:self.managedObjectContext ];
    insertAvatar.thumbnail = thumbnail;
    insertAvatar.image = image;
    NSInteger sequence = [self.albumArray count] + 1;
    
    insertAvatar.sequence = [NSNumber numberWithInt:sequence];
    [self.me addAvatarsObject:insertAvatar];
    
    [self.albumView removeFromSuperview];
    [self initAlbumView];
    
    //delete 
//    [me removeAvatarsObject:insertAvatar];
    //replace
//    [insertAvatar setImage:image];
//    [insertAvatar setThumbnail:image];
    
    
    
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    /* keep the order first dismiss picker and pop controller */
    [picker dismissModalViewControllerAnimated:YES];
    //    [self.controller.navigationController popViewControllerAnimated:NO];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - status view
////////////////////////////////////////////////////////////////////////////////


- (void)initStatusView
{
    self.statusView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + 12, VIEW_COMMON_WIDTH, 15)];
    
    // Create a label icon for the sex.
    UIImageView* sexView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"sex_female_bg.png"]];
    [sexView setFrame:CGRectMake(0, 0, 40, 15)];
    
    UILabel* sexLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 15, 15)];
    [sexLabel setBackgroundColor:[UIColor clearColor]];
    sexLabel.text  = @"18";
    [sexLabel setFont:[UIFont systemFontOfSize:12.0]];
    [sexLabel setTextColor:[UIColor whiteColor]];
    [sexView addSubview:sexLabel];
    
    
    // Create a label icon for the time.
    UIImageView *timeIconView = [[UIImageView alloc] initWithFrame:CGRectMake(210, 0 , 15, 15)];
    timeIconView.image = [UIImage imageNamed:@"time_icon.png"];
    
    UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(228, 0 ,60, 15)];
	timeLabel.font = [UIFont systemFontOfSize:12.0];
	timeLabel.textAlignment = UITextAlignmentLeft;
	timeLabel.textColor = RGBCOLOR(140, 140, 140);
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.text  = @"6 hours ago";
    [timeLabel sizeToFit];
    
    // Create a label icon for the time.
    UIImageView *locationIconView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 0 , 15, 15)];
    locationIconView.image = [UIImage imageNamed:@"location_icon.png"];
    
    UILabel* locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(158, 0 ,40, 15)];
	locationLabel.font = [UIFont systemFontOfSize:12.0];
	locationLabel.textAlignment = UITextAlignmentLeft;
	locationLabel.textColor = RGBCOLOR(140, 140, 140);
    locationLabel.backgroundColor = [UIColor clearColor];
    locationLabel.text  = @"200M";
    [locationLabel sizeToFit];
    
    // add to the statusView
    [self.statusView addSubview:sexView];
    [self.statusView addSubview:timeIconView];
	[self.statusView addSubview:timeLabel];
    [self.statusView addSubview:locationIconView];
	[self.statusView addSubview:locationLabel];
    
    [self.contentView addSubview: self.statusView];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - sns view
////////////////////////////////////////////////////////////////////////////////
- (void)initSNSView
{
    self.snsView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + 24, VIEW_COMMON_WIDTH, VIEW_SNS_HEIGHT)];
    
    NSArray *buttonNames = [NSArray arrayWithObjects:@"weibo", @"wechat", @"kaixin", @"douban", nil];
    NSUInteger _count = [buttonNames count];
    UIButton *snsButton;
    UIImageView *snsIcon;
    for (int index = 0; index < _count; index++ ) {
        snsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [snsButton setFrame:CGRectMake( VIEW_COMMON_WIDTH / _count * index, 0, VIEW_COMMON_WIDTH / _count -1, VIEW_SNS_HEIGHT)];
        [snsButton setTitle:[buttonNames objectAtIndex:index] forState:UIControlStateNormal];
        [snsButton setTitleColor:RGBCOLOR(108, 108, 108) forState:UIControlStateNormal];
        snsButton.titleLabel.font = [UIFont systemFontOfSize:11.0];
        [snsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 15, 0, 0)];
        [snsButton.layer setMasksToBounds:YES];
        [snsButton.layer setCornerRadius:3.0];
        
        snsButton.backgroundColor = RGBCOLOR(255, 255, 255);
        [snsButton setBackgroundImage:[UIImage imageNamed:@"uibutton_bg_color.png"] forState:UIControlStateHighlighted];
        
        snsIcon = [[UIImageView alloc]initWithFrame:CGRectMake(5, 7.5, 15, 15)];
        [snsIcon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_icon_%@_c.png",[buttonNames objectAtIndex:index]]]];
        [snsButton addSubview:snsIcon];
        
        snsButton.tag = 1000 + index;
        [snsButton addTarget:self action:@selector(snsAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.snsView addSubview:snsButton];
    }
    
    
    
    
    [self.contentView addSubview: self.snsView];
    
}

-(void)snsAction:(UIButton *)sender
{
    NSLog(@"Seg.selectedSegmentIndex:%d",sender.tag);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - info view
////////////////////////////////////////////////////////////////////////////////
- (void)initInfoView
{
    self.infoView = [[UIView alloc] initWithFrame:
                     CGRectMake(0, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + VIEW_SNS_HEIGHT + 30, self.view.frame.size.width, 400)];
    self.infoView.backgroundColor = [UIColor clearColor];
    
    self.infoArray = [[NSArray alloc] initWithObjects: @"签名",@"手机",@"职业",@"家乡",@"个人说明",nil ];    
    self.infoDescArray = [[NSArray alloc] initWithObjects:
                          @"夫和实生物，同则不继。以他平他谓之和故能丰长而物归之",
                          @"老莫  13899763487",
                          @"IT工程师",
                          @"山东 聊城",
                          @"我不是那个史上最牛历史老师！我们中国的教科书属于秽史，请同学们考完试抓紧把它们烧了，放家里一天，都脏你屋子。", nil];
    
    self.infoTableView = [[UITableView alloc]initWithFrame:self.infoView.bounds style:UITableViewStyleGrouped];
    self.infoTableView.dataSource = self;
    self.infoTableView.delegate = self;
    [self.infoTableView setBackgroundColor:[UIColor clearColor]];
    
    
    [self.infoView addSubview:self.infoTableView];
    
    [self.contentView addSubview:self.infoView];    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - info table view
////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.row == [self.infoArray count] -1 ){
        return 120.0;
    }else{
        return 44.0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [infoArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    
    return cell;
    
}
#define SUMMARY_WIDTH 200
#define LABEL_HEIGHT 20

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, message, and quarter image of the time zone.
	 */
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    //    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.backgroundView.backgroundColor = RGBCOLOR(248, 248, 248);
    
    cell.selectedBackgroundView.backgroundColor =  RGBCOLOR(228, 228, 228);
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 70, 20)];
    titleLabel.text = [self.infoArray objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(155, 161, 172);
    titleLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:titleLabel];
    //    cell.textLabel.text = [self.infoArray objectAtIndex:indexPath.row];
    //    cell.textLabel.textColor = RGBCOLOR(155, 161, 172);
    
    // Create a label for the summary
    UILabel* descLabel;
	CGRect rect = CGRectMake( 80, 10, 210, 30);
	descLabel = [[UILabel alloc] initWithFrame:rect];
    descLabel.numberOfLines = 0;
	descLabel.font = [UIFont systemFontOfSize:13.0];
	descLabel.textAlignment = UITextAlignmentLeft;
    descLabel.textColor = RGBCOLOR(125, 125, 125);
    descLabel.backgroundColor = [UIColor clearColor];
    NSString *signiture = [self.infoDescArray objectAtIndex:indexPath.row];
    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    CGFloat _labelHeight;
    
    CGSize signitureSize = [signiture sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signitureSize.height > 20) {
        _labelHeight = 6.0;
    }else {
        _labelHeight = 14.0;
    }
    descLabel.text = signiture;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signitureSize.width , signitureSize.height );
    
    
    if( indexPath.row == [self.infoArray count] -1 ){
        descLabel.frame = CGRectMake(20, _labelHeight + 25 , SUMMARY_WIDTH + 50 , signitureSize.height );
    }
    
    
    [cell.contentView addSubview:descLabel];
    
    return cell;
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
