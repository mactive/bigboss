//
//  dataersationTableViewCell.m
//  jiemo
//
//  Created by meng qian on 12-12-5.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import "ConversationTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+timesince.h"
#import "User.h"
#import "Channel.h"
#import "Conversation.h"
#import "DDLog.h"
#import "AppNetworkAPIClient.h"
#import "CustomBadge.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface ConversationTableViewCell()

@property(nonatomic, strong)UIImage *avatarImage;
@property(nonatomic, strong)CustomBadge *badgeView;
@property(nonatomic, readwrite)BOOL timeShow;
@end

@implementation ConversationTableViewCell

@synthesize data = _data;
@synthesize avatarImage;
@synthesize badgeView;
@synthesize timeShow;

#define CELL_W      320.0f
#define CELL_H      60.0f
#define AVA_D       50.0f
#define AVA_X       5.0f
#define AVA_Y       5.0f

#define ROW_HEIGHT  CELL_H

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0


#define MAIN_FONT_SIZE 16.0
#define SUMMARY_PADDING 10.0

#define IMAGE_SIDE 50.0
#define SUMMARY_WIDTH 90.0

/////////////////////////////////

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0

#define MIDDLE_COLUMN_OFFSET 70.0
#define MIDDLE_COLUMN_WIDTH 150.0

#define RIGHT_COLUMN_OFFSET 245.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 14.0
#define LABEL_HEIGHT 25.0
#define MESSAGE_LABEL_HEIGHT 15.0

#define IMAGE_SIDE 50.0
#define SUMMARY_WIDTH_OFFEST 16.0
#define BADGE_WIDTH 20.0

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code

        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.timeShow = YES;
        // badge view
        CGRect rect = CGRectMake(LEFT_COLUMN_OFFSET+LEFT_COLUMN_WIDTH+3, 2 ,BADGE_WIDTH ,BADGE_WIDTH );
        self.badgeView = [CustomBadge customBadgeWithString:@""];
        [self.badgeView setFrame:rect];
        [self.contentView addSubview:self.badgeView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self setNeedsDisplay];
}

- (void)setNewTimeShow:(BOOL)timeShowBool
{
    self.timeShow = timeShowBool;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    // Drawing code
    // highlight and selected background
    if (self.selected || self.highlighted) {
        CGRect rectangle = self.bounds;
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(context, 0.86, 0.86, 0.86, 1.0);
        //        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, rectangle);
    }
    // nickname
    UIColor *nameMagentaColor = RGBCOLOR(107, 107, 107);
    [nameMagentaColor set];
    CGRect nameRect = CGRectMake(MIDDLE_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE)/2.0+2, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
    NSString *nameString;
    if (_data.type == ConversationTypePlugginFriendRequest) {
        nameString = _data.ownerEntity.displayName;
    } else if (_data.type == ConversationTypeMediaChannel) {
        nameString = _data.ownerEntity.displayName;
    } else if (_data.type == ConversationTypeSingleUserChat) {
        User* anUser = [_data.attendees anyObject];
        nameString = anUser.displayName;
    } else {
        DDLogError(@"FIX: unhandled conversation type");
    }
    [nameString drawInRect:nameRect
                  withFont:[UIFont systemFontOfSize:MAIN_FONT_SIZE]];
    
    /* signaure */
    UIColor *signMagentaColor = RGBCOLOR(158, 158, 158);
    [signMagentaColor set];
    CGRect signRect = CGRectMake(MIDDLE_COLUMN_OFFSET, ROW_HEIGHT - (IMAGE_SIDE / 2.0), MIDDLE_COLUMN_WIDTH, MESSAGE_LABEL_HEIGHT);
    NSString *signatureString = _data.lastMessageText;
    [signatureString drawInRect:signRect
                  withFont:[UIFont systemFontOfSize:SUMMARY_FONT_SIZE]];
    
    /* time */
    if (self.timeShow) {
        UIColor *magentaColor = RGBCOLOR(187, 187, 187);
        [magentaColor set];
        NSString *timeString = [self.data.lastMessageSentDate timesince];
        CGRect timerect = CGRectMake(RIGHT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0 + 5, RIGHT_COLUMN_WIDTH, 15.0);
        UIFont *timeFont = [UIFont boldSystemFontOfSize:SUMMARY_FONT_SIZE];
        [timeString drawInRect:timerect withFont:timeFont lineBreakMode:NSLineBreakByCharWrapping alignment:NSTextAlignmentRight];
    }
    
    /* avatar */
    self.avatarImage = [[UIImage alloc]init];
    CGRect avatarRect =  CGRectMake(LEFT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);

    if (self.data.type == ConversationTypePlugginFriendRequest) {
        self.avatarImage = self.data.ownerEntity.thumbnailImage;
        
    } else if (self.data.type == ConversationTypeMediaChannel) {
        if (self.data.ownerEntity.thumbnailImage) {
            self.avatarImage = self.data.ownerEntity.thumbnailImage;
        } else {
            if (StringHasValue(self.data.ownerEntity.thumbnailURL)) {
                [[AppNetworkAPIClient sharedClient]loadImage:self.data.ownerEntity.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
                    self.avatarImage = image;
                }];
            }else{
                self.avatarImage = [UIImage imageNamed:@"placeholder_company.png"];
            }
        }
    } else if (self.data.type == ConversationTypeSingleUserChat) {
        User *user = [self.data.attendees anyObject];
        if (user.thumbnailImage) {
            self.avatarImage = user.thumbnailImage;
        } else {
            if (StringHasValue(user.thumbnailURL)) {
                [[AppNetworkAPIClient sharedClient] loadImage:user.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
                    self.avatarImage = image;
                }];
            }else{
                self.avatarImage = [UIImage imageNamed:@"placeholder_user.png"];
            }
        }
    } else {
        DDLogError(@"FIX: unhandled dataersation type");
    }

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:avatarRect cornerRadius:5].CGPath;
    CGContextAddPath(ctx, clippath);
    CGContextClip(ctx);
    [self.avatarImage drawInRect:avatarRect];
    CGContextRestoreGState(ctx);
    
    if (self.data.unreadMessagesCount == 0) {
        [self.badgeView setHidden:YES];
    }else{
        [self.badgeView setHidden:NO];
        [self.badgeView autoBadgeSizeWithString:[NSString stringWithFormat:@"%i",self.data.unreadMessagesCount]];
    }
}


@end
