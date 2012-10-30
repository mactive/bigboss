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
#import "ImageRemote.h"
#import "ChatWithIdentity.h"
#import "ModelHelper.h"
#import "XMPPNetworkCenter.h"
#import "DDLog.h"
#import <QuartzCore/QuartzCore.h>
#import "AlbumViewController.h"
#import "UIImage+Resize.h"
#import "AppDelegate.h"
#import "AppNetworkAPIClient.h"

@interface ProfileMeController ()

@property(strong, nonatomic) NSMutableArray * albumButtonArray;
@property(strong, nonatomic) UIActionSheet *photoActionsheet;
@property(strong, nonatomic) UIActionSheet *editActionsheet;
@property(readwrite, nonatomic) NSUInteger editingAlbumIndex;

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
@synthesize addAlbumButton;

@synthesize editProfileButton;
@synthesize albumCount;
@synthesize albumButtonArray;
@synthesize photoActionsheet;
@synthesize editActionsheet;
@synthesize editingAlbumIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.me = [self appDelegate].me ;
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - edit model
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setEditModel
{
    UIBarButtonItem *ttButton = [[UIBarButtonItem alloc] initWithTitle:T(@"保存") 
                                                              style:UIBarButtonItemStyleDone 
                                                             target:self
                                                             action:@selector(cancelEditModel)];
    [ttButton setTintColor:RGBCOLOR(80, 192, 77)];
    self.navigationItem.rightBarButtonItem = ttButton;
    
    //album can do image
    [self.addAlbumButton setHidden:YES];
    
    // table into setting
    for (int j = 0; j < 8; j++) {
        UIButton *albumButton = [self.albumButtonArray objectAtIndex:j];
        
        [albumButton.layer setBorderColor:[UIColor whiteColor].CGColor];
        [albumButton.layer setBorderWidth:3.0f];
        
        if (j < self.albumCount) {
            [albumButton removeTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
            [albumButton addTarget:self action:@selector(removeOrReplace:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [albumButton setHidden:YES];
        }
    }
}


- (void)cancelEditModel
{
    // save and upload
    self.navigationItem.rightBarButtonItem = self.editProfileButton;
    
    [self.addAlbumButton setHidden:NO];

    // table into setting
    for (int j = 0; j < 8; j++) {
        UIButton *albumButton = [self.albumButtonArray objectAtIndex:j];
        [albumButton.layer setBorderColor:[UIColor clearColor].CGColor];
        [albumButton.layer setBorderWidth:0.0f];
    }
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actionsheet when add album
/////////////////////////////////////////////////////////////////////////////////////////

- (void)removeOrReplace:(UIButton *)sender
{   
    self.editActionsheet = [[UIActionSheet alloc]  
                                  initWithTitle:nil  
                                  delegate:self  
                                  cancelButtonTitle:T(@"取消")  
                                  destructiveButtonTitle:nil 
                                  otherButtonTitles:T(@"替换照片"), T(@"删除照片"),nil];  
    self.editActionsheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [self.editActionsheet showFromTabBar:[[self tabBarController] tabBar]];
    self.editingAlbumIndex = sender.tag;
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

- (CGRect)calcRect:(NSInteger)index
{
    CGFloat x = VIEW_ALBUM_OFFSET * (index % 4 * 2 + 1) + VIEW_ALBUM_WIDTH * (index % 4) ; 
    CGFloat y = VIEW_ALBUM_OFFSET * (floor(index / 4) * 2 + 1) + VIEW_ALBUM_WIDTH * floor(index / 4);
    return  CGRectMake( x, y, VIEW_ALBUM_WIDTH, VIEW_ALBUM_WIDTH);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = T(@"个人设置");
    self.editProfileButton = [[UIBarButtonItem alloc] initWithTitle:T(@"编辑") 
                                                          style:UIBarButtonItemStyleDone 
                                                         target:self 
                                                         action:@selector(setEditModel)];
    
    self.navigationItem.rightBarButtonItem = self.editProfileButton;
}

- (void)loadView
{
    [super loadView];
    self.contentView = [[UIScrollView alloc]initWithFrame:
                        CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - VIEW_ACTION_HEIGHT - VIEW_UINAV_HEIGHT)];
    [self.contentView setContentSize:CGSizeMake(self.view.frame.size.width, 600)];
    [self.contentView setScrollEnabled:YES];
    self.contentView.backgroundColor = RGBCOLOR(222, 224, 227);
    
    self.editingAlbumIndex = NSNotFound;
    
    self.EDITMODEL = NO;
    
    [self initAlbumView];
    [self refreshAlbumView];
    [self initStatusView];
    [self initSNSView];
    [self initInfoView];
    
    [self.view addSubview:self.contentView];
    
}
////////////////////////////////////////////////////////////////////////////////
#pragma mark -  ablum view
////////////////////////////////////////////////////////////////////////////////
#define MAX_ALBUN_COUNT 8
- (void)initAlbumView
{
    self.albumView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, VIEW_ALBUM_HEIGHT)];
    UIImageView *albumViewBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_image_bg.png"]];
    [self.albumView addSubview:albumViewBg];
    [self.contentView addSubview:self.albumView];
    
    self.addAlbumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.addAlbumButton.layer setMasksToBounds:YES];
    [self.addAlbumButton.layer setCornerRadius:3.0];
    self.addAlbumButton.tag = 1000;
    [self.addAlbumButton setImage:[UIImage imageNamed:@"profile_add.png"] forState:UIControlStateNormal];
    [self.addAlbumButton addTarget:self action:@selector(addAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.addAlbumButton setFrame:[self calcRect:0]];
    [self.albumView addSubview:self.addAlbumButton];

    
    self.albumButtonArray = [[NSMutableArray alloc] init];
    UIButton *albumButton;
//    self.albumArray = [[NSMutableArray alloc] initWithObjects:
//                       @"profile_face_1.png",@"profile_face_2.png",@"profile_face_1.png",@"profile_face_2.png", nil ];
    

    for (int i = 0; i< MAX_ALBUN_COUNT; i++) {
        albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [albumButton setFrame:[self calcRect:i]];
        [albumButton.layer setMasksToBounds:YES];
        [albumButton.layer setCornerRadius:3.0];
        albumButton.tag = i ;
        [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.albumView addSubview:albumButton];
        [albumButton setHidden:YES];
        [self.albumButtonArray addObject:albumButton];
    }
}

- (void)refreshAlbumView
{
    self.albumArray = [[NSMutableArray alloc] initWithArray: [self.me getOrderedAvatars]];
    self.albumCount = [self.albumArray count];

    for (int j = 0; j < 8; j++) {
        UIButton *albumButton = [self.albumButtonArray objectAtIndex:j];
        if (j < albumCount) {
            Avatar *avatar = [self.albumArray objectAtIndex:j];
            [albumButton setImage:avatar.thumbnail forState:UIControlStateNormal]; 
            [albumButton setHidden:NO];
        } else {
            [albumButton setImage:nil forState:UIControlStateNormal];
            [albumButton setHidden:YES];
        }
    }

    if (self.albumCount < MAX_ALBUN_COUNT) {
        CGRect rect = [self calcRect:self.albumCount];
        [self.addAlbumButton setFrame:rect];
        [self.addAlbumButton setHidden:NO];
    } else {
        [self.addAlbumButton setHidden:YES];
    }
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
    
    self.photoActionsheet = [[UIActionSheet alloc] 
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:T(@"取消")
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:T(@"用户相册"), T(@"摄像头"),nil];
    self.photoActionsheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [self.photoActionsheet showFromTabBar:[[self tabBarController] tabBar]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.photoActionsheet) {
        if (buttonIndex == 0) {  
            [self takePhotoFromLibaray];  
        }else if (buttonIndex == 1) {  
            [self takePhotoFromCamera];  
        } 
    }
    
    if (actionSheet == self.editActionsheet) {
        if (buttonIndex == 0) {  
            [self addAlbum:nil];
        }else if (buttonIndex == 1) {
            [self removeAlbum];
        }
    }
    
    
}

- (void)removeAlbum
{    
    Avatar *removeAvatar = [self.albumArray objectAtIndex:self.editingAlbumIndex];
    [self.me removeAvatarsObject:removeAvatar];
    
    // network
//    [[AppNetworkAPIClient sharedClient] storeAvatar:removeAvatar forMe:self.me andOrder:sequence withBlock:nil];

    // display
    UIButton *albumButton = [self.albumButtonArray objectAtIndex:self.editingAlbumIndex];
    [albumButton removeTarget:self action:@selector(removeOrReplace:) forControlEvents:UIControlEventTouchUpInside];
    [albumButton setHidden:YES];
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
    
    if (self.editingAlbumIndex != NSNotFound) {
        Avatar *replaceAvatar = [self.albumArray objectAtIndex:self.editingAlbumIndex];
        replaceAvatar.image = image;
        replaceAvatar.thumbnail = thumbnail;
        [[AppNetworkAPIClient sharedClient] storeAvatar:replaceAvatar forMe:self.me andOrder:self.editingAlbumIndex withBlock:nil];
        
        self.editingAlbumIndex = NSNotFound;

    }else {
        Avatar *insertAvatar = [NSEntityDescription insertNewObjectForEntityForName:@"ImageLocal" inManagedObjectContext:self.managedObjectContext ];
        insertAvatar.thumbnail = thumbnail;
        insertAvatar.image = image;
        NSInteger sequence = [self.albumArray count] + 1;
        
        insertAvatar.sequence = [NSNumber numberWithInt:sequence];
        [self.me addAvatarsObject:insertAvatar];
        
        //网路传输
        [[AppNetworkAPIClient sharedClient] storeAvatar:insertAvatar forMe:self.me andOrder:sequence withBlock:^(id responseObject, NSError *error) {
            if (error == nil) {
                
                NSString* url = [responseObject valueForKey:@"image"];
                NSString *thumbnailURL = [responseObject valueForKey:@"thumbnail"];
                
                NSArray *imagesURLArray = [self.me getOrderedImages];
                ImageRemote *imageRemote = [imagesURLArray objectAtIndex:(sequence-1)];
                imageRemote.sequence = [NSNumber numberWithInt:sequence];
                imageRemote.imageThumbnailURL = thumbnailURL;
                imageRemote.imageURL = url;
            } else {
                NSLog (@"NSError received during login: %@", error);
            }
            
        }];
    }
    

    
    [self refreshAlbumView];
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
    NSString* bgImgStr ;
        if ([me.gender isEqualToString:@"m"]) {
        bgImgStr = @"sex_male_bg.png";
    } else if ([me.gender isEqualToString:@"f"]) {
        bgImgStr = @"sex_female_bg.png";
    } else {
        bgImgStr = @"sex_unknown_bg.png";
    }
    
    UIImageView* sexView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:bgImgStr]];
    [sexView setFrame:CGRectMake(0, 0, 40, 15)];
    
    
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //unsigned int unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit fromDate:self.me.birthdate  toDate:now  options:0];
    NSString* ageStr = [NSString stringWithFormat:@"%d", comps.year];
    
    UILabel* sexLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 15, 15)];
    [sexLabel setBackgroundColor:[UIColor clearColor]];
    sexLabel.text  = ageStr;
    [sexLabel setFont:[UIFont systemFontOfSize:12.0]];
    [sexLabel setTextColor:[UIColor whiteColor]];
    [sexView addSubview:sexLabel];
    
    
    // add to the statusView
    [self.statusView addSubview:sexView];    
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
                          self.me.signature ,
                          self.me.cell,
                          self.me.career,
                          self.me.hometown,
                          self.me.selfIntroduction,
                          nil];
    
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
   
    NSString *text = @"";
    if (indexPath.row < [self.infoDescArray count])
        text = [self.infoDescArray objectAtIndex:indexPath.row];
    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    CGFloat _labelHeight;
    
    CGSize signitureSize = [text sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signitureSize.height > 20) {
        _labelHeight = 6.0;
    }else {
        _labelHeight = 14.0;
    }
    descLabel.text = text;
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
