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
#import "UIImage+ProportionalFill.h"
#import "AppDelegate.h"
#import "AppNetworkAPIClient.h"
#import "AFImageRequestOperation.h"
#import "EditViewController.h"
#import "ServerDataTransformer.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "NSDate+timesince.h"
#import "SinaWeiboViewController.h"

#define SUMMARY_WIDTH 200
#define LABEL_HEIGHT 20
#define kCameraSource       UIImagePickerControllerSourceTypeCamera
#define MAX_ALBUN_COUNT 8

#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface ProfileMeController ()
@property(strong, nonatomic) NSMutableArray * albumButtonArray;
@property(strong, nonatomic) UIActionSheet *photoActionsheet;
@property(strong, nonatomic) UIActionSheet *editActionsheet;
@property(strong, nonatomic) UIAlertView *weiboAlertView;
@property(readwrite, nonatomic) NSUInteger editingAlbumIndex;
@property(readwrite, nonatomic) NSUInteger addButtonIndex;
@property(readwrite, nonatomic) BOOL isEditing;

@property (strong, nonatomic) UIScrollView *contentView;
@property (strong, nonatomic) UITableView *infoTableView;

@property (strong, nonatomic) UIView *albumView;
@property (strong, nonatomic) UIView *statusView;
@property (strong, nonatomic) UIView *snsView;
@property (strong, nonatomic) UIView *infoView;

@property (strong, nonatomic) UIImageView *sexView;
@property (strong, nonatomic) UILabel *sexLabel;
@property (strong, nonatomic) UILabel *guidLabel;
@property (strong, nonatomic) UILabel *horoscopeLabel;


@property (strong, nonatomic) UIButton *sendMsgButton;
@property (strong, nonatomic) UIButton *deleteUserButton;
@property (strong, nonatomic) UIButton *reportUserButton;
@property (strong, nonatomic) UILabel  *nameLabel;


@property (strong, nonatomic) UIBarButtonItem *editProfileButton;

@property (strong, nonatomic) NSMutableArray *albumArray;
@property (strong, nonatomic) NSArray *infoArray;
@property (strong, nonatomic) NSMutableArray *infoDescArray;

@property (strong, nonatomic) UIButton *addAlbumButton;
@property (readwrite, nonatomic) NSUInteger albumCount;

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

@synthesize statusView;
@synthesize snsView;
@synthesize infoArray;
@synthesize infoDescArray;
@synthesize infoView;
@synthesize infoTableView;
@synthesize addAlbumButton;
@synthesize sexLabel;
@synthesize sexView;
@synthesize guidLabel;
@synthesize horoscopeLabel;

@synthesize editProfileButton;
@synthesize albumCount;
@synthesize albumButtonArray;
@synthesize photoActionsheet;
@synthesize editActionsheet;
@synthesize weiboAlertView;
@synthesize editingAlbumIndex;
@synthesize addButtonIndex;
@synthesize isEditing;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.me = [self appDelegate].me ;
        [self.infoTableView setAllowsSelection:NO];
        self.isEditing = NO;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - edit mode
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setEditMode
{
    if (self.isEditing) {
        return;
    }
    
    UIBarButtonItem *ttButton = [[UIBarButtonItem alloc] initWithTitle:T(@"保存") 
                                                              style:UIBarButtonItemStyleDone 
                                                             target:self
                                                                action:@selector(saveEditMode)];
    [ttButton setTintColor:RGBCOLOR(80, 192, 77)];
    self.navigationItem.rightBarButtonItem = ttButton;
    self.isEditing = YES;
    
    [self infoTableEditing];
    [self refreshAlbumView];
    
    // table into setting
}

- (void)saveEditMode
{
    if (!self.isEditing) {
        return;
    }
    
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"更新中");
    // save and upload
    [[AppNetworkAPIClient sharedClient] uploadMe:self.me withBlock:^(id responseObject, NSError *error) {
        [HUD hide:YES];
        if ((responseObject != nil) && (error == nil)) {
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"更新成功") andHideAfterDelay:1];
        }else {
            DDLogVerbose (@"NSError received during upload me: %@", error);
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"更新失败") andHideAfterDelay:1];
        }
    }];
    
    self.navigationItem.rightBarButtonItem = self.editProfileButton;
    
    self.isEditing = NO;
    
    [self infoTableCommitEdit];
    [self refreshAlbumView];
}

