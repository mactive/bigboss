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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#define VIEW_ALBUM_OFFSET 5
#define VIEW_ALBUM_WIDTH 310
#define VIEW_ALBUM_HEIGHT 150
#define COUNT_PER_LINE 2
#define Y_OFFEST 5

- (CGRect)calcRect:(NSInteger)index
{
    CGFloat x = VIEW_ALBUM_OFFSET * (index % COUNT_PER_LINE * 1 + 1) + VIEW_ALBUM_WIDTH * (index % COUNT_PER_LINE) ;
    CGFloat y = VIEW_ALBUM_OFFSET * (floor(index / COUNT_PER_LINE) * 1 + 1) + VIEW_ALBUM_HEIGHT * floor(index / COUNT_PER_LINE);
    return  CGRectMake( x, y+Y_OFFEST, VIEW_ALBUM_WIDTH, VIEW_ALBUM_HEIGHT);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = T(@"");
    self.menuTitleArray = [[NSArray alloc] initWithObjects:@"搜索公司",@"消息",@"联系人",@"福利",@"设置",@"公司列表", nil];
    self.view.backgroundColor = BGCOLOR;
    [self.view addSubview:self.menuView];
    
    for (int index = 0; index <[self.menuTitleArray count]; index++) {
        MetroButton *button = [[MetroButton alloc]initWithFrame:[self calcRect:index]];
        NSString *title = [self.menuTitleArray objectAtIndex:index];
        NSString *image = [NSString stringWithFormat:@"main_menu_icon_%d.png",(index+3)];
        [button initMetroButton:[UIImage imageNamed:image] andText:title andIndex:index];
        
        //        if (index == 0) {
        //            [button addTarget:self action:@selector(sayhiAction) forControlEvents:UIControlEventTouchUpInside];
        //        }
        if (index == 0) {
            [button addTarget:self action:@selector(shakeAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 1) {
            [button addTarget:self action:@selector(channelListAction) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:button];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
