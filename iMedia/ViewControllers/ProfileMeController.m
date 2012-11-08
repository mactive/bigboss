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
#import "AFImageRequestOperation.h"
#import "EditViewController.h"
#import "ServerDataTransformer.h"
#import "MBProgressHUD.h"
#import "NSDate+timesince.h"

#define SUMMARY_WIDTH 200
#define LABEL_HEIGHT 20
#define kCameraSource       UIImagePickerControllerSourceTypeCamera
#define MAX_ALBUN_COUNT 8

@interface ProfileMeController ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}
@property(strong, nonatomic) NSMutableArray * albumButtonArray;
@property(strong, nonatomic) UIActionSheet *photoActionsheet;
@property(strong, nonatomic) UIActionSheet *editActionsheet;
@property(readwrite, nonatomic) NSUInteger editingAlbumIndex;
@property(readwrite, nonatomic) BOOL isEditing;

@property(strong, nonatomic) NSMutableArray *infoCellArray;

@property (strong, nonatomic) UIScrollView *contentView;
@property (strong, nonatomic) UITableView *infoTableView;

@property (strong, nonatomic) UIView *albumView;
@property (strong, nonatomic) UIView *statusView;
@property (strong, nonatomic) UIView *snsView;
@property (strong, nonatomic) UIView *infoView;

@property (strong, nonatomic) UIImageView *sexView;
@property (strong, nonatomic) UILabel *sexLabel;

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

@synthesize editProfileButton;
@synthesize albumCount;
@synthesize albumButtonArray;
@synthesize photoActionsheet;
@synthesize editActionsheet;
@synthesize editingAlbumIndex;
@synthesize infoCellArray;
@synthesize isEditing;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.me = [self appDelegate].me ;
        [self.infoTableView setAllowsSelection:NO];
        self.isEditing = NO;
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - edit mode
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setEditMode
{
    UIBarButtonItem *ttButton = [[UIBarButtonItem alloc] initWithTitle:T(@"保存") 
                                                              style:UIBarButtonItemStyleDone 
                                                             target:self
                                                                action:@selector(saveEditMode:)];
    [ttButton setTintColor:RGBCOLOR(80, 192, 77)];
    self.navigationItem.rightBarButtonItem = ttButton;
    self.isEditing = YES;
    

    [self infoTableEditing];
    [self refreshAlbumView];
    
    // table into setting
}

- (void)saveEditMode:(id)sender
{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = T(@"更新中");
    // save and upload
    [[AppNetworkAPIClient sharedClient] uploadMe:self.me withBlock:^(id responseObject, NSError *error) {
        if ((responseObject != nil) && (error == nil)) {
            // HUD hide
            [HUD hide:YES];
            
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.delegate = self;
            HUD.mode = MBProgressHUDModeText;
            HUD.labelText = T(@"更新成功");
            [HUD hide:YES afterDelay:1];
            
        }else {
            NSLog (@"NSError received during upload me: %@", error);
            
            // HUD hide
            [HUD hide:YES];
            // HUD show error
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.mode = MBProgressHUDModeText;
            HUD.delegate = self;
            HUD.labelText = T(@"更新失败");
            [HUD hide:YES afterDelay:1];
        }
    }];
    
    self.navigationItem.rightBarButtonItem = self.editProfileButton;
    
    self.isEditing = NO;
    
    [self infoTableCommitEdit];
    [self refreshAlbumView];
}



- (void)infoTableEditing{
    for (int index =0; index < [self.infoCellArray count]; index++) {
        UITableViewCell *cell = [self.infoCellArray objectAtIndex:index];
        if (index != SEX_ITEM_INDEX ) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    UITableViewCell *cell = [self.infoCellArray objectAtIndex:indexPath.row];
    
    if (self.isEditing && indexPath.row != SEX_ITEM_INDEX) {
        NSLog(@"click the %d",indexPath.row);
        
        EditViewController *controller = [[EditViewController alloc] initWithNibName:nil bundle:nil];
        controller.nameText = [self.infoArray objectAtIndex:indexPath.row];
//        NSLog(@"%@",[self.infoDescArray objectAtIndex:indexPath.row]);
        if ([self.infoDescArray objectAtIndex:indexPath.row] != NULL) {
            controller.valueText = [self.infoDescArray objectAtIndex:indexPath.row];
        }else {
            NSLog(@"---");
        }
        controller.valueIndex = indexPath.row;
        controller.delegate = self;
        
        if (indexPath.row == SEX_ITEM_INDEX  ) {
            controller.valueType = @"gender";
        }else if (indexPath.row == BIRTH_ITEM_INDEX) {
            controller.valueType = @"date";
        }else if (indexPath.row == NICKNAME_ITEM_INDEX) {
            controller.valueType = @"shorttext";
        }else {
            controller.valueType = nil;
        }
        
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];

    }
}
// Protocl function
-(void)passStringValue:(NSString *)value andIndex:(NSUInteger )index;
{
    NSLog(@"*** %@ %d ***",value,index);
    
    // sex dict
    if (index == SEX_ITEM_INDEX) {
        value = [[ServerDataTransformer sexDict] objectForKey:value];
    }
    
    UITableViewCell *cell = [self.infoCellArray objectAtIndex:index];
    UILabel *descLabel = (UILabel *)[cell viewWithTag:1002];
    
    // resize the label for multiline
    
    CGSize summaryMaxSize = CGSizeZero;
    if( index == [self.infoArray count] -1 ){
        summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    }else{
        summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);
    }
    CGFloat _labelHeight;
    
    CGSize signatureSize = [value sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > 20) {
        _labelHeight = 6.0;
    }else {
        _labelHeight = 14.0;
    }
    descLabel.text = value;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signatureSize.width , signatureSize.height );
    if( index == [self.infoArray count] -1 ){
        descLabel.frame = CGRectMake(20, _labelHeight + 25 , SUMMARY_WIDTH + 50 , signatureSize.height );
    }
    
    [self.infoDescArray replaceObjectAtIndex:index withObject:value];
    
    switch (index) {
        case NICKNAME_ITEM_INDEX:
            self.me.displayName = value;
            break;
        case SEX_ITEM_INDEX:
            self.me.gender = value;
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
        case SELF_INTRO_ITEM_INDEX:
            self.me.selfIntroduction = value;
            break;
        default:
            break;
    }
    
}

