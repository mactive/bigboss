//
//  WSBubbleData.m
//  iMedia
//
//  Created by meng qian on 12-11-12.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleData.h"
#import <QuartzCore/QuartzCore.h>
#import "XMPPFramework.h"

@implementation WSBubbleData

@synthesize date = _date;
@synthesize type = _type;
@synthesize avatar = _avatar;
@synthesize content = _content;
@synthesize showAvatar = _showAvatar;
@synthesize cellHeight = _cellHeight;
@synthesize msg = _msg;
@synthesize insets = _insets;
@synthesize view = _view;
@synthesize textLabel = _textLabel;
@synthesize templateView = _templateView;

const UIEdgeInsets textInsetsMine = {5, 10, 11, 17};
const UIEdgeInsets textInsetsSomeone = {5, 15, 11, 10};
const UIEdgeInsets templateAInsetsMine = {20, 20, 20, 20};
const UIEdgeInsets templateBInsetsMine = {12, 20, 12, 20};

#define MAX_WIDTH 220

//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - text bubble
//////////////////////////////////////////////////////////////////////////////////////////////////

+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(WSBubbleType)type
{
    return [[WSBubbleData alloc] initWithText:text date:date type:type];
}
- (id)initWithText:(NSString *)text date:(NSDate *)date type:(WSBubbleType)type
{
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(MAX_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.textLabel.text = (text ? text : @"");
    self.textLabel.font = font;
    self.textLabel.backgroundColor = [UIColor clearColor];
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:self.textLabel date:date content:text type:type insets:insets];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - web bubble templateA
//////////////////////////////////////////////////////////////////////////////////////////////////

+ (id)dataWithTemplateA:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
{
    return [[WSBubbleData alloc] initWithTemplateA:urlString date:date type:type];
}

- (id)initWithTemplateA:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
{
    NSXMLElement *element =[[NSXMLElement alloc] initWithXMLString:urlString error:nil];    
    
    NSString *title = [[element elementForName:@"title9"] stringValue];
    NSString *image = [[element elementForName:@"image9"] stringValue];
    NSString *content = [[element elementForName:@"content9"] stringValue];
    
    
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    UIFont *titleFont = [UIFont boldSystemFontOfSize:18];
    
    CGSize size = [(content ? content : @"") sizeWithFont:font constrainedToSize:CGSizeMake(275, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGSize titleSize = [(title ? title : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(275, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    self.templateView = [[UIView alloc]init];
    if (image == nil || [image length] == 0) {
        self.templateView.frame = CGRectMake(0, 0, 275,  size.height + titleSize.height);
    } else {
        self.templateView.frame = CGRectMake(0, 0, 275, TEMPLATE_IMAGE_HEIGHT+ size.height + titleSize.height);
    }
    
    UIEdgeInsets insets = templateAInsetsMine;
    return [self initWithView:self.templateView date:date content:urlString type:type insets:insets];
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - web bubble templateB
//////////////////////////////////////////////////////////////////////////////////////////////////

+ (id)dataWithTemplateB:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
{
    return [[WSBubbleData alloc] initWithTemplateB:urlString date:date type:type];
}


- (id)initWithTemplateB:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
{
    // 4块 分区域显示
    // title1 为大图 title2 3 4 为小图
    NSXMLElement *element =[[NSXMLElement alloc] initWithXMLString:urlString error:nil];
    
    NSString *title2 = [[element elementForName:@"title2"] stringValue];
    NSString *title3 = [[element elementForName:@"title3"] stringValue];
    NSString *title4 = [[element elementForName:@"title4"] stringValue];
    
    
    UIFont *titleFont = [UIFont boldSystemFontOfSize:16.0f];
    
    CGSize titleSize2 = [(title2 ? title2 : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(TEMPLATEB_RESIZE_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGSize titleSize3 = [(title3 ? title3 : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(TEMPLATEB_RESIZE_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGSize titleSize4 = [(title4 ? title4 : @"") sizeWithFont:titleFont constrainedToSize:CGSizeMake(TEMPLATEB_RESIZE_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat height2 = (titleSize2.height > TEMPLATE_CELL_IHEIGHT ? titleSize2.height : TEMPLATE_CELL_IHEIGHT) + TEMPLATE_CELL_OFFSET;
    CGFloat height3 = (titleSize3.height > TEMPLATE_CELL_IHEIGHT ? titleSize3.height : TEMPLATE_CELL_IHEIGHT) + TEMPLATE_CELL_OFFSET;
    CGFloat height4 = (titleSize4.height > TEMPLATE_CELL_IHEIGHT ? titleSize4.height : TEMPLATE_CELL_IHEIGHT) + TEMPLATE_CELL_OFFSET;
    
    self.templateView = [[UIView alloc]init];
    self.templateView.frame = CGRectMake(0, 0, 275, TEMPLATE_IMAGE_HEIGHT + height2 + height3 + height4);
    
    
    UIEdgeInsets insets = templateBInsetsMine;
    return [self initWithView:self.templateView date:date content:urlString type:type insets:insets];
}


- (id)initWithView:(UIView *)view date:(NSDate *)date content:(NSString *)content type:(WSBubbleType)type insets:(UIEdgeInsets)insets
{
    self = [super init];
    if (self)
    {
        
        _date = date;
        _type = type;
        _content = content;
        _insets = insets;
        self.msg = _msg;
        self.showAvatar = type != BubbleTypeTemplateAview ? YES : NO ;
        self.cellHeight = view.frame.size.height;
        self.view = view;
    }
    return self;
}


@end
