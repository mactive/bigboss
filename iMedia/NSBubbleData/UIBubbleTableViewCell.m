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
#import "XMPPFramework.h"
#import "UIImageView+AFNetworking.h"

@interface UIBubbleTableViewCell ()<UIWebViewDelegate>

@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic, strong) UIImageView *avatarImage;
@property (nonatomic, strong) UIView *templateBackView;
@property (nonatomic, strong) UIImageView *templateImage;
@property (nonatomic, strong) UILabel *templateContent;
@property (nonatomic, strong) UIImageView *rateView;
@property (nonatomic, readwrite) CGSize viewSize;

- (void) setupInternalData;

@end

@implementation UIBubbleTableViewCell

@synthesize data = _data;
@synthesize customView = _customView;
@synthesize bubbleImage = _bubbleImage;
@synthesize showAvatar = _showAvatar;
@synthesize avatarImage;
@synthesize templateImage;
@synthesize templateContent;
@synthesize templateBackView;
@synthesize rateView;
@synthesize viewSize;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setupInternalData];
    
}

- (id)init
{
    id obj = [super init];    
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
    else if (type == BubbleTypeTemplateview){
        
        NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:self.data.content error:nil];
        NSString* imageString = [[element elementForName:@"image9"] stringValue];
        NSString* contentString = [[element elementForName:@"content9"] stringValue];
        
        self.templateBackView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, height +20)];
        self.templateContent = [[UILabel alloc] initWithFrame:CGRectMake(12.5, 160, 275, height)];
        self.templateImage = [[UIImageView alloc]initWithFrame:CGRectMake(12.5, 12.5, 275, TEMPLATE_IMAGE_HEIGHT)];
        self.templateImage.contentMode = UIViewContentModeScaleAspectFit;

        if (imageString == nil || [imageString length] == 0) {
            [self.templateContent setFrame:CGRectMake(12.5, 10, 275, height )];
            
        }else{
            [self.templateContent setFrame:CGRectMake(12.5, 160, 275, height - TEMPLATE_IMAGE_HEIGHT)];
        }
        
//        imageString = @"http://img.hb.aicdn.com/b524a99d6cd18479f2316613e5babe016e6d3112ce7dc-qkksEP_fw554";
        [self.templateImage setImageWithURL:[NSURL URLWithString:imageString] placeholderImage:nil];
        
        self.templateContent.font = [UIFont systemFontOfSize:14];
        self.templateContent.text = contentString;
        self.templateContent.numberOfLines = 0;
        self.templateContent.textColor = RGBCOLOR(33, 33, 33);
        self.templateContent.backgroundColor = [UIColor clearColor];
        
        
        [self.templateBackView setBackgroundColor:[UIColor whiteColor]];
        [self.templateBackView.layer setMasksToBounds:YES];
        [self.templateBackView.layer setCornerRadius:10.0];
        
        /*[[data.content elementForName:@"title9"] stringValue]
         MYUIVIew = kkk
         myui.content = NSString* summary = [[data.content elementForName:@"title9"] stringValue];
         myui.imageView NSString* summary = [[entry elementForName:@"image9"] stringValue];

        */
        
        [self.customView removeFromSuperview];
        [self.avatarImage removeFromSuperview];
        [self.bubbleImage removeFromSuperview];
        
        [self.templateBackView addSubview:self.templateImage];
        [self.templateBackView addSubview:self.templateContent];
        [self.contentView addSubview:self.templateBackView];

        

        
    }else if(type == BubbleTypeRateview){
        
        self.rateView = [[UIImageView alloc]initWithFrame:CGRectMake(80, 10, 160, 41)];
        [self.rateView setImage:[UIImage imageNamed:@"welcome_btn.png"]];
        UILabel *rateLabel = [[UILabel alloc]initWithFrame:rateView.bounds];
        
        [rateLabel setText:T(@"评价客服")];
        [rateLabel setTextAlignment:NSTextAlignmentCenter];
        [rateLabel setTextColor:[UIColor whiteColor]];
        [rateLabel setBackgroundColor:[UIColor clearColor]];
        [self.rateView addSubview:rateLabel];
        [self.contentView addSubview:self.rateView];
        
        [self.customView removeFromSuperview];
        [self.avatarImage removeFromSuperview];
        [self.bubbleImage removeFromSuperview];
    }
    self.bubbleImage.frame = CGRectMake(x, y, width + self.data.insets.left + self.data.insets.right, height + self.data.insets.top + self.data.insets.bottom);
}


#pragma mark - UIWebView delegate
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    if ([self.webView isEqual:webView]) {
//        
//        CGSize actualSize = [self.webView sizeThatFits:CGSizeZero];
//        CGRect newFrame = self.webView.frame;
//        newFrame.size.height = actualSize.height;
//        self.webView.frame = newFrame;
//        self.webViewOverlayButton.frame = newFrame;
//        
//        CGRect backFrame = self.backWebView.frame;
//        backFrame.size.height = actualSize.height+25;
//        self.backWebView.frame = backFrame;
//        NSLog(@"%@", NSStringFromCGRect(self.backWebView.frame));
//        
////        self.data.view.frame = backFrame;
//        self.data.isDone = YES;
//        self.data.cellHeight = backFrame.size.height;
//    }
//}



@end