- (void)passNSDateValue:(NSDate *)value andIndex:(NSUInteger)index
{

    UITableViewCell *cell = [self.infoCellArray objectAtIndex:index];
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
    
    [self.infoDescArray replaceObjectAtIndex:index withObject:valueStr];
    
    self.me.birthdate = value;
    [self refreshStatusView];
}

- (void)infoTableCommitEdit{
    for (int index =0; index < [self.infoCellArray count]; index++) {
        UITableViewCell *cell = [self.infoCellArray objectAtIndex:index];
        cell.accessoryType = UITableViewCellAccessoryNone;        
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
    
    NSLog(@"editingAlbumIndex %d",self.editingAlbumIndex);
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
                                                         action:@selector(setEditMode)];

    self.navigationItem.rightBarButtonItem = self.editProfileButton;
}

- (void)loadView
{
    [super loadView];
    self.contentView = [[UIScrollView alloc]initWithFrame:
                        CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - VIEW_ACTION_HEIGHT - VIEW_UINAV_HEIGHT)];
    [self.contentView setContentSize:CGSizeMake(self.view.frame.size.width, 720)];
    [self.contentView setScrollEnabled:YES];
    self.contentView.backgroundColor = RGBCOLOR(222, 224, 227);
    
    self.editingAlbumIndex = NSNotFound;
        
    [self initAlbumView];
    [self refreshAlbumView];
    [self initStatusView];
