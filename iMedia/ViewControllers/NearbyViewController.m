//
//  NearbyViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-15.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "NearbyViewController.h"
#import "AppNetworkAPIClient.h"
#import "DDLog.h"
#import "NearbyTableViewCell.h"
#import "PullToRefreshView.h"
#import "ContactDetailController.h"
#import "AppDelegate.h"
#import "ConversationsController.h"
#import "User.h"
#import "Me.h"  
#import "ModelHelper.h"
#import "LocationManager.h"
#import "NSObject+SBJson.h"
#import "LocationManager.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "ServerDataTransformer.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@interface NearbyViewController ()<PullToRefreshViewDelegate,ChatWithIdentityDelegate,UIActionSheetDelegate>
{
	PullToRefreshView *pull;
    NSLock* _lock;
}

@property (nonatomic, strong) NSArray* sourceData;
@property (nonatomic, strong) UIButton *loadMoreButton;
@property (nonatomic, strong) UIButton *filterButton;
@property (nonatomic, strong) UIActionSheet *filterActionSheet;
@property( nonatomic, readwrite) NSUInteger genderInt;
@property( nonatomic, readwrite) NSUInteger startInt;
@property (nonatomic, readwrite) BOOL isLOADMORE;
@property (nonatomic, strong) NSDictionary* prefDict;
@property (nonatomic, strong) NSMutableDictionary* sourceDict;
@end

@implementation NearbyViewController
@synthesize sourceData;
@synthesize filterButton;
@synthesize filterActionSheet;
@synthesize genderInt;
@synthesize startInt;
@synthesize isLOADMORE;
@synthesize prefDict;
@synthesize sourceDict;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _lock = [[NSLock alloc] init];
        self.filterButton = [[UIButton alloc] init];
        self.filterButton.frame=CGRectMake(0, 0, 50, 29);
        [self.filterButton setBackgroundImage:[UIImage imageNamed: @"barbutton_bg.png"] forState:UIControlStateNormal];
        [self.filterButton setTitle:T(@"筛选") forState:UIControlStateNormal];
        [self.filterButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
        [self.filterButton addTarget:self action:@selector(filterAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.filterButton];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = BGCOLOR;
    

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.separatorColor = SEPCOLOR;
        self.tableView.backgroundColor = [UIColor whiteColor];
        
        // 初始全部并且
        self.genderInt = 0;
        self.startInt = 0;
        self.isLOADMORE = NO;
        
        if (StringHasValue([self appDelegate].me.lastSearchPreference)) {
            self.prefDict = [[self appDelegate].me.lastSearchPreference JSONValue];
        } else {
            self.prefDict = [NSMutableDictionary dictionaryWithCapacity:1];
        }
        
        NSNumber *gender = [self.prefDict valueForKey:@"gender"];
        if (gender != nil) {
            self.genderInt = gender.intValue;
        }
        
        
        pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.tableView];
        [pull setDelegate:self];
        [self.tableView addSubview:pull];
        
        // footerView
        self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 60)];
        
        self.loadMoreButton  = [[UIButton alloc] initWithFrame:CGRectMake(40, 10, 240, 40)];
        [self.loadMoreButton.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
        [self.loadMoreButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.loadMoreButton setTitleColor:RGBCOLOR(143, 183, 225) forState:UIControlStateHighlighted];
        [self.loadMoreButton.titleLabel setTextAlignment:UITextAlignmentCenter];
        [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
        [self.loadMoreButton setBackgroundColor:[UIColor clearColor]];
        //    [self.loadMoreButton.layer setBorderColor:[RGBCOLOR(187, 217, 247) CGColor]];
        //    [self.loadMoreButton.layer setBorderWidth:1.0f];
        [self.loadMoreButton.layer setCornerRadius:5.0f];
        [self.loadMoreButton addTarget:self action:@selector(loadMoreAction) forControlEvents:UIControlEventTouchUpInside];
        [self.loadMoreButton setHidden:YES];
        [self.tableView.tableFooterView addSubview:self.loadMoreButton];
        
        //    self.sourceData = [[NSArray alloc]init];
        self.sourceDict = [[NSMutableDictionary alloc]init];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    self.startInt = 0;
    [self populateDataWithGender:self.genderInt andStart:self.startInt];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // updateLocation self
#warning 如没有location 欢一个背景图  sourcedata = nil
    if ([LocationManager sharedInstance].isAllowed == NO) {
        
        [XFox logEvent:EVENT_LOCATION_OFF];
        pull.enabled = NO;
        [self.loadMoreButton setEnabled:NO];
        
        // do sth here

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:T(@"定位服务未开启") message:T(@"需要你在手机开启定位服务以看到附近用户") delegate:nil cancelButtonTitle:T(@"确定") otherButtonTitles:nil];
        [alert show];
        
        self.sourceData = [[NSArray alloc]init];
        [self.loadMoreButton setHidden:YES];
        [self.tableView reloadData];

    }else{
        pull.enabled = YES;
        [self.loadMoreButton setHidden:NO];
        [self.loadMoreButton setEnabled:YES];
        
        if (self.sourceData == nil || [self.sourceData count] == 0) {
            self.startInt = 0;
            [self populateDataWithGender:self.genderInt andStart:self.startInt];
        }
    }
    

}

