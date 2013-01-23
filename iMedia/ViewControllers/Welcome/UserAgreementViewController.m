//
//  UserAgreementViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-22.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "UserAgreementViewController.h"

@interface UserAgreementViewController ()
@property(strong, nonatomic)UIWebView *webView;

@end

@implementation UserAgreementViewController
@synthesize webView;


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
	// Do any additional setup after loading the view.
    self.title = T(@"用户协议");
    
    self.webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
