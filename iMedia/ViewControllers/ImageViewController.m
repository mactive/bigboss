//
//  ImageViewController.m
//  iMedia
//
//  Created by meng qian on 13-3-6.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "ImageViewController.h"
#import "UIImageView+AFNetworking.h"
@interface ImageViewController ()
@property(strong, nonatomic)UIImageView *imageContainer;
@end

@implementation ImageViewController

@synthesize urlString;
@synthesize imageContainer;
@synthesize titleString;

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
    self.title = StringHasValue(self.titleString) ? self.titleString:T(@"查看图片") ;
    self.imageContainer = [[UIImageView alloc]initWithFrame:self.view.bounds];
    self.imageContainer.contentMode = UIViewContentModeScaleAspectFit;
    [self.imageContainer setUserInteractionEnabled:YES];
    [self.imageContainer setMultipleTouchEnabled:YES];
    
    [self.view addSubview:self.imageContainer];
	// Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.imageContainer setImageWithURL:[NSURL URLWithString:self.urlString] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
