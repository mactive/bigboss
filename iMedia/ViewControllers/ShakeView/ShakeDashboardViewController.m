//
//  ShakeDashboardViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-22.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "ShakeDashboardViewController.h"
#import "AppNetworkAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import "TrapezoidLabel.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"
#import "ShakeViewController.h"
#import "CheckinNoteViewController.h"

@interface ShakeDashboardViewController ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}

@property(nonatomic, strong) TrapezoidLabel *inprogressLabel;
@property(nonatomic, strong) TrapezoidLabel *waitingLabel;
@property(nonatomic, strong) UIView *checkinView;
@property(nonatomic, strong) UILabel *checkinLabel;
@property(nonatomic, strong) UIButton *checkinButton;
@property(nonatomic, strong) NSMutableArray *urlArray;


@property(nonatomic, strong)UIButton *inprogressButton;

@end

@implementation ShakeDashboardViewController

@synthesize inprogressLabel;
@synthesize waitingLabel;
@synthesize inprogressButton;
@synthesize checkinLabel;
@synthesize checkinView;
@synthesize checkinButton;
@synthesize urlArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = T(@"摇一摇");
    }
    return self;
}

#define LARGE_BUTTON_WIDTH 320
#define LARGE_BUTTON_HEIGHT 160

#define BUTTON_WIDTH 160
#define BUTTON_HEIGHT 80
#define FIRST_TAG 0
#define BUTTON_OFFEST 1

#define VIEW_ALBUM_OFFSET 1
#define VIEW_ALBUM_WIDTH 160
#define VIEW_ALBUM_HEIGHT 80
#define COUNT_PER_LINE 2
#define Y_OFFEST 203
#define X_OFFEST -0.5

- (CGRect)calcRect:(NSInteger)index
{
    CGFloat x = VIEW_ALBUM_OFFSET * (index % COUNT_PER_LINE * 1 ) + VIEW_ALBUM_WIDTH * (index % COUNT_PER_LINE) ;
    CGFloat y = VIEW_ALBUM_OFFSET * (floor(index / COUNT_PER_LINE) * 1 + 1) + VIEW_ALBUM_HEIGHT * floor(index / COUNT_PER_LINE);
    return  CGRectMake( x + X_OFFEST, y+Y_OFFEST, VIEW_ALBUM_WIDTH, VIEW_ALBUM_HEIGHT);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // green title 
    self.inprogressLabel = [[TrapezoidLabel alloc] initWithFrame:CGRectMake(0, 0, 87, 15)];
    self.inprogressLabel.text = T(@"正在进行的活动");
    self.inprogressLabel.textColor = [UIColor blackColor];
    self.inprogressLabel.backgroundColor = [ UIColor clearColor];
    self.inprogressLabel.bgColor = RGBCOLOR(123, 248, 68);
    
    //blur title
    self.waitingLabel = [[TrapezoidLabel alloc] initWithFrame:CGRectMake(0, 0, 87, 15)];
    self.waitingLabel.text = T(@"即将开始的活动");
    self.waitingLabel.textColor = [UIColor whiteColor];
    self.waitingLabel.backgroundColor = [UIColor clearColor];
    self.waitingLabel.bgColor = RGBCOLOR(60, 91, 148);
    
    // 顶部大button
    self.inprogressButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.inprogressButton.frame = CGRectMake(0, 0, LARGE_BUTTON_WIDTH, LARGE_BUTTON_HEIGHT);
    self.inprogressButton.tag = FIRST_TAG;
    
    // checkinView
    self.checkinView = [[UIView alloc]initWithFrame:CGRectMake(0, LARGE_BUTTON_HEIGHT, 320, 44)];
    self.checkinView.backgroundColor = RGBCOLOR(237, 223, 214);
    // checklabel
    self.checkinLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 12, 200, 20)];
    self.checkinLabel.text = T(@"连续摇7天可以获得精美礼品");
    self.checkinLabel.font = [UIFont systemFontOfSize:12];
    self.checkinLabel.textAlignment = NSTextAlignmentLeft;
    self.checkinLabel.textColor = RGBCOLOR(195, 70, 21);
    self.checkinLabel.backgroundColor = [UIColor clearColor];
    [self.checkinView addSubview:self.checkinLabel];
    // checkButton
    self.checkinButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.checkinButton setTitle:T(@"了解更多") forState:UIControlStateNormal];
    [self.checkinButton setTitleColor:RGBCOLOR(215, 122, 84) forState:UIControlStateNormal];
    [self.checkinButton setFont:[UIFont systemFontOfSize:12]];
    self.checkinButton.backgroundColor = RGBCOLOR(232, 216, 206);
    self.checkinButton.layer.cornerRadius = 5.0f;
    self.checkinButton.frame = CGRectMake(230, 6, 70, 30);
    [self.checkinButton addTarget:self action:@selector(checkinAction) forControlEvents:UIControlEventTouchUpInside];
    [self.checkinView addSubview:self.checkinButton];
    
    self.urlArray = [[NSMutableArray alloc]init];
    
    [self.view addSubview:self.checkinView];
    [self.view addSubview:self.inprogressButton];
    
    // did load populate
    [self populateData];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}