-(void)loadMoreAction
{
    self.isLOADMORE = YES;
    [self populateDataWithGender:self.genderInt andStart:self.startInt];
    
}
// sort sourcedata
-(void)generateSourceDataFromDict:(NSDictionary*)dict
{
    NSArray *sortArray = [dict allValues];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    self.sourceData = [sortArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
}

- (void)populateDataWithGender:(NSUInteger)gender andStart:(NSUInteger)start
{
    // log event
    [XFox logEvent:EVENT_GET_NEARBY_USER withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:gender], @"gender", [NSNumber numberWithInt:start], @"start", nil]];
    
    [self.loadMoreButton setTitle:T(@"正在加载") forState:UIControlStateNormal];
    [self.loadMoreButton setEnabled:NO];
    pull.enabled = NO;
    
    if (gender == 0) {
        self.title = T(@"附近");
    } else if (gender == 1) {
        self.title = T(@"附近(男)");
    } else if (gender == 2) {
        self.title = T(@"附近(女)");
    }
        
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载");
    
    CLLocation *loc = [LocationManager sharedInstance].location;
    CGFloat lat =  loc.coordinate.latitude;
    CGFloat lon =  loc.coordinate.longitude;
    NSString *latString = [NSString stringWithFormat:@"%f",loc.coordinate.latitude];
    NSString *lonString = [NSString stringWithFormat:@"%f",loc.coordinate.longitude];
    [self appDelegate].me.lastGPSUpdated = loc.timestamp;
    [self appDelegate].me.lastGPSLocation = [NSString stringWithFormat:@"%@,%@", latString, lonString];
    
    [[AppNetworkAPIClient sharedClient]getNearestPeopleWithGender:gender start:start latitude:lat longitude:lon andBlock:^(id responseObject, NSError *error) {
        [HUD hide:YES];
        if (responseObject != nil) {
            
            NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithDictionary:responseObject];
            NSMutableDictionary *transDict = [[NSMutableDictionary alloc] init];
            
            self.startInt += [responseDict count];
            [responseDict removeObjectForKey:[self appDelegate].me.guid];  // 移出自己

            [responseDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                
                BOOL valid = StringHasValue([obj objectForKey:@"nickname"]);
                
                if (valid) {
                    //// location && time
                    NSString *lon  = [obj objectForKey:@"lon"];
                    NSString *lat  = [obj objectForKey:@"lat"];
                    
                    CLLocation *dataLocation = [[CLLocation alloc] initWithLatitude:[lat doubleValue]
                                                                          longitude:[lon doubleValue]];
                    CLLocationDistance dataDistance = -1.0f;
                    if ([LocationManager sharedInstance].location != nil && dataLocation != nil)
                        dataDistance = [dataLocation distanceFromLocation:[LocationManager sharedInstance].location];
                    NSNumber *distanceNumber = [NSNumber numberWithDouble:dataDistance];
                    
                    // 复制一份
                    NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithDictionary:obj];
                    [aDict setValue:distanceNumber forKey:@"distance"];
                    
                    [transDict setValue:aDict forKey:key];
                }
                
            }];
            
            // 去重复
            [_lock lock];
            if (self.isLOADMORE) {
                [self.sourceDict addEntriesFromDictionary:transDict];
            }else{
                self.sourceDict = transDict;
            }
            // 排序
            [self generateSourceDataFromDict:self.sourceDict];
            [_lock unlock];
            
            // 重新设置start
//            self.startInt = [self.sourceData count];
            
            // 数量太少不出现 load more
            if([responseDict count] == 0) {
                [self.loadMoreButton setTitle:T(@"没有更多了") forState:UIControlStateNormal];
            } else {
                [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
            }
            
            [self.tableView reloadData];
            
        }else{            
            [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误 暂时无法刷新") andHideAfterDelay:1];
        }
        
        [self.loadMoreButton setEnabled:YES];
        [self.loadMoreButton setHidden:NO];
        pull.enabled = YES;
        self.isLOADMORE = NO;
        [pull finishedLoading];
    }];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - action sheet
