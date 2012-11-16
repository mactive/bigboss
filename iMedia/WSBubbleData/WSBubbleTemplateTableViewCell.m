//
//  WSBubbleTemplateTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-14.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleTemplateTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "XMPPFramework.h"
#import "UIImageView+AFNetworking.h"
#import "WSBubbleData.h"


@interface WSBubbleTemplateTableViewCell ()

@property (nonatomic, strong) UIView *templateBackView;
@property (nonatomic, strong) UILabel *templateTitle;
@property (nonatomic, strong) UIImageView *templateImage;
@property (nonatomic, strong) UILabel *templateContent;

- (void) setupInternalData:(WSBubbleData *)cellData;

@end

@implementation WSBubbleTemplateTableViewCell
@synthesize templateBackView = _templateBackView;
@synthesize templateTitle = _templateTitle;
@synthesize templateImage = _templateImage;
@synthesize templateContent = _templateContent;
@synthesize data = _data;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.templateBackView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 100)];
        self.templateContent = [[UILabel alloc] initWithFrame:CGRectMake(12, 180, 275, 100)];
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
                
        [self.templateBackView addSubview:self.templateImage];
        [self.templateBackView addSubview:self.templateContent];
        [self.templateBackView addSubview:self.templateTitle];
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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