//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - click actions
//////////////////////////////////////////////////////////////////////////////////////////
- (void)checkinAction
{
    CheckinNoteViewController *controller = [[CheckinNoteViewController alloc]initWithNibName:nil bundle:nil];
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)buttonAction:(UIButton *)sender
{
    ShakeViewController *controller = [[ShakeViewController alloc]initWithNibName:nil bundle:nil];
    controller.shakeData = [self.urlArray objectAtIndex:sender.tag];
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)populateData
{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = T(@"正在加载信息");
    
    [[AppNetworkAPIClient sharedClient]getShakeDashboardInfoWithBlock:^(id responseObject, NSError *error) {
        if (responseObject != nil) {
            [HUD hide:YES];
            NSDictionary *responseDict = responseObject;
            NSDictionary *inprogressDict = [responseDict objectForKey:@"inprogress"];
            NSDictionary *waitingDict = [responseDict objectForKey:@"waiting"];
 
            if (inprogressDict) {
                UIImageView *buttonImageView = [[UIImageView alloc]initWithFrame:self.inprogressButton.bounds];
                NSURL *url = [[NSURL alloc]initWithString:[inprogressDict objectForKey:@"thumbnail"]];
                [buttonImageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"shake_test_image.png"]];
                [self.inprogressButton addSubview:buttonImageView];
                [self.inprogressButton addSubview:self.inprogressLabel];
                
                [self.urlArray insertObject:inprogressDict atIndex:self.inprogressButton.tag];
                
                [self.inprogressButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];

            }
            
            if (waitingDict) {
                for (int j = 0; j < [waitingDict count]; j++) {
                    NSDictionary *waitingItem = [waitingDict objectForKey:[NSString stringWithFormat:@"%i",j]];
                    
                    UIButton *waitingButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    waitingButton.frame = [self calcRect:j];
                    
                    UIImageView *imageView = [[UIImageView alloc]initWithFrame:waitingButton.bounds];
                    NSURL *url = [[NSURL alloc]initWithString:[waitingItem objectForKey:@"thumbnail"]];
                    [imageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"shake_test_thumbnail.png"]];
                    waitingButton.tag = FIRST_TAG+j+1;
                    
                    [self.urlArray insertObject:waitingItem atIndex:waitingButton.tag];
                    
                    [waitingButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];

                    [waitingButton addSubview:imageView];
                    if (j == 0) {
                        [waitingButton addSubview:self.waitingLabel];
                    }
                    [self.view addSubview:waitingButton];
                }
            }
     
        }else{
            [HUD hide:YES];
            
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.mode = MBProgressHUDModeText;
            HUD.delegate = self;
            HUD.labelText = T(@"网络错误,无法获取信息");
            [HUD hide:YES afterDelay:1];
        }
        
        
    }];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
