//
//  MemoViewController.m
//  jiemo
//
//  Created by meng qian on 12-12-11.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import "MemoViewController.h"
#import "AppNetworkAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import "ConvenienceMethods.h"
#import "NSDate+timesince.h"
#import "Information.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface MemoViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic, strong)NSArray *dataArray;
@property(nonatomic, strong)UIView *noticeView;
@property(nonatomic, strong)UILabel *noticeLabel;
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)UIButton *barButton;

@end

@implementation MemoViewController
@synthesize managedObjectContext;
@synthesize dataArray;
@synthesize noticeLabel;
@synthesize noticeView;
@synthesize tableView;
@synthesize barButton;

#define SUMMARY_WIDTH 200.0
#define LABEL_HEIGHT 20.0

#define DESC_TAG 10
#define TYPE_TAG 11
#define ROW_HEIGHT 50

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_mainmenu.png"] forState:UIControlStateNormal];
        [self.barButton addTarget:self action:@selector(mainMenuAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setHidesBackButton:YES];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
        
    }
    return self;
}

- (void)mainMenuAction
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = T(@"系统通知中心");
    
    self.view.backgroundColor = BGCOLOR;
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = SEPCOLOR;
    
    self.tableView.delegate = self;
    self.tableView.dataSource  = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self initDataArray];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}


- (void)initDataArray
{
    // 
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Information" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdOn" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    self.dataArray = [[NSArray alloc]initWithArray:mutableFetchResults];
    
    if (mutableFetchResults == nil) {
        // Handle the error.
    }
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
    static NSString *CellIdentifier = @"MemoViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];
    
    
    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    
    //    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
    //    cell.backgroundView = cellBgView;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.textColor = RGBCOLOR(195, 70, 21);
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.layer.cornerRadius = 5.0f;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(80, 30 , 60, 15)];
    label.textAlignment = NSTextAlignmentCenter;
    label.tag = TYPE_TAG;
    label.font = [UIFont boldSystemFontOfSize:10];
    label.textColor = [UIColor whiteColor];
    [label.layer setCornerRadius:3];
    label.numberOfLines = 0;

    [cell.contentView addSubview:label];

    
    return  cell;
}



- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    Information *info = [self.dataArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = info.value;
    cell.detailTextLabel.text = [info.createdOn timesince];
    
    UILabel *label = (UILabel *)[cell viewWithTag:TYPE_TAG];
    
    if (info.type == WinnerCodeFromShake) {
        label.backgroundColor = RGBCOLOR(25, 164, 221);
        label.text = T(@"CODE");
    }
    if (info.type == LastMessageFromServer) {
        label.backgroundColor = RGBCOLOR(25, 164, 221);
        label.text = T(@"MESSAGE");
    }
    
}



#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    Information *info = [self.dataArray objectAtIndex:indexPath.row];
//    // 点击复制到系统本
//    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//    [pasteboard setString:info.value];
//    
//    [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"成功复制到剪贴板") andHideAfterDelay:1];
//}


#pragma mark - Table edit and delete

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the managed object at the given index path.
        NSManagedObject *dataToDelete = [self.dataArray objectAtIndex:indexPath.row];
        [managedObjectContext deleteObject:dataToDelete];
        
        // Update the array and table view.
        NSMutableArray *tmpArray = [[NSMutableArray alloc]initWithArray:self.dataArray];
        [tmpArray removeObjectAtIndex:indexPath.row];
        self.dataArray = [[NSArray alloc]initWithArray:tmpArray];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
        // Commit the change.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
        }
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDLogVerbose(@"you slided");
    //    self.editingIndexPath = indexPath;
    return UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  T(@"Delete");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
