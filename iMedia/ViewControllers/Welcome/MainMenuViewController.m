//
//  MainMenuViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-24.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "MainMenuViewController.h"
#import "MetroButton.h"


@interface MainMenuViewController ()
@property(nonatomic, strong)NSArray *menuTitleArray;
@property(strong, nonatomic)UIView *menuView;

@end

@implementation MainMenuViewController
@synthesize menuTitleArray;
@synthesize menuView;
@synthesize conversationController;
@synthesize contactListViewController;
@synthesize functionListViewController;
@synthesize settingViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#define VIEW_OFFSET 5
#define VIEW_WIDTH 310
#define HALF_WIDTH (VIEW_WIDTH-VIEW_OFFSET)/2
#define LITE_HEIGHT 45

- (CGRect)calcRect:(NSInteger)index
{
    CGRect rect = CGRectZero;
    switch (index) {
        case 0:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET, VIEW_WIDTH , LITE_HEIGHT);
            break;
        case 1:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET*2+LITE_HEIGHT, HALF_WIDTH, HALF_WIDTH);
            break;
        case 2:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET*2+LITE_HEIGHT, HALF_WIDTH, HALF_WIDTH);
            break;
        case 3:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET*3+LITE_HEIGHT+HALF_WIDTH, HALF_WIDTH, HALF_WIDTH+LITE_HEIGHT);
            break;
        case 4:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET*3+LITE_HEIGHT+HALF_WIDTH, HALF_WIDTH, (HALF_WIDTH-15));
            break;
        case 5:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET+LITE_HEIGHT+HALF_WIDTH*2, HALF_WIDTH, LITE_HEIGHT+10);
            break;
        default:
            rect = CGRectZero;
            break;
    }
    
    return rect;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = T(@"大掌柜");
    self.menuTitleArray = [[NSArray alloc] initWithObjects:@"搜索公司",@"消息",@"联系人",@"福利",@"设置",@"公司列表", nil];
    self.view.backgroundColor = BGCOLOR;
    [self.view addSubview:self.menuView];
    
    for (int index = 0; index <[self.menuTitleArray count]; index++) {
        MetroButton *button = [[MetroButton alloc]initWithFrame:[self calcRect:index]];
        NSString *title = [self.menuTitleArray objectAtIndex:index];
        NSString *image = [NSString stringWithFormat:@"main_menu_icon_%d.png",index];
        [button initMetroButton:[UIImage imageNamed:image] andText:title andIndex:index];
        
        //        if (index == 0) {
        //            [button addTarget:self action:@selector(sayhiAction) forControlEvents:UIControlEventTouchUpInside];
        //        }
        if (index == 0) {
            [button addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 1) {
            [button addTarget:self action:@selector(conversationAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 2) {
            [button addTarget:self action:@selector(contactAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 3) {
            [button addTarget:self action:@selector(functionAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 4) {
            [button addTarget:self action:@selector(settingAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 5) {
            [button addTarget:self action:@selector(companyAction) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:button];
    }
}
//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark actions
//////////////////////////////////////////////////////////////////////////////////////////
- (void)conversationAction
{
    self.conversationController = [[ConversationsController alloc] initWithStyle:UITableViewStylePlain];
    self.conversationController.managedObjectContext = self.managedObjectContext;

    [self.navigationController pushViewController:self.conversationController animated:NO];
}

- (void)contactAction
{
    self.contactListViewController = [[ContactListViewController alloc] initWithNibName:nil bundle:nil];
    self.contactListViewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:self.contactListViewController animated:NO];
}

- (void)functionAction
{
    self.functionListViewController = [[FunctionListViewController alloc]initWithNibName:nil bundle:nil];
    self.functionListViewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:self.functionListViewController animated:NO];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
