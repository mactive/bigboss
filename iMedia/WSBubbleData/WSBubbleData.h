//
//  WSBubbleData.h
//  iMedia
//
//  Created by meng qian on 12-11-12.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

typedef enum _WSBubbleType
{
    BubbleTypeMine = 0,
    BubbleTypeSomeoneElse = 1,
    BubbleTypeRateview = 2,
    BubbleTypeNoticationview = 3,
    BubbleTypeTemplateAview = 4,
    BubbleTypeTemplateBview = 5
} WSBubbleType;

@interface WSBubbleData : NSObject

@property (readonly, nonatomic, strong) NSDate *date;
@property (readonly, nonatomic) WSBubbleType type;
@property (readwrite, nonatomic) BOOL showAvatar;
@property (readonly, nonatomic) NSString *content;
@property (nonatomic, strong) UIImage *avatar;
@property (nonatomic, readwrite) CGFloat cellHeight;
@property (nonatomic, retain)Message * msg;
@property (readonly, nonatomic) UIEdgeInsets insets;
@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UIView *templateView;




- (id)initWithText:(NSString *)text date:(NSDate *)date type:(WSBubbleType)type;
+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(WSBubbleType)type;
- (id)initWithTemplateA:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type;
+ (id)dataWithTemplateA:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type;
- (id)initWithTemplateB:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type;
+ (id)dataWithTemplateB:(NSString *)urlString date:(NSDate *)date type:(WSBubbleType)type;

- (id)initWithView:(UIView *)view date:(NSDate *)date content:(NSString *)content type:(WSBubbleType)type insets:(UIEdgeInsets)insets;


@end
