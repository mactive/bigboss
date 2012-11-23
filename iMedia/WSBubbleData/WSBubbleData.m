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
const UIEdgeInsets templateInsetsMine = {20, 20, 20, 20};

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
#pragma mark - web bubble
//////////////////////////////////////////////////////////////////////////////////////////////////

+ (id)dataWithTemplate:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
{
    return [[WSBubbleData alloc] initWithTemplate:urlString date:date type:type];
}

- (id)initWithTemplate:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
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
    
    UIEdgeInsets insets = templateInsetsMine;
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
        self.showAvatar = type != BubbleTypeTemplateview ? YES : NO ;
        self.cellHeight = view.frame.size.height;
        self.view = view;
    }
    return self;
}


@end
