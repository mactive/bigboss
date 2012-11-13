//
//  WSBubbleTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-13.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleTableViewCell.h"
#import "WSBubbleData.h"
#import "XMPPFramework.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>

@interface WSBubbleTableViewCell ()

@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic, strong) UIImageView *avatarImage;
@property (nonatomic, strong) UIView *templateBackView;
@property (nonatomic, strong) UILabel *templateTitle;
@property (nonatomic, strong) UIImageView *templateImage;
@property (nonatomic, strong) UILabel *templateContent;
@property (nonatomic, strong) UIImageView *rateView;
@property (nonatomic, readwrite) CGSize viewSize;

- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleTableViewCell

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
@synthesize templateTitle;


- (void)setData:(WSBubbleData *)data
{
    [self setupInternalData:data];
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        
        self.templateBackView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 0)];
        self.templateContent = [[UILabel alloc] initWithFrame:CGRectMake(12, 180, 275, 0)];
        self.templateTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 275, 30)];
        self.templateImage = [[UIImageView alloc]initWithFrame:CGRectMake(12, 40, 275, TEMPLATE_IMAGE_HEIGHT)];
        
        self.templateTitle.backgroundColor = [UIColor clearColor];
        self.templateTitle.font = [UIFont boldSystemFontOfSize:18];
        self.templateTitle.textColor = RGBCOLOR(68, 68, 68);
        self.templateTitle.textAlignment = NSTextAlignmentLeft;
        
        self.templateContent.font = [UIFont systemFontOfSize:14];
        self.templateContent.numberOfLines = 0;
        self.templateContent.textColor = RGBCOLOR(100, 100, 100);
        self.templateContent.backgroundColor = [UIColor clearColor];
        [self.templateBackView setBackgroundColor:[UIColor whiteColor]];
        [self.templateBackView.layer setMasksToBounds:YES];
        [self.templateBackView.layer setCornerRadius:10.0];
        [self.templateBackView.layer setBorderColor:[RGBCOLOR(194, 194, 194) CGColor]];
        [self.templateBackView.layer setBorderWidth:1.0];
        
        self.customView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 220, 50)];
        
    }
    return self;
}



- (void) setupInternalData:(WSBubbleData *)cellData
{
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    WSBubbleType type = cellData.type;
    
    if (!self.bubbleImage)
    {
        self.bubbleImage = [[UIImageView alloc] init];
        [self.contentView addSubview:self.bubbleImage];
    }
    
    
    CGFloat width = cellData.view.frame.size.width;
    CGFloat height = cellData.view.frame.size.height;
    
    CGFloat x = (type == BubbleTypeSomeoneElse) ? 0 : self.frame.size.width - width - cellData.insets.left - cellData.insets.right;
    CGFloat y = 5;
    
    // Adjusting the x coordinate for avatar
    if (cellData.showAvatar)
    {
        [self.avatarImage removeFromSuperview];
        self.avatarImage = [[UIImageView alloc] initWithImage:
                            (cellData.avatar ? cellData.avatar : [UIImage imageNamed:@"user_avatar_placeholder.png"])];
        self.avatarImage.layer.cornerRadius = 9.0;
        self.avatarImage.layer.masksToBounds = YES;
        self.avatarImage.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.avatarImage.layer.borderWidth = 1.0;
        
        CGFloat avatarX = (type == BubbleTypeSomeoneElse) ? 2 : self.frame.size.width - 52;
        CGFloat avatarY = 0 ;// self.frame.size.height - 50;
        
        self.avatarImage.frame = CGRectMake(avatarX, avatarY, 50, 50);
        [self addSubview:self.avatarImage];
        
        //        CGFloat delta = self.frame.size.height - (cellData.insets.top + cellData.insets.bottom + cellData.view.frame.size.height);
        //        if (delta > 0) y = delta;
        
        if (type == BubbleTypeSomeoneElse) x += 54;
        if (type == BubbleTypeMine) x -= 54;
    }
    
    [self.customView removeFromSuperview];
    self.customView = cellData.view;
    self.customView.frame = CGRectMake(x + cellData.insets.left, y + cellData.insets.top, width, height);
    
    [self.contentView addSubview:self.customView];
    
    if (type == BubbleTypeSomeoneElse)
    {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
    }
    else if(type == BubbleTypeMine) {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
    }
    else if (type == BubbleTypeTemplateview){
        
        NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:cellData.content error:nil];
        
        [self.templateBackView setFrame:CGRectMake(10, 0, 300, height +TEMPLATE_TITLE_HEIGHT)];
        [self.templateContent setFrame:CGRectMake(12, 180, 275, height)];
        [self.templateImage setFrame:CGRectMake(12, 40, 275, TEMPLATE_IMAGE_HEIGHT)];
        
        
        NSString* imageString = [[element elementForName:@"image9"] stringValue];
        NSString* contentString = [[element elementForName:@"content9"] stringValue];
        NSString* titleString = [[element elementForName:@"title9"] stringValue];
        
        self.templateImage.contentMode = UIViewContentModeScaleAspectFit;
        
        if (imageString == nil || [imageString length] == 0) {
            [self.templateContent setFrame:CGRectMake(12, 40, 275, height )];
        }else{
            [self.templateContent setFrame:CGRectMake(12, 180, 275, height - TEMPLATE_IMAGE_HEIGHT)];
        }
        
        
        self.templateContent.text = contentString;
        [self.templateImage setImageWithURL:[NSURL URLWithString:imageString] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];
        self.templateTitle.text = titleString;
        
        [self.templateBackView addSubview:self.templateImage];
        [self.templateBackView addSubview:self.templateContent];
        [self.templateBackView addSubview:self.templateTitle];
        [self.contentView addSubview:self.templateBackView];
        
        
        [self.customView removeFromSuperview];
        [self.avatarImage removeFromSuperview];
        [self.bubbleImage removeFromSuperview];
        
        
    }
    else if(type == BubbleTypeRateview){
        
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
    self.bubbleImage.frame = CGRectMake(x, y, width + cellData.insets.left + cellData.insets.right, height + cellData.insets.top + cellData.insets.bottom);
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