- (void)infoTableEditing{
    for (NSInteger j = 0; j < [self.infoTableView numberOfSections]; ++j)
    {
        for (NSInteger i = 0; i < [self.infoTableView numberOfRowsInSection:j]; ++i)
        {
            UITableViewCell *cell = [self.infoTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator ;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *titleArray = (NSArray *)[self.infoArray objectAtIndex:indexPath.section];
    NSArray *descArray = (NSArray *)[self.infoDescArray objectAtIndex:indexPath.section];

    
    if (self.isEditing) {
        DDLogVerbose(@"click the %d",indexPath.row);
        
        EditViewController *controller = [[EditViewController alloc] initWithNibName:nil bundle:nil];
        controller.nameText = [titleArray objectAtIndex:indexPath.row];
        controller.valueText = [descArray objectAtIndex:indexPath.row];
        controller.valueIndex = [self encodeIndex:indexPath];
        controller.delegate = self;
        
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    }else{
        [self editModeMBPNotice];
    }
}

///////////////////////////////////////////
#pragma mark - decodeIndex encodeIndex
///////////////////////////////////////////
// index to nsarray 21-> 1,1
//- (NSArray *)decodeIndex:(NSUInteger )index
//{
//    NSNumber * section =  [NSNumber numberWithInteger: index / 10 - 1];
//    NSNumber * row =  [NSNumber numberWithInteger: index % 10];
//    
//    NSArray *result = [[NSArray alloc]initWithObjects:section, row, nil];
//    return  result;
//}

- (NSIndexPath *)decodeIndex:(NSUInteger )index
{
    NSInteger section =  index / 10 - 1;
    NSInteger row =   index % 10 ;
    
    NSIndexPath *result = [NSIndexPath indexPathForRow:row inSection:section];
    return result;
}

// section row to index 0,0-> 10
- (NSInteger )encodeIndex:(NSIndexPath  *)indexPath
{
    NSUInteger result = (indexPath.section+1) * 10 + indexPath.row;
    return result;
}


// Protocl function
-(void)passStringValue:(NSString *)value andIndex:(NSUInteger )index;
{
    DDLogVerbose(@"*** %@ %d ***",value,index);
    
    NSIndexPath *indexPath = [self decodeIndex:index];
    
    // 判断是否 SINAWEIBO_ITEM_INDEX
    if (index != SINAWEIBO_ITEM_INDEX) {

        UITableViewCell *cell = [self.infoTableView cellForRowAtIndexPath:indexPath];
        UILabel *descLabel = (UILabel *)[cell viewWithTag:1002];
        
        // resize the label for multiline
        
        CGSize summaryMaxSize = CGSizeZero;
        if( index == [self.infoArray count] -1 ){
            summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
        }else{
            summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*3);
        }
        CGFloat _labelHeight;
        
        CGSize signatureSize = [value sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
        if (signatureSize.height > 20) {
            if (indexPath.section == 0) {
                _labelHeight = 14.0;
            }else{
                _labelHeight = 6.0;
            }
        }else {
            if (indexPath.section == 0) {
                _labelHeight = 22.0;
            }else{
                _labelHeight = 14.0;
            }
        }
        descLabel.text = value;
        descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signatureSize.width , signatureSize.height );
        
        if( indexPath.section == 3 ){
            descLabel.frame     = CGRectMake(10, 37, SUMMARY_WIDTH + 50 , signatureSize.height );
        }
        // 根据不同的 index来设置 self.infoDescArray
        NSIndexPath *tmp = [self decodeIndex:index];
        NSMutableArray *itemArray = [self.infoDescArray objectAtIndex:tmp.section];
        [itemArray replaceObjectAtIndex:tmp.row withObject:value];
        
        switch (index) {
            case NICKNAME_ITEM_INDEX:
                self.me.displayName = value;
                break;
            case SIGNATURE_ITEM_INDEX:
                self.me.signature = value;
                break;
            case CELL_ITEM_INDEX:
                self.me.cell = value;
                break;
            case CAREER_ITEM_INDEX:
                self.me.career = value;
                break;
            case HOMETOWN_ITEM_INDEX:
                self.me.hometown = value;
                break;
            case ALWAYSBEEN_ITEM_INDEX:
                self.me.alwaysbeen = value;
                break;
            case SCHOOL_ITEM_INDEX:
                self.me.school = value;
                break;
            case COMPANY_ITEM_INDEX:
                self.me.company = value;
                break;
            case INTEREST_ITEM_INDEX:
                self.me.interest = value;
                break;
            case SELF_INTRO_ITEM_INDEX:
                self.me.selfIntroduction = value;
                break;
            default:
                break;
        }

    }else{
        
        UIButton *snsButton = (UIButton *)[self.snsView viewWithTag:1000];
        DDLogInfo(@"Sina weibo success");
        [snsButton setImage:[UIImage imageNamed:@"sns_big_icon_0_c.png"] forState:UIControlStateNormal];
        self.me.sinaWeiboID = value;
        [snsButton removeTarget:self action:@selector(snsAction:) forControlEvents:UIControlEventTouchUpInside];
        [snsButton addTarget:self action:@selector(cancelSnsAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

- (void)passNSDateValue:(NSDate *)value andIndex:(NSUInteger)index
{

    UITableViewCell *cell = [self.infoTableView cellForRowAtIndexPath:[self decodeIndex:index]];
    UILabel *descLabel = (UILabel *)[cell viewWithTag:1002];
    
    // resize the label for multiline
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);
    CGFloat _labelHeight;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSString * valueStr = [[NSString alloc] initWithString:[dateFormatter stringFromDate:value]];
    
    CGSize signatureSize = [valueStr sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > 20) {
        _labelHeight = 6.0;
    }else {
        _labelHeight = 14.0;
    }
    descLabel.text = valueStr;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signatureSize.width , signatureSize.height );
    
    NSIndexPath *tmp = [self decodeIndex:index];
    NSMutableArray *itemArray = [self.infoDescArray objectAtIndex:tmp.section];
    [itemArray replaceObjectAtIndex:tmp.row withObject:valueStr];
    
    self.me.birthdate = value;
    [self refreshStatusView];
}

- (void)infoTableCommitEdit{
    
    for (NSInteger j = 0; j < [self.infoTableView numberOfSections]; ++j)
    {
        for (NSInteger i = 0; i < [self.infoTableView numberOfRowsInSection:j]; ++i)
        {
            UITableViewCell *cell = [self.infoTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actionsheet when add album
/////////////////////////////////////////////////////////////////////////////////////////

#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_WIDTH 75
#define VIEW_ALBUM_OFFSET 2.5

#define VIEW_PADDING_LEFT 12
#define VIEW_ALBUM_HEIGHT 160
#define VIEW_STATUS_HEIGHT 15
#define VIEW_SNS_HEIGHT 50
#define VIEW_ACTION_HEIGHT 41
#define VIEW_UINAV_HEIGHT 44

#define VIEW_COMMON_WIDTH 296
#define VIEW_INFO_HEIGHT 720

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
                                                         action:@selector(setEditMode)];

    self.navigationItem.rightBarButtonItem = self.editProfileButton;
}

- (void)loadView
{
    [super loadView];
    self.contentView = [[UIScrollView alloc]initWithFrame:
                        CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - VIEW_UINAV_HEIGHT )];
    [self.contentView setContentSize:CGSizeMake(self.view.frame.size.width, VIEW_INFO_HEIGHT + 300)];
    [self.contentView setScrollEnabled:YES];
    self.contentView.backgroundColor = RGBCOLOR(222, 224, 227);
    
    self.editingAlbumIndex = NSNotFound;
        
    [self initAlbumView];
    [self refreshAlbumView];
    [self initStatusView];
    [self initSNSView];
    [self initInfoView];
    [self refreshSNSView];
    
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
    [self.contentView addSubview:self.albumView];
    
    self.addAlbumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.addAlbumButton.layer setMasksToBounds:YES];
    [self.addAlbumButton.layer setCornerRadius:3.0];
    self.addAlbumButton.tag = 1000;
    [self.addAlbumButton setImage:[UIImage imageNamed:@"profile_add.png"] forState:UIControlStateNormal];
    [self.addAlbumButton addTarget:self action:@selector(addOrReplaceAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.addAlbumButton setFrame:[self calcRect:0]];
    [self.albumView addSubview:self.addAlbumButton];

    self.albumArray = [[NSMutableArray alloc] initWithArray:[self.me getOrderedAvatars]];
    self.albumButtonArray = [[NSMutableArray alloc] init];
    UIButton *albumButton;

    for (int i = 0; i< MAX_ALBUN_COUNT; i++) {
        albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [albumButton setFrame:[self calcRect:i]];
        [albumButton.layer setMasksToBounds:YES];
        [albumButton.layer setCornerRadius:3.0];
        albumButton.tag = i ;
       
        [self.albumView addSubview:albumButton];
        [self.albumButtonArray addObject:albumButton];
    }
}

- (void)refreshAlbumView
{
    NSArray *avatars = [self.me getOrderedAvatars];

    // every time refresh album - make sure self.albumArray only contains good avatar with images, and
    // set albumButton to display all avatar images continuously even if avatar images are not continuous.
    self.albumCount = 0;
    for (int i = 0; i < [avatars count]; i++) {
        Avatar *avatar = [avatars objectAtIndex:i];
        
        if (avatar.thumbnail != nil || (avatar.imageRemoteThumbnailURL != nil && ![avatar.imageRemoteThumbnailURL isEqualToString:@""])) {
            UIButton *albumButton = [self.albumButtonArray objectAtIndex:self.albumCount];
            if (avatar.thumbnail != nil) {
                [albumButton setBackgroundImage:avatar.thumbnail forState:UIControlStateNormal];
            } else {
                AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:avatar.imageRemoteThumbnailURL]] imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    avatar.thumbnail = image;
                    [albumButton setBackgroundImage:avatar.thumbnail forState:UIControlStateNormal];
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    [albumButton setTitle:@"下载失败" forState:UIControlStateNormal];
                }];
                
                [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
            }
            [albumButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [albumButton setHidden:NO];
            
            if (self.isEditing) {
                [albumButton.layer setBorderColor:[UIColor whiteColor].CGColor];
                [albumButton.layer setBorderWidth:3.0f];
                [albumButton removeTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
                [albumButton addTarget:self action:@selector(removeOrReplace:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [albumButton.layer setBorderColor:[UIColor clearColor].CGColor];
                [albumButton.layer setBorderWidth:0.0f];
                [albumButton removeTarget:self action:@selector(removeOrReplace:) forControlEvents:UIControlEventTouchUpInside];
                [albumButton addTarget:self action:@selector(albumClick:) forControlEvents:UIControlEventTouchUpInside];
            }
            
            [self.albumArray setObject:avatar atIndexedSubscript:self.albumCount];
            self.albumCount += 1;
            avatar.sequence = [NSNumber numberWithInt:self.albumCount];
        } else {
            // store avatar to the albumArray from the back
            int index = [avatars count] - (i - self.albumCount) - 1;
            [self.albumArray setObject:avatar atIndexedSubscript:index];
            avatar.sequence = [NSNumber numberWithInt:(index+1)];
        }
    }
    
    // set main avatar and thumbnail depends on current available images
    if ([self.albumArray count] == 0) {
        self.me.avatarURL = @"";
        self.me.thumbnailURL = @"";
        self.me.thumbnailImage = nil;

    } else {
        Avatar *avatar = [self.albumArray objectAtIndex:0];        
        if (![avatar.imageRemoteThumbnailURL isEqualToString:self.me.thumbnailURL]) {
            self.me.avatarURL = avatar.imageRemoteURL;
            self.me.thumbnailURL = avatar.imageRemoteThumbnailURL;
            self.me.thumbnailImage = avatar.thumbnail;
            
            NSNotification *myNotification =
            [NSNotification notificationWithName:THUMBNAIL_IMAGE_CHANGE_NOTIFICATION object:self.me];
            [[NSNotificationQueue defaultQueue]
             enqueueNotification:myNotification
             postingStyle:NSPostWhenIdle
             coalesceMask:NSNotificationNoCoalescing
             forModes:nil];
        }
    }
    
    for (int i = self.albumCount; i < [self.albumButtonArray count]; i++) {
        UIButton *albumButton = [self.albumButtonArray objectAtIndex:i];
        [albumButton setHidden:YES];
    }
    
    // Calcuate where to display add album button. If display, also set editingAlbumIndex to start with Add
    if (self.albumCount == 0) {
        CGRect rect = [self calcRect:self.albumCount];
        [self.addAlbumButton setFrame:rect];
        [self.addAlbumButton setHidden:NO];
        self.addButtonIndex = self.albumCount;
    }else if (self.albumCount == MAX_ALBUN_COUNT){
        [self.addAlbumButton setHidden:YES];
    } else if (self.isEditing) {
        CGRect rect = [self calcRect:self.albumCount];
        [self.addAlbumButton setFrame:rect];
        [self.addAlbumButton setHidden:NO];
        self.addButtonIndex = self.albumCount;
    }else{
        [self.addAlbumButton setHidden:YES];
        
    }
    
}

- (void)albumClick:(UIButton *)sender
{
    AlbumViewController *albumViewController = [[AlbumViewController alloc] init];
    albumViewController.albumArray = self.albumArray;
    albumViewController.albumIndex = sender.tag;
    [albumViewController setHidesBottomBarWhenPushed:YES];
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:albumViewController animated:YES];
    DDLogVerbose(@"%d",sender.tag);
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actionsheet when add album
/////////////////////////////////////////////////////////////////////////////////////////

- (void)addOrReplaceAlbum:(UIButton *)sender
{
    // IsReplace if sender is nil
    if (sender == self.addAlbumButton) {
        [self setEditMode];
        self.editingAlbumIndex = self.addButtonIndex;
    }
    self.photoActionsheet = [[UIActionSheet alloc] 
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:T(@"取消")
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:T(@"本地相册"), T(@"照相"),nil];
    self.photoActionsheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [self.photoActionsheet showFromTabBar:[[self tabBarController] tabBar]];
}

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
    
    DDLogVerbose(@"editingAlbumIndex %d",self.editingAlbumIndex);
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
            [self addOrReplaceAlbum:nil];
        }else if (buttonIndex == 1) {
            [self removeAlbum];
        }
    }
    
}

- (void)removeAlbum
{
    DDLogVerbose(@"editingAlbumIndex %d",self.editingAlbumIndex);
    Avatar *removeAvatar = [self.albumArray objectAtIndex:self.editingAlbumIndex];
    removeAvatar.image = nil;
    removeAvatar.thumbnail  = nil;
    removeAvatar.imageRemoteThumbnailURL = @"";
    removeAvatar.imageRemoteURL = @"";
    removeAvatar.title = @"";
    
    [self refreshAlbumView];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImagePickerControllerDelegateMethods
//////////////////////////////////////////////////////////////////////////////////////////


- (void)takePhotoFromLibaray
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.delegate = self;
	picker.allowsEditing = YES;
    [self presentModalViewController:picker animated:YES];
}

- (void)takePhotoFromCamera
{
    if (![UIImagePickerController isSourceTypeAvailable:kCameraSource]) {
        UIAlertView *cameraAlert = [[UIAlertView alloc] initWithTitle:T(@"cameraAlert") message:T(@"Camera is not available.") delegate:self cancelButtonTitle:T(@"Cancel") otherButtonTitles:nil, nil];
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
	UIImage *originalImage = [info objectForKey:UIImagePickerControllerEditedImage];
    NSData *imageData = UIImageJPEGRepresentation(originalImage, JPEG_QUALITY);
    DDLogVerbose(@"Imagedata size %i", [imageData length]);
    UIImage *image = [UIImage imageWithData:imageData];
    
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // Save Video to Photo Album
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:imageData
                                         metadata:nil
                                  completionBlock:^(NSURL *assetURL, NSError *error){}];
    }

    UIImage *thumbnail = [image imageCroppedToFitSize:CGSizeMake(75, 75)];
    
    if (self.editingAlbumIndex != NSNotFound) {
        
        Avatar *avatar = [self.albumArray objectAtIndex:self.editingAlbumIndex];
        self.editingAlbumIndex = NSNotFound;
    
        // HUD show
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        HUD.labelText = T(@"上传中");
        
        //网路传输
        [[AppNetworkAPIClient sharedClient] storeImage:image thumbnail:thumbnail forMe:me andAvatar:avatar withBlock:^(id responseObject, NSError *error) {
            [HUD hide:YES];
            if ((responseObject != nil) && error == nil) {

                [[self appDelegate] saveContextInDefaultLoop];

                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"上传成功") andHideAfterDelay:2];
            } else {
                DDLogVerbose (@"NSError received during store avatar: %@", error);
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"上传失败") andHideAfterDelay:2];
            }
            
            [self refreshAlbumView];
            [picker dismissModalViewControllerAnimated:YES];
            
        }];
    }
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

