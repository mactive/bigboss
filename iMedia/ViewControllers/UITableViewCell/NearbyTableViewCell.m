//
//  NearbyTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-19.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "NearbyTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+timesince.h"
#import "LocationManager.h"
#import "ModelHelper.h"
#import "User.h"
#import "ServerDataTransformer.h"
#import "AppNetworkAPIClient.h"
#import "ServerDataTransformer.h"

@interface NearbyTableViewCell()

@property(nonatomic, strong)UIImage *avatarImage;
@property(nonatomic, strong)NSDictionary *data;
@end

@implementation NearbyTableViewCell
@synthesize data;
@synthesize avatarImage;
@synthesize delegate;

#define CELL_W      320.0f
#define CELL_H      60.0f
#define AVA_D       50.0f
#define AVA_X       5.0f
#define AVA_Y       5.0f

#define ROW_HEIGHT  CELL_H

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 36.0


#define MIDDLE_COLUMN_OFFSET 65.0
#define MIDDLE_COLUMN_WIDTH 100.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 12.0
#define LABEL_HEIGHT 20.0
#define SUMMARY_PADDING 10.0

#define IMAGE_SIDE 50.0
#define SNS_SIDE 15.0
#define SUMMARY_WIDTH_OFFEST 10.0
#define SUMMARY_WIDTH 80.0

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.avatarImage = nil;
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

- (void)setNewData:(NSDictionary *)_data
{
    self.data = _data;

    
    if ([self.data objectForKey:@"cachedThumbnail"] != nil) {
        self.avatarImage = [self.data objectForKey:@"cachedThumbnail"];
        [self setNeedsDisplay];

    }else{
        self.avatarImage = [UIImage imageNamed:@"placeholder_user.png"];
        [self setNeedsDisplay];
        [[AppNetworkAPIClient sharedClient]loadImage:[self.data objectForKey:@"thumbnail"] withBlock:^(UIImage *image, NSError *error) {
            if(image){
                self.avatarImage = image;
                NSString *key = [ServerDataTransformer getStringObjFromServerJSON:self.data byName:@"guid"];
                [self.delegate passUIImageValue:self.avatarImage andKey:key];
                [self setNeedsDisplay];
            }
        }];
    }
    
    
}

