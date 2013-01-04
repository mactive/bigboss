//
//  ContactTableViewCell.m
//  jiemo
//
//  Created by meng qian on 12-12-27.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import "ContactTableViewCell.h"
#import "User.h"
#import "Channel.h"
#import "Me.h"
#import "AppNetworkAPIClient.h"

@interface ContactTableViewCell()

@property(nonatomic, strong)Identity *data;
@property(nonatomic, strong)UIImage *avatarImage;
@end


@implementation ContactTableViewCell
@synthesize data;
@synthesize avatarImage;

#define ROW_HEIGHT 60
#define NAME_TAG 1
#define SNS_TAG 20
#define AVATAR_TAG 3
#define SUMMARY_TAG 4

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0

#define MIDDLE_COLUMN_OFFSET 70.0
#define MIDDLE_COLUMN_WIDTH 100.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 12.0
#define LABEL_HEIGHT 20.0
#define SUMMARY_PADDING 10.0

#define IMAGE_SIDE 50.0
#define SNS_SIDE 15.0
#define SUMMARY_WIDTH_OFFEST 30.0
#define SUMMARY_WIDTH 80.0


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
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


- (void)setNewInentity:(Identity *)identity
{
    self.data  = identity;
    
    if (identity.thumbnailImage != nil) {
        self.avatarImage = identity.thumbnailImage;
    } else if (StringHasValue(identity.thumbnailURL)){
        [[AppNetworkAPIClient sharedClient] loadImage:identity.thumbnailURL withBlock:^(UIImage *image, NSError *error) {
            if (image) {
                identity.thumbnailImage = image;
            }
        }];
    } else {
        if ([identity isKindOfClass:[Channel class]]) {
            self.avatarImage = [UIImage imageNamed:@"placeholder_company.png"];
        } else if ([identity isKindOfClass:[User class]]) {
            self.avatarImage = [UIImage imageNamed:@"placeholder_user.png"];
        } else {
            self.avatarImage = [UIImage imageNamed:@"placeholder_user.png"];
        }
    }
    
    [self setNeedsDisplay];

}


- (void)drawRect:(CGRect)rect
{
    if (self.selected || self.highlighted) {
        CGRect rectangle = self.bounds;
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(context, 0.86, 0.86, 0.86, 1.0);
//        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, rectangle);
    }
    
    //// avatar
    CGRect avatarRect = CGRectMake(LEFT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:avatarRect cornerRadius:5].CGPath;
    CGContextAddPath(ctx, clippath);
    CGContextClip(ctx);
    [self.avatarImage drawInRect:avatarRect];
    CGContextRestoreGState(ctx);
    
    
    // set max size
    CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*2);
    CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);
    CGFloat _labelHeight;

    NSString *nameString;
    NSString *signatureString;
    if ([self.data isKindOfClass:[User class]]) {
        User *user = (User *)self.data ;
        nameString = user.displayName;
        signatureString = user.signature;
        
    } else if ([self.data  isKindOfClass:[Channel class]]) {
        Channel *channel = (Channel *)self.data ;
        nameString = channel.displayName;
        signatureString = channel.selfIntroduction;
    } else if ([self.data  isKindOfClass:[Me class]]) {
        Me *me = (Me *)self.data;
        nameString = me.displayName;
        signatureString = me.signature;
    }

    // nickname
    UIColor *nameMagentaColor = RGBCOLOR(107, 107, 107);
    [nameMagentaColor set];
    UIFont* nameFont = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    CGSize labelSize = [nameString sizeWithFont:nameFont constrainedToSize:nameMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (labelSize.height > LABEL_HEIGHT) {
        _labelHeight = 10.0;
    }else {
        _labelHeight = 20.0;
    }
    
    CGRect nameRect = CGRectMake(MIDDLE_COLUMN_OFFSET, _labelHeight, labelSize.width, labelSize.height);

    [nameString drawInRect:nameRect
                  withFont:[UIFont systemFontOfSize:MAIN_FONT_SIZE]];
    
    // signature
    UIColor *signatureMagentaColor = RGBCOLOR(187, 187, 187);
    [signatureMagentaColor set];
    UIFont* signatureFont = [UIFont boldSystemFontOfSize:SUMMARY_FONT_SIZE];
    CGSize signatureSize = [signatureString sizeWithFont:signatureFont constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > LABEL_HEIGHT) {
        _labelHeight = 13.0;
    }else {
        _labelHeight = 23.0;
    }
    CGRect signatureRect = CGRectMake(280 - signatureSize.width - SUMMARY_PADDING, _labelHeight, signatureSize.width + SUMMARY_PADDING, signatureSize.height+SUMMARY_PADDING);
    [signatureString drawInRect:signatureRect withFont:signatureFont];
    
}


@end
