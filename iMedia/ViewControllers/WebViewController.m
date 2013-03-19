//
//  WebViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-9.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WebViewController.h"
#import "ConvenienceMethods.h"
#import "MBProgressHUD.h"

@interface WebViewController ()<UIWebViewDelegate>

@property(strong, nonatomic)UIWebView *webView;
@property(strong, nonatomic)MBProgressHUD *HUD;
@property(readwrite, nonatomic)BOOL firstLoad;
@end

@implementation WebViewController

@synthesize urlString;
@synthesize webView;
@synthesize titleString;
@synthesize webType;
@synthesize HUD;
@synthesize firstLoad;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.titleString;
    
    self.webView  = [[UIWebView alloc]initWithFrame:self.view.bounds];
    self.webView.delegate = self;

    [self.view addSubview:self.webView];
	// Do any additional setup after loading the view.

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.firstLoad = YES;
    
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
    
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.removeFromSuperViewOnHide = YES;
    self.HUD.labelText = T(@"正在加载");
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [XFox endTimedEvent:EVENT_ARTICLE_TIMER withParameters:nil];
}

////////////////////////////////////////////////////

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([self.webView isEqual:webView] && self.firstLoad ) {
        [self.HUD hide:YES];
        [XFox logEvent:EVENT_ARTICLE_TIMER withParameters:[NSDictionary dictionaryWithObjectsAndKeys:self.titleString, @"title", self.urlString,@"url", nil] timed:YES];
        self.firstLoad = NO;
    }


}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
