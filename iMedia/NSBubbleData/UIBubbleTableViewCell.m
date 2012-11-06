//
//  UIBubbleTableViewCell.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <QuartzCore/QuartzCore.h>
#import "UIBubbleTableViewCell.h"
#import "NSBubbleData.h"

@interface UIBubbleTableViewCell ()<UIWebViewDelegate>

@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic, strong) UIImageView *avatarImage;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *backWebView;
@property (nonatomic, strong) UIButton *webViewOverlayButton;
@property (nonatomic, strong) UIButton *rateButton;

- (void) setupInternalData;

@end

@implementation UIBubbleTableViewCell

@synthesize data = _data;
@synthesize customView = _customView;
@synthesize bubbleImage = _bubbleImage;
@synthesize showAvatar = _showAvatar;
@synthesize avatarImage;
@synthesize webView =_webView;
@synthesize webViewOverlayButton;
@synthesize backWebView;
@synthesize rateButton;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setupInternalData];
    
}

- (id)init
{
    id obj = [super init];
    
    self.webViewOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rateButton setFrame:CGRectMake(80, 0, 160, 41)];
    self.backWebView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300,1)];
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(12.5, 12.5, 275, 1)];
    
    return obj;
}

#if !__has_feature(objc_arc)
- (void) dealloc
{
    self.data = nil;
    self.customView = nil;
    self.bubbleImage = nil;
    [super dealloc];
}
#endif

//- (void)setDataInternal:(NSBubbleData *)value
//{
//	self.data = value;
//	[self setupInternalData];
//}

- (void) setupInternalData
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSBubbleType type = self.data.type;

    if (!self.bubbleImage)
    {
        self.bubbleImage = [[UIImageView alloc] init];
        [self addSubview:self.bubbleImage];
    }
    
    
    CGFloat width = self.data.view.frame.size.width;
    CGFloat height = self.data.view.frame.size.height;

    CGFloat x = (type == BubbleTypeSomeoneElse) ? 0 : self.frame.size.width - width - self.data.insets.left - self.data.insets.right;
    CGFloat y = 5;
    
    // Adjusting the x coordinate for avatar
    if (self.data.showAvatar)
    {
        [self.avatarImage removeFromSuperview];
        self.avatarImage = [[UIImageView alloc] initWithImage:(self.data.avatar ? self.data.avatar : [UIImage imageNamed:@"missingAvatar.png"])];
        self.avatarImage.layer.cornerRadius = 9.0;
        self.avatarImage.layer.masksToBounds = YES;
        self.avatarImage.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.avatarImage.layer.borderWidth = 1.0;
        
        CGFloat avatarX = (type == BubbleTypeSomeoneElse) ? 2 : self.frame.size.width - 52;
        CGFloat avatarY = 0 ;// self.frame.size.height - 50;
        
        self.avatarImage.frame = CGRectMake(avatarX, avatarY, 50, 50);
        [self addSubview:self.avatarImage];
        
//        CGFloat delta = self.frame.size.height - (self.data.insets.top + self.data.insets.bottom + self.data.view.frame.size.height);
//        if (delta > 0) y = delta;
        
        if (type == BubbleTypeSomeoneElse) x += 54;
        if (type == BubbleTypeMine) x -= 54;
    }

    [self.customView removeFromSuperview];
    self.customView = self.data.view;
    self.customView.frame = CGRectMake(x + self.data.insets.left, y + self.data.insets.top, width, height);
    
    [self.contentView addSubview:self.customView];

    if (type == BubbleTypeSomeoneElse)
    {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];

    }
    else if(type == BubbleTypeMine) {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
    }
    else if (type == BubbleTypeWebview){
        
        [self.backWebView setBackgroundColor:[UIColor whiteColor]];
        [self.backWebView.layer setMasksToBounds:YES];
        [self.backWebView.layer setCornerRadius:10.0];
        
        [self.webViewOverlayButton setFrame:self.webView.bounds];
        [self.webViewOverlayButton setAlpha:0.3];
        [self.webViewOverlayButton setBackgroundColor:[UIColor whiteColor]];
        
        if (self.data.isDone == NO) {
            NSURL *url=[NSURL URLWithString:self.data.content];
            NSURLRequest *resquestobj=[NSURLRequest requestWithURL:url];
            [self.webView loadRequest:resquestobj];
            NSLog(@"%@",resquestobj);
            self.webView.scalesPageToFit = YES;
            //        self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            self.webView.delegate = self;
            [self.webView setBackgroundColor:[UIColor clearColor]];
            
            [self.backWebView addSubview:self.webView];
            [self.backWebView addSubview:self.webViewOverlayButton];
            [self.contentView addSubview:self.backWebView];
        }
        [self.customView removeFromSuperview];
        [self.avatarImage removeFromSuperview];
        [self.bubbleImage removeFromSuperview];
        
    }else if(type == BubbleTypeRateview){
        [self.rateButton setImage:[UIImage imageNamed:@"welcome_btn.png"] forState:UIControlStateNormal];
        [self.rateButton setTitle:T(@"评价客服") forState:UIControlStateNormal];
        [self.rateButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.rateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.rateButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [self.contentView addSubview:self.rateButton];
        
        [self.customView removeFromSuperview];
        [self.avatarImage removeFromSuperview];
        [self.bubbleImage removeFromSuperview];
    }
    self.bubbleImage.frame = CGRectMake(x, y, width + self.data.insets.left + self.data.insets.right, height + self.data.insets.top + self.data.insets.bottom);
}


#pragma mark - UIWebView delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([self.webView isEqual:webView]) {
        
        CGSize actualSize = [self.webView sizeThatFits:CGSizeZero];
        CGRect newFrame = self.webView.frame;
        newFrame.size.height = actualSize.height;
        self.webView.frame = newFrame;
        self.webViewOverlayButton.frame = newFrame;
        
        CGRect backFrame = self.backWebView.frame;
        backFrame.size.height = actualSize.height+25;
        self.backWebView.frame = backFrame;
        NSLog(@"%@", NSStringFromCGRect(self.backWebView.frame));
        
//        self.data.view.frame = backFrame;
        self.data.isDone = YES;
        self.data.cellHeight = backFrame.size.height;
    }
}



@end
