//
//  WSBubbleTemplateBTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-14.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleTemplateBTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "XMPPFramework.h"
#import "UIImageView+AFNetworking.h"
#import "WSBubbleData.h"


@interface WSBubbleTemplateBTableViewCell ()

@property (nonatomic, strong) UIView *templateBackView;
@property (nonatomic, strong) UILabel *templateTitle1;
@property (nonatomic, strong) UILabel *templateTitle2;
@property (nonatomic, strong) UILabel *templateTitle3;
@property (nonatomic, strong) UILabel *templateTitle4;
@property (nonatomic, strong) UIImageView *templateImage1;
@property (nonatomic, strong) UIImageView *templateImage2;
@property (nonatomic, strong) UIImageView *templateImage3;
@property (nonatomic, strong) UIImageView *templateImage4;
@property (nonatomic, strong) UIView *separaterView2;
@property (nonatomic, strong) UIView *separaterView3;
@property (nonatomic, strong) UIView *separaterView4;

- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleTemplateBTableViewCell
@synthesize templateBackView = _templateBackView;
@synthesize templateTitle1;
@synthesize templateImage1;
@synthesize templateTitle2;
@synthesize templateImage2;
@synthesize templateTitle3;
@synthesize templateImage3;
@synthesize templateTitle4;
@synthesize templateImage4;
@synthesize separaterView2;
@synthesize separaterView3;
@synthesize separaterView4;

@synthesize data = _data;

#define WIDTH_S 200

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // title 1 and image 1
        
        self.separaterView2 = [[UIView alloc]initWithFrame:CGRectMake(0, 10, 295, 1)];
        self.separaterView2.backgroundColor = RGBCOLOR(240, 240, 240);
        self.separaterView3 = [[UIView alloc]initWithFrame:CGRectMake(0, 10, 295, 1)];
        self.separaterView3.backgroundColor = RGBCOLOR(240, 240, 240);
        self.separaterView4 = [[UIView alloc]initWithFrame:CGRectMake(0, 10, 295, 1)];
        self.separaterView4.backgroundColor = RGBCOLOR(240, 240, 240);

        self.templateImage1 = [[UIImageView alloc]initWithFrame:CGRectMake(12, 10, 275, TEMPLATE_IMAGE_HEIGHT)];
        self.templateImage2 = [[UIImageView alloc]initWithFrame:CGRectMake(225, 10, TEMPLATE_CELL_IHEIGHT, TEMPLATE_CELL_IHEIGHT)];
        self.templateImage3 = [[UIImageView alloc]initWithFrame:CGRectMake(225, 10, TEMPLATE_CELL_IHEIGHT, TEMPLATE_CELL_IHEIGHT)];
        self.templateImage4 = [[UIImageView alloc]initWithFrame:CGRectMake(225, 10, TEMPLATE_CELL_IHEIGHT, TEMPLATE_CELL_IHEIGHT)];
        
        self.templateTitle1 = [[UILabel alloc] initWithFrame:CGRectMake(12, TEMPLATE_IMAGE_HEIGHT-30, 275, 30)];
        self.templateTitle1.numberOfLines = 0;
        self.templateTitle1.backgroundColor = RGBACOLOR(0, 0, 0, 0.5);
        self.templateTitle1.font = [UIFont boldSystemFontOfSize:16];
        self.templateTitle1.textColor = RGBCOLOR(255, 255, 255);
        self.templateTitle1.textAlignment = NSTextAlignmentLeft;
        
        self.templateTitle2 = [[UILabel alloc] initWithFrame:CGRectMake(16, TEMPLATE_IMAGE_HEIGHT, WIDTH_S, 30)];
        self.templateTitle2.numberOfLines = 0;
        self.templateTitle2.backgroundColor = [UIColor clearColor];
        self.templateTitle2.font = [UIFont systemFontOfSize:14];
        self.templateTitle2.textColor = RGBCOLOR(68, 68, 68);
        self.templateTitle2.textAlignment = NSTextAlignmentLeft;
        
        
        self.templateTitle3 = [[UILabel alloc] initWithFrame:CGRectMake(16, TEMPLATE_IMAGE_HEIGHT+30, WIDTH_S, 30)];
        self.templateTitle3.numberOfLines = 0;
        self.templateTitle3.backgroundColor = [UIColor clearColor];
        self.templateTitle3.font = [UIFont systemFontOfSize:14];
        self.templateTitle3.textColor = RGBCOLOR(68, 68, 68);
        self.templateTitle3.textAlignment = NSTextAlignmentLeft;
        
        self.templateTitle4 = [[UILabel alloc] initWithFrame:CGRectMake(16, TEMPLATE_IMAGE_HEIGHT+60, WIDTH_S, 30)];
        self.templateTitle4.numberOfLines = 0;
        self.templateTitle4.backgroundColor = [UIColor clearColor];
        self.templateTitle4.font = [UIFont systemFontOfSize:14];
        self.templateTitle4.textColor = RGBCOLOR(68, 68, 68);
        self.templateTitle4.textAlignment = NSTextAlignmentLeft;
        
        self.templateBackView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 100)];
        [self.templateBackView setBackgroundColor:[UIColor whiteColor]];
        [self.templateBackView.layer setMasksToBounds:YES];
        [self.templateBackView.layer setCornerRadius:10.0];
        [self.templateBackView.layer setBorderColor:[RGBCOLOR(194, 194, 194) CGColor]];
        [self.templateBackView.layer setBorderWidth:1.0];
        
        [self.templateBackView addSubview:self.templateImage1];
        [self.templateBackView addSubview:self.templateTitle1]; // 文字在上边
        
        [self.templateBackView addSubview:self.templateTitle2];
        [self.templateBackView addSubview:self.templateImage2];
        [self.templateBackView addSubview:self.templateTitle3];
        [self.templateBackView addSubview:self.templateImage3];
        [self.templateBackView addSubview:self.templateTitle4];
        [self.templateBackView addSubview:self.templateImage4];
        
        [self.templateBackView addSubview:self.separaterView2];
        [self.templateBackView addSubview:self.separaterView3];
        [self.templateBackView addSubview:self.separaterView4];
        
        [self.contentView addSubview:self.templateBackView];
    }
    return self;
}

