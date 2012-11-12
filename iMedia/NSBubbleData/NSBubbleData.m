//
//  NSBubbleData.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "NSBubbleData.h"
#import <QuartzCore/QuartzCore.h>
#import "XMPPFramework.h"

@implementation NSBubbleData

#pragma mark - Properties

@synthesize date = _date;
@synthesize type = _type;
@synthesize view = _view;
@synthesize insets = _insets;
@synthesize avatar = _avatar;
@synthesize content = _content;
@synthesize templateView = templateView;
@synthesize showAvatar = _showAvatar;
@synthesize isDone = _isDone;
@synthesize cellHeight = _cellHeight;
@synthesize msg = _msg;

#pragma mark - Lifecycle

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_date release];
	_date = nil;
    [_view release];
    _view = nil;
    
    self.avatar = nil;

    [super dealloc];
}
#endif

#pragma mark - Text bubble

const UIEdgeInsets NStextInsetsMine = {5, 10, 11, 17};
const UIEdgeInsets NStextInsetsSomeone = {5, 15, 11, 10};

+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithText:text date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithText:text date:date type:type];
#endif    
}

- (id)initWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = (text ? text : @"");
    label.font = font;
    label.backgroundColor = [UIColor clearColor];
    
#if !__has_feature(objc_arc)
    [label autorelease];
#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? NStextInsetsMine : NStextInsetsSomeone);
    return [self initWithView:label date:date content:text type:type insets:insets];
}

#pragma mark - Image bubble

const UIEdgeInsets imageInsetsMine = {11, 13, 16, 22};
const UIEdgeInsets templateInsetsMine = {30, 30, 16, 22};
const UIEdgeInsets imageInsetsSomeone = {11, 18, 16, 14};

+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithImage:image date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithImage:image date:date type:type];
#endif    
}

- (id)initWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
    CGSize size = image.size;
    if (size.width > 220)
    {
        size.height /= (size.width / 220);
        size.width = 220;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    imageView.image = image;
    imageView.layer.cornerRadius = 5.0;
    imageView.layer.masksToBounds = YES;

    
#if !__has_feature(objc_arc)
    [imageView autorelease];
#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:imageView date:date content:nil type:type insets:insets];
}

#pragma mark - web bubble
+ (id)dataWithWeb:(NSString *)urlString date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithWeb:urlString date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithWeb:urlString date:date type:type];
#endif
}

- (id)initWithWeb:(NSString *)urlString date:(NSDate *)date type:(NSBubbleType)type
{
    NSXMLElement *element =[[NSXMLElement alloc] initWithXMLString:urlString error:nil];
    
    NSString *image = [[element elementForName:@"image9"] stringValue];
    NSString *content = [[element elementForName:@"content9"] stringValue];
    
    
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = [(content ? content : @"") sizeWithFont:font constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = (content ? content : @"");
    label.font = font;
    
#if !__has_feature(objc_arc)
    [label autorelease];
#endif
    
    if (image == nil || [image length] == 0) {
        self.templateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 275, label.frame.size.height + TEMPLATE_TITLE_HEIGHT)];
    } else {
        self.templateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 275, TEMPLATE_IMAGE_HEIGHT+label.frame.size.height+TEMPLATE_TITLE_HEIGHT)];
    }
    
#if !__has_feature(objc_arc)
    [self.templateView autorelease];
#endif
    
    UIEdgeInsets insets = templateInsetsMine;
    return [self initWithView:self.templateView date:date content:urlString type:type insets:insets];
    
}

#pragma mark - Custom view bubble

+ (id)dataWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithView:view date:date type:type insets:insets] autorelease];
#else
    return [[NSBubbleData alloc] initWithView:view date:date content:nil type:type insets:insets];
#endif    
}

- (id)initWithView:(UIView *)view date:(NSDate *)date content:(NSString *)content type:(NSBubbleType)type insets:(UIEdgeInsets)insets
{
    self = [super init];
    if (self)
    {
#if !__has_feature(objc_arc)
        _view = [view retain];
        _date = [date retain];
#else
        _view = view;
        _date = date;
#endif
        _type = type;
        _content = content;
        _insets = insets;
    
        self.showAvatar = type != BubbleTypeTemplateview ? YES : NO ;
        self.isDone = NO;
        self.cellHeight = 0.0f;
    }
    return self;
}

@end
