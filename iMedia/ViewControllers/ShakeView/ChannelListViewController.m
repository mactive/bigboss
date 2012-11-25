//
//  ChannelListViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-25.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ChannelListViewController.h"
#import "AppNetworkAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"

#define NAME_TAG 1
#define SNS_TAG 20
#define AVATAR_TAG 3
#define SUMMARY_TAG 4

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0

#define MIDDLE_COLUMN_OFFSET 90.0
#define MIDDLE_COLUMN_WIDTH 100.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 12.0
#define LABEL_HEIGHT 20.0
#define SUMMARY_PADDING 10.0

#define IMAGE_SIDE 50.0
#define SNS_SIDE 15.0
#define SUMMARY_WIDTH_OFFEST 20.0
#define SUMMARY_WIDTH 130.0
#define ROW_HEIGHT  60.0



@interface ChannelListViewController ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}

@property(nonatomic, strong)NSArray *dataArray;

@end

@implementation ChannelListViewController
@synthesize dataArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return self;
}

// 排序算法
NSInteger intSort2(id num1, id num2, void *context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.title = T(@"频道列表");
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.view setBackgroundColor:BGCOLOR];
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = T(@"正在加载信息");
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[AppNetworkAPIClient sharedClient]getChannelListWithBlock:^(id responseObject, NSError *error) {
        if (responseObject) {
            [HUD hide:YES];
            NSDictionary *responseDict = responseObject;
            NSDictionary *item = [[NSDictionary alloc]init];
            NSMutableArray *tempArray = [[NSMutableArray alloc]init];
            NSArray *keyArray = [[responseDict allKeys] sortedArrayUsingFunction:intSort2 context:NULL];
            
            for (int j = 0;  j< [keyArray count]; j++) {
                NSString * KEY = [keyArray objectAtIndex:j];
                item = [responseDict objectForKey:KEY];
                [tempArray addObject:item];
            }
            self.dataArray  = tempArray;
            [self.tableView reloadData];
        }else{
            [HUD hide:YES];
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.mode = MBProgressHUDModeText;
            HUD.delegate = self;
            HUD.labelText = T(@"网络错误，无法获取信息");
            [HUD hide:YES afterDelay:1];
        }
    }];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROW_HEIGHT;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ChannelList";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];
    
    
    return cell;
}


////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuring table view cells
////////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
    cell.backgroundView = cellBgView;
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    
    UILabel *label;
    CGRect rect;
    // Create an image view for the quarter image.
	CGRect imageRect = CGRectMake(LEFT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:imageRect];
    avatarImage.tag = AVATAR_TAG;
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
    [cell.contentView addSubview:avatarImage];
    
    // Create a label for the user name.
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, (ROW_HEIGHT - LABEL_HEIGHT) / 2.0, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = NAME_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(107, 107, 107);
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];
    
    // Create a label for the summary
	rect = CGRectMake(self.view.frame.size.width - SUMMARY_WIDTH - SUMMARY_WIDTH_OFFEST , (ROW_HEIGHT - LABEL_HEIGHT) / 2.0, SUMMARY_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = SUMMARY_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
	label.textAlignment = UITextAlignmentCenter;
    label.textColor = RGBCOLOR(158, 158, 158);
    label.backgroundColor = RGBCOLOR(236, 238, 240);
    
    [label.layer setMasksToBounds:YES];
    [label.layer setCornerRadius:3.0];
	[cell.contentView addSubview:label];
    
    return  cell;
}


- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary * data = [self.dataArray objectAtIndex:indexPath.row];
    
    // set max size
    CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*2);
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);

    
    // set the avatar
    UIImageView *imageView;
    NSString *_nameString = [data objectForKey:@"nickname"];
    NSString *_signatureString = [NSString stringWithFormat:@"ID:%@-%@ ",[data objectForKey:@"guid"],[data objectForKey:@"self_introduction"]];
    CGFloat _labelHeight;
    
    //set avatar
    imageView = (UIImageView *)[cell viewWithTag:AVATAR_TAG];
    NSURL *url = [NSURL URLWithString:[data objectForKey:@"thumbnail"]];
    [imageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"placeholder_user.png"]];
       
    // set the name text
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:NAME_TAG];
    
    CGSize labelSize = [_nameString sizeWithFont:nameLabel.font constrainedToSize:nameMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (labelSize.height > LABEL_HEIGHT) {
        _labelHeight = 10.0;
    }else {
        _labelHeight = 20.0;
    }
    nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, _labelHeight, labelSize.width, labelSize.height);
    nameLabel.text = _nameString;

    // set the user signature
    UILabel *signatureLabel = (UILabel *)[cell viewWithTag:SUMMARY_TAG];
    
    CGSize signatureSize = [_signatureString sizeWithFont:signatureLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > LABEL_HEIGHT) {
        _labelHeight = 10.0;
    }else {
        _labelHeight = 20.0;
    }
    signatureLabel.text = _signatureString;
    signatureLabel.frame = CGRectMake(280 - signatureSize.width - SUMMARY_PADDING, _labelHeight, signatureSize.width + SUMMARY_PADDING, signatureSize.height+SUMMARY_PADDING);
    
    if ([_signatureString length] == 0 || _signatureString == nil ) {
        [signatureLabel removeFromSuperview];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