- (void)refreshStatusView
{
    if (self.me.birthdate) {
        NSDate *now = [NSDate date];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        //unsigned int unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit;
        NSDateComponents *comps = [gregorian components:NSYearCalendarUnit fromDate:self.me.birthdate  toDate:now  options:0];
        NSString* ageStr = [NSString stringWithFormat:@"%d", comps.year];
        
        self.sexLabel.text  = ageStr;
        self.horoscopeLabel.text = [self.me.birthdate horoscope];
    }
    
    self.guidLabel.text  = [ NSString stringWithFormat:@" %@: %@",T(@"ID"),self.me.guid ];

}

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
    
    self.sexView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:bgImgStr]];
    [self.sexView setFrame:CGRectMake(0, 0, 50, 20)];
    
    
    self.sexLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 20, 20)];
    [self.sexLabel setBackgroundColor:[UIColor clearColor]];
    [self.sexLabel setFont:[UIFont systemFontOfSize:14.0]];
    [self.sexLabel setTextColor:[UIColor whiteColor]];
    [self.sexView addSubview:self.sexLabel];

    self.horoscopeLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 0, 100, 20)];
    [self.horoscopeLabel setBackgroundColor:[UIColor clearColor]];
    [self.horoscopeLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    [self.horoscopeLabel setShadowColor:[UIColor whiteColor]];
    [self.horoscopeLabel setShadowOffset:CGSizeMake(0, 1)];
    [self.horoscopeLabel setTextColor:RGBCOLOR(97, 97, 97)];
    [self.statusView addSubview:self.horoscopeLabel];
    
    self.guidLabel = [[UILabel alloc]initWithFrame:CGRectMake(210, 0, 100, 20)];
    [self.guidLabel setBackgroundColor:[UIColor clearColor]];
    [self.guidLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    [self.guidLabel setShadowColor:[UIColor whiteColor]];
    [self.guidLabel setShadowOffset:CGSizeMake(0, 1)];
    [self.guidLabel setTextColor:RGBCOLOR(97, 97, 97)];
    [self.statusView addSubview:self.guidLabel];
    
    
    // add to the statusView
    [self.statusView addSubview:self.sexView];
    [self.contentView addSubview: self.statusView];
    
    [self refreshStatusView];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - sns view
////////////////////////////////////////////////////////////////////////////////
- (void)initSNSView
{
    self.snsView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + VIEW_INFO_HEIGHT, VIEW_COMMON_WIDTH, VIEW_SNS_HEIGHT*3)];
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 20)];
    titleLabel.text = T(@"社交认证");
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.backgroundColor = [UIColor clearColor];
    [self.snsView addSubview:titleLabel];
    
    NSArray *buttonNames = SNS_ARRAY;
    NSUInteger _count = [buttonNames count];
    UIButton *snsButton;
    UILabel *snsLabel;
    
    for (int index = 0; index < _count; index++ ) {
        snsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        snsButton.enabled = YES;
        [snsButton setFrame:CGRectMake( VIEW_COMMON_WIDTH / _count * index, 30, VIEW_COMMON_WIDTH / 3, VIEW_SNS_HEIGHT)];
        [snsButton setTitleColor:RGBCOLOR(108, 108, 108) forState:UIControlStateNormal];
        snsButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [snsButton.layer setMasksToBounds:YES];
        [snsButton.layer setCornerRadius:3.0];
        snsButton.backgroundColor = RGBCOLOR(255, 255, 255);
        [snsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_big_icon_%i.png",index]] forState:UIControlStateNormal];
        
        snsButton.tag = 1000 + index;
        [snsButton addTarget:self action:@selector(snsAction:) forControlEvents:UIControlEventTouchUpInside];
        
        snsLabel = [[UILabel alloc] initWithFrame:CGRectMake( VIEW_COMMON_WIDTH / _count * index, 40+VIEW_SNS_HEIGHT, VIEW_COMMON_WIDTH / 3, 20)];
        snsLabel.text = [buttonNames objectAtIndex:index];
        snsLabel.textAlignment = UITextAlignmentCenter;
        snsLabel.textColor = [UIColor blackColor];
        snsLabel.backgroundColor = [UIColor clearColor];
        snsLabel.font = [UIFont systemFontOfSize:14];
        
        [self.snsView addSubview:snsLabel];
        [self.snsView addSubview:snsButton];
        
    }
    
    [self.contentView addSubview: self.snsView];
    
}

