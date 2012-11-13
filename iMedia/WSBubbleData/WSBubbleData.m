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
@synthesize isDone = _isDone;
@synthesize cellHeight = _cellHeight;
@synthesize msg = _msg;
@synthesize insets = _insets;
@synthesize view = _view;


const UIEdgeInsets textInsetsMine = {5, 10, 11, 17};
const UIEdgeInsets textInsetsSomeone = {5, 15, 11, 10};
const UIEdgeInsets templateInsetsMine = {30, 30, 16, 22};

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
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = (text ? text : @"");
    label.font = font;
    label.backgroundColor = [UIColor clearColor];

    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:label date:date content:text type:type insets:insets];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - web bubble
//////////////////////////////////////////////////////////////////////////////////////////////////

+ (id)dataWithWeb:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
{
    return [[WSBubbleData alloc] initWithWeb:urlString date:date type:type];
}

- (id)initWithWeb:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type
{
    NSXMLElement *element =[[NSXMLElement alloc] initWithXMLString:urlString error:nil];
    
    NSString *image = [[element elementForName:@"image9"] stringValue];
    NSString *content = [[element elementForName:@"content9"] stringValue];
    
    
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = [(content ? content : @"") sizeWithFont:font constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    UIView *templateView = [[UIView alloc] init];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = (content ? content : @"");
    label.font = font;

    
    if (image == nil || [image length] == 0) {
        templateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 275, label.frame.size.height + TEMPLATE_TITLE_HEIGHT)];
    } else {
        templateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 275, TEMPLATE_IMAGE_HEIGHT+label.frame.size.height+TEMPLATE_TITLE_HEIGHT)];
    }
    
    UIEdgeInsets insets = templateInsetsMine;
    return [self initWithView:templateView date:date content:urlString type:type insets:insets];
    
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
        
        self.showAvatar = type != BubbleTypeTemplateview ? YES : NO ;
        self.isDone = NO;
        self.cellHeight = view.frame.size.height;
        self.view = view;
    }
    return self;
}


@end