- (void)drawRect:(CGRect)rect
{
    // highlight and selected background
    if (self.selected || self.highlighted) {
        CGRect rectangle = self.bounds;
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(context, 0.86, 0.86, 0.86, 1.0);
        //        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, rectangle);
    }
    
    //// avatar
    CGRect avatarRect = CGRectMake(AVA_X, AVA_Y, AVA_D, AVA_D);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:avatarRect cornerRadius:5].CGPath;
    CGContextAddPath(ctx, clippath);
    CGContextClip(ctx);
    [self.avatarImage drawInRect:avatarRect];
    CGContextRestoreGState(ctx);
    
    // nickname
    UIColor *nameMagentaColor = RGBCOLOR(107, 107, 107);
    [nameMagentaColor set];
    UIFont *nameFont = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
    CGRect nameRect = CGRectMake(MIDDLE_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE)/2.0+2, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
    CGRect genderRect;
    CGRect friendRect;
    NSString *nameString = [self.data objectForKey:@"nickname"];

    if ([nameString length] != 0) {
        CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
        CGSize nameSize = [[self.data objectForKey:@"nickname"] sizeWithFont:nameFont constrainedToSize:nameMaxSize lineBreakMode: UILineBreakModeTailTruncation];
        nameRect = CGRectMake(MIDDLE_COLUMN_OFFSET +3, 7, nameSize.width + SUMMARY_PADDING, nameSize.height);
        genderRect = CGRectMake(MIDDLE_COLUMN_OFFSET + nameSize.width +10, 10.5, 15, 15);
        friendRect = CGRectMake(MIDDLE_COLUMN_OFFSET + nameSize.width +30, 10.5, 30, 15);
        [nameString drawInRect:nameRect withFont:nameFont];
    }
    
    //// gender icon
    UIImage *genderImage;
    if ([[self.data objectForKey:@"gender"] isEqual:@"f"] && genderRect.origin.x != 0) {
        genderImage = [UIImage imageNamed:@"famale_icon.png"];
        [genderImage drawInRect:genderRect];
    }else if([[self.data objectForKey:@"gender"] isEqual:@"m"] && genderRect.origin.x != 0){
        genderImage = [UIImage imageNamed:@"male_icon.png"];
        [genderImage drawInRect:genderRect];
    }
    
    // friend icon
    UIImage *friendImage;
    User* aUser = [[ModelHelper sharedInstance] findUserWithGUID:[ServerDataTransformer getGUIDFromServerJSON:self.data]];
    if (aUser != nil && aUser.state == IdentityStateActive) {
        // is friend
        friendImage = [UIImage imageNamed:@"friend_icon.png"];
        [friendImage drawInRect:friendRect];
    }
    // location icon
    UIImage *locationIcon = [UIImage imageNamed:@"location_icon.png"];
    [locationIcon drawInRect:CGRectMake(MIDDLE_COLUMN_OFFSET, 36 , 15, 15)];
    // location text
    NSString *locationString = [self distanceDisplay:[self.data objectForKey:@"distance"]];
    UIColor *locationMagentaColor = RGBCOLOR(187, 187, 187);
    [locationMagentaColor set];
    UIFont *locationFont = [UIFont boldSystemFontOfSize:SUMMARY_FONT_SIZE];
    CGRect locationRect = CGRectMake(MIDDLE_COLUMN_OFFSET+17 , 36, 60, LABEL_HEIGHT);
    [locationString drawInRect:locationRect withFont:locationFont];
    
    // time icon
    UIImage *timeIcon = [UIImage imageNamed:@"time_icon.png"];
    [timeIcon drawInRect:CGRectMake(MIDDLE_COLUMN_OFFSET+78, 36 , 15, 15)];
    // time text
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc]init];
    [dateFormater setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *updateDate = [dateFormater dateFromString:[self.data objectForKey:@"last_updated"]];
    
    NSString *timeString = [updateDate timesinceAgo];
    UIColor *timeMagentaColor = RGBCOLOR(187, 187, 187);
    [timeMagentaColor set];
    UIFont *timeFont = [UIFont boldSystemFontOfSize:SUMMARY_FONT_SIZE];
    CGRect timeRect = CGRectMake(MIDDLE_COLUMN_OFFSET+96 , 36, 50, LABEL_HEIGHT);
    [timeString drawInRect:timeRect withFont:timeFont];
    
    // signature    
    NSString * signatureString = [data objectForKey:@"signature"];
    UIColor *signatureMagentaColor = RGBCOLOR(187, 187, 187);
    [signatureMagentaColor set];
    
    if ([signatureString length] != 0 && signatureString != nil ) {
        CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);
        CGFloat _labelHeight;
        CGSize signatureSize = [signatureString sizeWithFont:locationFont constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
        if (signatureSize.height > LABEL_HEIGHT) {
            _labelHeight = 13.0;
        }else {
            _labelHeight = 23.0;
        }
        
        CGRect signRect = CGRectMake(300 - signatureSize.width - SUMMARY_PADDING, _labelHeight, signatureSize.width + SUMMARY_PADDING, signatureSize.height+SUMMARY_PADDING);
        [signatureString drawInRect:signRect withFont:locationFont lineBreakMode:UILineBreakModeTailTruncation alignment:NSTextAlignmentRight];
    }
    

}

- (NSString *)distanceDisplay:(NSNumber *)distanceNumber
{
    CGFloat distance = [distanceNumber floatValue];
        
    NSString *distanceString = @"";
    if (distance == 0) {
        distanceString = T(@"就在这");
    } else if (distance < 1000) {   // less than 1KM，count by m
        distanceString = [NSString stringWithFormat:T(@"%.0f米"), distance];
    } else if (distance < 50000) { // less than 50KM，count by KM,show decimals
        distanceString = [NSString stringWithFormat:T(@"%.1f公里"), distance / 1000.0f];
    } else if (distance < 1000000) { // less than 100KM，count by KM, NOT show decimals
        distanceString = [NSString stringWithFormat:T(@"%.0f公里"), distance / 1000.0f];
    } else {
        distanceString = T(@">1K公里"); // more than 1000KM，count by KM,too for
    }
    
    return distanceString;
}


@end