//    [self initSNSView];
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
    [self.contentView addSubview:self.albumView];
    
    self.addAlbumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.addAlbumButton.layer setMasksToBounds:YES];
    [self.addAlbumButton.layer setCornerRadius:3.0];
    self.addAlbumButton.tag = 1000;
    [self.addAlbumButton setImage:[UIImage imageNamed:@"profile_add.png"] forState:UIControlStateNormal];
    [self.addAlbumButton addTarget:self action:@selector(addAlbum:) forControlEvents:UIControlEventTouchUpInside];
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
        self.editingAlbumIndex = self.albumCount;
    }else if (self.albumCount == MAX_ALBUN_COUNT){
        [self.addAlbumButton setHidden:YES];
    } else if (self.isEditing) {
        CGRect rect = [self calcRect:self.albumCount];
        [self.addAlbumButton setFrame:rect];
        [self.addAlbumButton setHidden:NO];
        self.editingAlbumIndex = self.albumCount;
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
                                  otherButtonTitles:T(@"本地相册"), T(@"照相"),nil];
    self.photoActionsheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [self.photoActionsheet showFromTabBar:[[self tabBarController] tabBar]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.photoActionsheet) {
        if (buttonIndex == 0) {
            [self setEditMode]; 
            [self takePhotoFromLibaray];  
        }else if (buttonIndex == 1) {
            [self setEditMode]; 
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
    NSLog(@"editingAlbumIndex %d",self.editingAlbumIndex);
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
    NSLog(@"Imagedata size %i", [imageData length]);
    UIImage *image = [UIImage imageWithData:imageData];
    
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // Save Video to Photo Album
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:imageData
                                         metadata:nil
                                  completionBlock:^(NSURL *assetURL, NSError *error){}];
    }

    UIImage *thumbnail = [image resizedImageToSize:CGSizeMake(75, 75)];
    Avatar *avatar;
    
    if (self.editingAlbumIndex != NSNotFound) {
        
        avatar = [self.albumArray objectAtIndex:self.editingAlbumIndex];
        self.editingAlbumIndex = NSNotFound;
    
        // HUD show
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.delegate = self;
        HUD.labelText = T(@"上传中");
        
        //网路传输
        [[AppNetworkAPIClient sharedClient] storeAvatar:avatar forMe:self.me andOrder:avatar.sequence.intValue withBlock:^(id responseObject, NSError *error) {
            if ((responseObject != nil) && error == nil) {

                avatar.image = image;
                avatar.thumbnail = thumbnail;
                avatar.imageRemoteURL = @"";
                avatar.imageRemoteThumbnailURL = @"";
                MOCSave(self.managedObjectContext);

                // HUD hide
                [HUD hide:YES];
                // HUD show success
                HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                HUD.mode = MBProgressHUDModeText;
                HUD.delegate = self;
                HUD.labelText = T(@"上传成功");
                [HUD hide:YES afterDelay:2];
            } else {
                NSLog (@"NSError received during store avatar: %@", error);
                
                // HUD hide
                [HUD hide:YES];
                // HUD show error
                HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                HUD.mode = MBProgressHUDModeText;
                HUD.delegate = self;
                HUD.labelText = T(@"上传失败");
                [HUD hide:YES afterDelay:2];
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
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //unsigned int unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit fromDate:self.me.birthdate  toDate:now  options:0];
    NSString* ageStr = [NSString stringWithFormat:@"%d", comps.year];
    
    sexLabel.text  = ageStr;
}

- (void)initStatusView
{
    self.statusView = [[UIView alloc] initWithFrame:CGRectMake(VIEW_PADDING_LEFT, VIEW_ALBUM_HEIGHT + 15, VIEW_COMMON_WIDTH, 15)];
    
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

    UILabel* horoscopeLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 0, 100, 20)];
    [horoscopeLabel setBackgroundColor:[UIColor clearColor]];
    horoscopeLabel.text = [self.me.birthdate horoscope];
    [horoscopeLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    [horoscopeLabel setShadowColor:[UIColor whiteColor]];
    [horoscopeLabel setShadowOffset:CGSizeMake(0, 1)];
    [horoscopeLabel setTextColor:RGBCOLOR(97, 97, 97)];
    [self.statusView addSubview:horoscopeLabel];
    
    UILabel* guidLabel = [[UILabel alloc]initWithFrame:CGRectMake(210, 0, 100, 20)];
    [guidLabel setBackgroundColor:[UIColor clearColor]];
    guidLabel.text  = [ NSString stringWithFormat:@" %@: %@",T(@"ID"),self.me.guid ];
    [guidLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    [guidLabel setShadowColor:[UIColor whiteColor]];
    [guidLabel setShadowOffset:CGSizeMake(0, 1)];
    [guidLabel setTextColor:RGBCOLOR(97, 97, 97)];
    [self.statusView addSubview:guidLabel];
    
    
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
                     CGRectMake(0, VIEW_ALBUM_HEIGHT + VIEW_STATUS_HEIGHT + 15, self.view.frame.size.width, 520)];
    self.infoView.backgroundColor = [UIColor clearColor];
    self.infoCellArray = [[NSMutableArray alloc] init];

    self.infoArray = [[NSArray alloc] initWithObjects:T(@"昵称"),T(@"性别"),T(@"生日"),T(@"签名"),T(@"手机"),T(@"职业"),T(@"家乡"),T(@"个人说明"),nil ];
    
    // brithdate transform
    NSDateFormatter *df = [[NSDateFormatter alloc] init]; 
    [df setDateFormat:@"yyyy-MM-dd"];
    NSString* dateString = [df stringFromDate:self.me.birthdate];
    
    self.infoDescArray = [[NSMutableArray alloc] initWithObjects:
                          self.me.displayName,
                          self.me.gender,
                          dateString,
                          self.me.signature,
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
        [self.infoCellArray addObject:cell];
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
    
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 70, 20)];
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
    descLabel.tag = 1002;
   
    NSString *text = @"";
    if (indexPath.row < [self.infoDescArray count]){
        text = [self.infoDescArray objectAtIndex:indexPath.row];
        // sex dict
        if (indexPath.row == SEX_ITEM_INDEX) {
            NSString *_tmp = [self.infoDescArray objectAtIndex:indexPath.row];
            text = [[ServerDataTransformer sexDict] objectForKey:_tmp];
        }
    }
    
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*4);
    CGFloat _labelHeight;
    
    CGSize signatureSize = [text sizeWithFont:descLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > 20) {
        _labelHeight = 6.0;
    }else {
        _labelHeight = 14.0;
    }
    descLabel.text = text;
    descLabel.frame = CGRectMake(descLabel.frame.origin.x, _labelHeight, signatureSize.width , signatureSize.height );
    
    
    if( indexPath.row == [self.infoArray count] -1 ){
        descLabel.frame = CGRectMake(20, _labelHeight + 25 , SUMMARY_WIDTH + 50 , signatureSize.height );
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