- (void)refreshSNSView
{    
    NSArray *buttonNames = SNS_ARRAY;
    NSUInteger _count = [buttonNames count];
    UIButton *snsButton;
    for (int index = 0; index < _count; index++ ) {
        
        if (StringHasValue(self.me.sinaWeiboID)) {
             snsButton = (UIButton *)[self.snsView viewWithTag:index+1000];
            [snsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_big_icon_%i_c.png",index]] forState:UIControlStateNormal];
            [snsButton removeTarget:self action:@selector(snsAction:) forControlEvents:UIControlEventTouchUpInside];
            [snsButton addTarget:self action:@selector(cancelSnsAction:) forControlEvents:UIControlEventTouchUpInside];
        }else{
            snsButton = (UIButton *)[self.snsView viewWithTag:index+1000];
            [snsButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sns_big_icon_%i.png",index]] forState:UIControlStateNormal];

        }
    }
}


-(void)snsAction:(UIButton *)sender
{
    if (self.isEditing) {
//        DDLogVerbose(@"Seg.selectedSegmentIndex:%d",sender.tag);
        if (sender.tag = 1000) {
            SinaWeiboViewController *controller = [[SinaWeiboViewController alloc]initWithNibName:nil bundle:nil];
            controller.valueIndex = SINAWEIBO_ITEM_INDEX;
            controller.passDelegate = self;
            [self.navigationController pushViewController:controller animated:YES];
            
            [XFox logEvent:EVENT_ADD_WEIBO];
        }
    }else{
        [self editModeMBPNotice];
    }

}

-(void)cancelSnsAction:(UIButton *)sender
{
//    DDLogVerbose(@"Seg.selectedSegmentIndex:%d",sender.tag);
    if (self.isEditing) {

        if (sender.tag = 1000) {
            self.weiboAlertView = [[UIAlertView alloc]initWithTitle:T(@"解除绑定")
                                                          message:T(@"即将解除绑定新浪微薄.成功后其他用户将看不到你的微博资料和动态")
                                                         delegate:self
                                                cancelButtonTitle:T(@"取消")
                                                otherButtonTitles:T(@"确定"), nil];
            [self.weiboAlertView show];
        
        }
    }else{
        [self editModeMBPNotice];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView isEqual:self.weiboAlertView]) {
        if (buttonIndex == 0){
            //cancel clicked ...do your action
        }else if (buttonIndex == 1){
            [XFox logEvent:EVENT_DEL_FRIEND withParameters:[NSDictionary dictionaryWithObjectsAndKeys:self.me.sinaWeiboID, @"weiboID", nil]];
            self.me.sinaWeiboID = nil;
            UIButton *snsButton = (UIButton *)[self.snsView viewWithTag:1000];
            [snsButton setImage:[UIImage imageNamed:@"sns_big_icon_0.png"] forState:UIControlStateNormal];
            [snsButton removeTarget:self action:@selector(cancelSnsAction:) forControlEvents:UIControlEventTouchUpInside];
            [snsButton addTarget:self action:@selector(snsAction:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}
////////////////////////////////////////////////////////////////////////////////
#pragma mark - sinaweibo delegate
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
#pragma mark - info view
////////////////////////////////////////////////////////////////////////////////
- (void)initInfoView
{
    self.infoView = [[UIView alloc] initWithFrame:
                     CGRectMake(0, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + 15, self.view.frame.size.width, VIEW_INFO_HEIGHT)];
    self.infoView.backgroundColor = [UIColor clearColor];

    self.infoArray = [[NSArray alloc] initWithObjects:
                      [[NSArray alloc] initWithObjects:T(@"签名"),nil],
                      [[NSArray alloc] initWithObjects:T(@"昵称"),T(@"生日"),nil],
                      [[NSArray alloc] initWithObjects:T(@"手机"),T(@"职业"),T(@"公司"),T(@"学校"),nil],
                      [[NSArray alloc] initWithObjects:T(@"兴趣爱好"),T(@"常出没的地方"),T(@"个人说明"),nil],
                      nil];
    

    // brithdate transform
    NSDateFormatter *df = [[NSDateFormatter alloc] init]; 
    [df setDateFormat:@"yyyy-MM-dd"];
    NSString* dateString = [df stringFromDate:self.me.birthdate];
    if (dateString == nil) {
        dateString = @"";
    }
    
    self.infoDescArray = [[NSMutableArray alloc] initWithObjects:
                          [[NSMutableArray alloc] initWithObjects:self.me.signature,nil],
                          [[NSMutableArray alloc] initWithObjects:self.me.displayName, dateString,nil],
                          [[NSMutableArray alloc] initWithObjects: self.me.cell,self.me.career,self.me.company,self.me.school,nil],
                          [[NSMutableArray alloc] initWithObjects:self.me.interest,self.me.alwaysbeen,self.me.selfIntroduction,nil],
                          nil];
    
    self.infoTableView = [[UITableView alloc]initWithFrame:self.infoView.bounds style:UITableViewStyleGrouped];
    self.infoTableView.dataSource = self;
    self.infoTableView.delegate = self;
    self.infoTableView.backgroundView = nil;
    [self.infoTableView setBackgroundColor:[UIColor clearColor]];
    
    [self.infoView addSubview:self.infoTableView];
    
    [self.contentView addSubview:self.infoView];    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - info table view
////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 3){
        if ( indexPath.row == 2) {
            return 120.0;
        }else{
            return 80.0;
        }
    }else if(indexPath.section ==0){
        return 60.0;
    }else{
        return 44.0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }else if(section == 1){
        return 2;
    }else if(section == 2){
        return 4;
    }else if(section == 3){
        return 3;
    }else{
        return 2;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProfileMeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    
    return cell;
    
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, message, and quarter image of the time zone.
	 */
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;    
    cell.backgroundView.backgroundColor = RGBCOLOR(79, 83, 89);
    
    NSArray *titleArray = (NSArray *)[self.infoArray objectAtIndex:indexPath.section];
    NSArray *descArray = (NSArray *)[self.infoDescArray objectAtIndex:indexPath.section];
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 70, 24)];
    titleLabel.text = [titleArray objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(155, 161, 172);
    titleLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:titleLabel];
    
    
    // Create a label for the summary
    UILabel* descLabel;
	CGRect rect = CGRectMake( 80, 10, 210, 30);
	descLabel = [[UILabel alloc] initWithFrame:rect];
    descLabel.numberOfLines = 0;
	descLabel.font = [UIFont systemFontOfSize:13.0];
	descLabel.textAlignment = UITextAlignmentLeft;
    descLabel.textColor = RGBCOLOR(125, 125, 125);
    descLabel.backgroundColor = [UIColor clearColor];
    descLabel.tag = 1002;

    NSString *text = @"";
    if (indexPath.row < [descArray count]){
        text = [descArray objectAtIndex:indexPath.row];
    }
    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    CGFloat _labelHeight;
    
    CGSize signatureSize = [text sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > 20) {
        if (indexPath.section == 0) {
            _labelHeight = 14.0;
        }else{
            _labelHeight = 6.0;
        }
    }else {
        if (indexPath.section == 0) {
            _labelHeight = 22.0;
        }else{
            _labelHeight = 14.0;
        }
    }
    descLabel.text = text;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signatureSize.width , signatureSize.height );
    
    
    if( indexPath.section == 3 ){
        titleLabel.frame    = CGRectMake(20, 10, 150, 20);
        descLabel.frame     = CGRectMake(10, 37, SUMMARY_WIDTH + 50 , signatureSize.height );
    }else if( indexPath.section == 0 && indexPath.row == 0){
        titleLabel.frame = CGRectMake(20, 20, 150, 20);
    }
    
    
    [cell.contentView addSubview:descLabel];
    
    
    return cell;
}

- (void)editModeMBPNotice
{
    [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"请点击右上角编辑按钮") detail:T(@"开启编辑模式") andHideAfterDelay:1];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //回退的时候如果没有保存上传 自动上传
    if ([self.navigationController.viewControllers indexOfObject:self]== NSNotFound) {
        if (self.isEditing) {
            [self saveEditMode];
        }
    }
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