//////////////////////////////////////////////////////////////////////////////////////////
- (void)filterAction
{
    self.filterActionSheet = [[UIActionSheet alloc]
                              initWithTitle:T(@"筛选附近的人")
                              delegate:self
                              cancelButtonTitle:T(@"取消")
                              destructiveButtonTitle:T(@"查看全部")
                              otherButtonTitles:T(@"只看女生"), T(@"只看男生"), nil];
    self.filterActionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [self.filterActionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
}


/////////////////////////////////////////////
#pragma mark - uiactionsheet delegate
////////////////////////////////////////////
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([self.filterActionSheet isEqual:actionSheet] ) {
        
        if (buttonIndex == 0) {
            DDLogVerbose(@"查看全部");
            self.genderInt = 0;
            self.startInt  = 0;
            self.title = T(@"附近");
        } else if (buttonIndex == 1) {
            self.genderInt = 2;
            self.startInt  = 0;
            DDLogVerbose(@"查看女生");
            self.title = T(@"附近(女)");
        } else if (buttonIndex == 2){
            DDLogVerbose(@"查看男生");
            self.genderInt = 1;
            self.startInt  = 0;
            self.title = T(@"附近(男)");
        }else{
            return;
        }
        
        if ([LocationManager sharedInstance].isAllowed == NO) {
             pull.enabled = NO;
            [self.loadMoreButton setEnabled:NO];
            
            // do sth here
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:T(@"定位服务未开启") message:T(@"需要你在手机开启定位服务以看到附近用户") delegate:nil cancelButtonTitle:T(@"确定") otherButtonTitles:nil];
            [alert show];
            
            self.sourceData = [[NSArray alloc]init];
            [self.loadMoreButton setHidden:YES];
            [self.tableView reloadData];
            
        }else{
            pull.enabled = YES;
            [self.loadMoreButton setHidden:NO];
            [self.loadMoreButton setEnabled:YES];
            
            [self.prefDict setValue:[NSNumber numberWithInt:genderInt] forKey:@"gender"];
            [self appDelegate].me.lastSearchPreference = [self.prefDict JSONRepresentation];
            [self populateDataWithGender:self.genderInt andStart:self.startInt];
            
            [[self appDelegate] saveContextInDefaultLoop];
        }
        
    }
    
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview header and footer and fresh
//////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview delegate
//////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sourceData count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview datasource
//////////////////////////////////////////////////////////////////////////////////////////

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NearbyCell";
    
    NSDictionary *rowData = [self.sourceData objectAtIndex:indexPath.row];
    
    NearbyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[NearbyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.delegate = self;
    }
    
    [cell setNewData:rowData];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *rowData = [self.sourceData objectAtIndex:indexPath.row];
    [self getDict:[ServerDataTransformer getGUIDFromServerJSON:rowData]];
    
}

- (void)passUIImageValue:(UIImage *)value andKey:(NSString *)key{
    // refresh sourceDict
    [_lock lock];
    NSDictionary *originalDict = [self.sourceDict valueForKey:key];
    NSMutableDictionary *replaceDict = [[NSMutableDictionary alloc]initWithDictionary:originalDict];
    [replaceDict setValue:value forKey:@"cachedThumbnail"];
    [self.sourceDict setValue:replaceDict forKey:key];
    
    //refresh sourceDatas
    NSMutableArray * replaceArray = [[NSMutableArray alloc]initWithArray:self.sourceData];
    
    for (int i = 0; i< [replaceArray count]; i++) {
        NSDictionary *obj = [replaceArray objectAtIndex:i];
        NSString *guidString = [ServerDataTransformer getStringObjFromServerJSON:obj byName:@"guid"];
        if ( [guidString isEqualToString:key]) {
            [replaceArray replaceObjectAtIndex:i withObject:replaceDict];
        }
    }
    
    self.sourceData = replaceArray;
    
    [_lock unlock];
    
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getDict:(NSString *)guidString
{
    
    // if the user already exist - then show the user
    User* aUser = [[ModelHelper sharedInstance] findUserWithGUID:guidString];
    
    if (aUser != nil && aUser.state == IdentityStateActive) {
        // it is a buddy on our contact list
        ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
        controller.user = aUser;
        controller.GUIDString = guidString;
        controller.managedObjectContext = [self appDelegate].context;
        
        // Pass the selected object to the new view controller.
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        // get user info from web and display as if it is searched
        NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: guidString, @"guid", @"1", @"op", nil];
        
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        
        [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //DDLogVerbose(@"nearby user get one received: %@", responseObject);
            
            [HUD hide:YES];
            NSString* type = [responseObject valueForKey:@"type"];
            if ([type isEqualToString:@"user"]) {
                ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
                controller.jsonData = responseObject;
                controller.managedObjectContext = [self appDelegate].context;
                controller.GUIDString = guidString;
                // Pass the selected object to the new view controller.
                [controller setHidesBottomBarWhenPushed:YES];
                [self.navigationController pushViewController:controller animated:YES];
                
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //
            DDLogVerbose(@"error received: %@", error);
            [HUD hide:YES];
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误，无法获取用户数据") andHideAfterDelay:1];
        }];
        
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewController:(UIViewController *)viewController didChatIdentity:(id)obj
{
    [self dismissModalViewControllerAnimated:YES];
    
    if (obj) {
        [self.tabBarController setSelectedIndex:1];
        [[self appDelegate].conversationController chatWithIdentity:obj];
    }
    
}


@end