- (void)setData:(WSBubbleData *)data
{
    [super setData:data];
}


- (void) setupInternalData:(WSBubbleData *)cellData
{
    [super setupInternalData:cellData];
    
    CGFloat height = cellData.view.frame.size.height;
    
    NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:cellData.content error:nil];
    
    [self.templateBackView setFrame:CGRectMake(10, 0, 300, height +TEMPLATE_TITLE_HEIGHT)];
    [self.templateImage1 setFrame:CGRectMake(12, 10, 275, TEMPLATE_IMAGE_HEIGHT)];
    
    NSString *title1 = [[element elementForName:@"title1"] stringValue];
    NSString *title2 = [[element elementForName:@"title2"] stringValue];
    NSString *title3 = [[element elementForName:@"title3"] stringValue];
    NSString *title4 = [[element elementForName:@"title4"] stringValue];
    NSString *image1 = [[element elementForName:@"image1"] stringValue];
    NSString *image2 = [[element elementForName:@"image2"] stringValue];
    NSString *image3 = [[element elementForName:@"image3"] stringValue];
    NSString *image4 = [[element elementForName:@"image4"] stringValue];
    
    
    UIFont *titleFont = [UIFont boldSystemFontOfSize:16.0f];
    
    CGSize titleSize1 = [(title1 ? title1 : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(275, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGSize titleSize2 = [(title2 ? title2 : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(WIDTH_S, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGSize titleSize3 = [(title3 ? title3 : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(WIDTH_S, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGSize titleSize4 = [(title4 ? title4 : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(WIDTH_S, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat height1 = titleSize1.height + 10;
    CGFloat height2 = (titleSize2.height > TEMPLATE_CELL_IHEIGHT ? titleSize2.height : TEMPLATE_CELL_IHEIGHT);
    CGFloat height3 = (titleSize3.height > TEMPLATE_CELL_IHEIGHT ? titleSize3.height : TEMPLATE_CELL_IHEIGHT);
    CGFloat height4 = (titleSize4.height > TEMPLATE_CELL_IHEIGHT ? titleSize4.height : TEMPLATE_CELL_IHEIGHT);
    
    self.templateImage1.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.templateTitle1 setFrame:CGRectMake(12, TEMPLATE_IMAGE_HEIGHT - height1 - 2, 275, height1)];
    [self.templateTitle2 setFrame:CGRectMake(16, TEMPLATE_IMAGE_HEIGHT + TEMPLATE_CELL_OFFSET , WIDTH_S, height2)];
    [self.templateTitle3 setFrame:CGRectMake(16, TEMPLATE_IMAGE_HEIGHT + TEMPLATE_CELL_OFFSET*2 + height2, WIDTH_S, height3)];
    [self.templateTitle4 setFrame:CGRectMake(16, TEMPLATE_IMAGE_HEIGHT + TEMPLATE_CELL_OFFSET*3 + height2+ height3, WIDTH_S, height4)];
    
    [self.templateImage2 setFrame:CGRectMake(235, TEMPLATE_IMAGE_HEIGHT+TEMPLATE_CELL_OFFSET, TEMPLATE_CELL_IHEIGHT, TEMPLATE_CELL_IHEIGHT)];
    [self.templateImage3 setFrame:CGRectMake(235, TEMPLATE_IMAGE_HEIGHT+TEMPLATE_CELL_OFFSET*2 + height2,
                                             TEMPLATE_CELL_IHEIGHT, TEMPLATE_CELL_IHEIGHT)];
    [self.templateImage4 setFrame:CGRectMake(235, TEMPLATE_IMAGE_HEIGHT+TEMPLATE_CELL_OFFSET*3 + height2+ height3,
                                             TEMPLATE_CELL_IHEIGHT, TEMPLATE_CELL_IHEIGHT)];
    
    [self.separaterView2 setFrame:CGRectMake(0, TEMPLATE_IMAGE_HEIGHT+TEMPLATE_CELL_OFFSET-TEMPLATE_CELL_OFFSET/2,
                                             300, 1)];
    [self.separaterView3 setFrame:CGRectMake(235, TEMPLATE_IMAGE_HEIGHT+TEMPLATE_CELL_OFFSET*2-TEMPLATE_CELL_OFFSET/2 + height2,
                                             300, 1)];
    [self.separaterView4 setFrame:CGRectMake(235, TEMPLATE_IMAGE_HEIGHT+TEMPLATE_CELL_OFFSET*3-TEMPLATE_CELL_OFFSET/2 + height2+ height3,
                                             300, 1)];
    
    [self.templateImage1 setImageWithURL:[NSURL URLWithString:image1] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];
    [self.templateImage2 setImageWithURL:[NSURL URLWithString:image2] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];
    [self.templateImage3 setImageWithURL:[NSURL URLWithString:image3] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];
    [self.templateImage4 setImageWithURL:[NSURL URLWithString:image4] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];
    
    self.templateTitle1.text = [NSString stringWithFormat:@"  %@", title1];
    self.templateTitle2.text = title2;
    self.templateTitle3.text = title3;
    self.templateTitle4.text = title4;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
