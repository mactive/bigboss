//
//  UserAgreementViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-22.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "UserAgreementViewController.h"

@interface UserAgreementViewController ()
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic)UILabel *contentLabel;
@property(strong, nonatomic)UIScrollView *scrollView;

@end

@implementation UserAgreementViewController
@synthesize titleLabel;
@synthesize contentLabel;
@synthesize scrollView;

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
    
    self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 20, 280 , 30)];
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.titleLabel setTextColor:BIGBOSS_BLUE];
    self.titleLabel.text = T(@"大掌柜用户协议(草案)");
    self.titleLabel.shadowColor = [UIColor whiteColor];
    self.titleLabel.shadowOffset = CGSizeMake(0, 1);
    
    NSString *text = @"我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。我们系统的把文章分成不同的难度级别。如果你发现你在阅读的级别对你来说太难或者太简单，你可以相应的选择另一个级别进行阅读。小贴士：难度稍微高出你能力的文章最适合作为训练材料。";
    
    UIFont *font = [UIFont systemFontOfSize:12.0];
    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(280, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    self.contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 60, size.width, size.height)];
    self.contentLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.contentLabel.text = (text ? text : @"");
    self.contentLabel.font = font;
    self.contentLabel.backgroundColor = [UIColor clearColor];
    [self.contentLabel setTextColor:[UIColor grayColor]];
    self.contentLabel.numberOfLines = 0;
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, 320, 400)];
    [self.scrollView setContentSize:CGSizeMake(320, size.height + 100)];
    
    
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.titleLabel];
    [self.scrollView addSubview:self.contentLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
