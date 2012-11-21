//
//  NearbyTableViewCell.m
//  iMedia
//
//  Created by meng qian on 12-11-19.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "NearbyTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+timesince.h"
#import "LocationManager.h"

@interface NearbyTableViewCell()

@property(nonatomic, strong)UIImageView *avatarView;
@property(nonatomic, strong)UIImageView *timeIconView;
@property(nonatomic, strong)UIImageView *locationIconView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *locationLabel;
@property(nonatomic, strong)UILabel *timeLabel;
@property(nonatomic, strong)UILabel *signatureLabel;
@property(nonatomic, strong)UIImageView *genderView;
@property(nonatomic, strong)CLLocation *here_location;

@end

@implementation NearbyTableViewCell
@synthesize data = _data;
@synthesize avatarView;
@synthesize timeIconView;
@synthesize locationIconView;
@synthesize nameLabel;
@synthesize locationLabel;
@synthesize timeLabel;
@synthesize signatureLabel;
@synthesize genderView;
@synthesize here_location;

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
#define SUMMARY_WIDTH 90.0

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
        UIImageView *cellBgSelectedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg_highlighted.png"]];
        self.selectedBackgroundView =  cellBgSelectedView;
        
        // avatar
        self.avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(AVA_X, AVA_Y, AVA_D, AVA_D)];
        CALayer *avatarLayer = [avatarView layer];
        [avatarLayer setMasksToBounds:YES];
        [avatarLayer setCornerRadius:5.0];
        [avatarLayer setBorderWidth:1.0];
        [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
        
        // set gender
        self.genderView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
        
        
        CGRect rect;
        
        // nickname
        rect = CGRectMake(MIDDLE_COLUMN_OFFSET,6, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
        self.nameLabel = [[UILabel alloc] initWithFrame:rect];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
        self.nameLabel.textAlignment = UITextAlignmentLeft;
        self.nameLabel.textColor = RGBCOLOR(107, 107, 107);
        self.nameLabel.backgroundColor = [UIColor clearColor];
        
        // location icon
        rect = CGRectMake(MIDDLE_COLUMN_OFFSET, 36 , 15, 15);
        self.locationIconView = [[UIImageView alloc] initWithFrame:rect];
        self.locationIconView.image = [UIImage imageNamed:@"location_icon.png"];
        
        // location
        rect = CGRectMake(MIDDLE_COLUMN_OFFSET+17 , 33, 50, LABEL_HEIGHT);
        self.locationLabel = [[UILabel alloc] initWithFrame:rect];
        self.locationLabel.font = [UIFont boldSystemFontOfSize:SUMMARY_FONT_SIZE];
        self.locationLabel.textAlignment = UITextAlignmentLeft;
        self.locationLabel.textColor = RGBCOLOR(187, 187, 187);
        self.locationLabel.backgroundColor = [UIColor clearColor];
        
        // time icon
        rect = CGRectMake(MIDDLE_COLUMN_OFFSET+70, 36 , 15, 15);
        self.timeIconView = [[UIImageView alloc] initWithFrame:rect];
        self.timeIconView.image = [UIImage imageNamed:@"time_icon.png"];
        
        // time
        rect = CGRectMake(MIDDLE_COLUMN_OFFSET+87 , 33, 50, LABEL_HEIGHT);
        self.timeLabel = [[UILabel alloc] initWithFrame:rect];
        self.timeLabel.font = [UIFont boldSystemFontOfSize:SUMMARY_FONT_SIZE];
        self.timeLabel.textAlignment = UITextAlignmentLeft;
        self.timeLabel.textColor = RGBCOLOR(187, 187, 187);
        self.timeLabel.backgroundColor = [UIColor clearColor];

        
        // signature
        rect = CGRectMake(CELL_W - SUMMARY_WIDTH - SUMMARY_WIDTH_OFFEST , 12.5, SUMMARY_WIDTH, LABEL_HEIGHT);
        self.signatureLabel = [[UILabel alloc] initWithFrame:rect];
        self.signatureLabel.numberOfLines = 2;
        self.signatureLabel.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
        self.signatureLabel.textAlignment = UITextAlignmentCenter;
        self.signatureLabel.textColor = RGBCOLOR(158, 158, 158);
        self.signatureLabel.backgroundColor = RGBCOLOR(236, 238, 240);
        [self.signatureLabel.layer setMasksToBounds:YES];
        [self.signatureLabel.layer setCornerRadius:3.0];
        
        
        [self.contentView addSubview: self.avatarView];
        [self.contentView addSubview: self.timeIconView];
        [self.contentView addSubview: self.locationIconView];
        [self.contentView addSubview: self.genderView];
        [self.contentView addSubview: self.locationLabel];
        [self.contentView addSubview: self.timeLabel];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview: self.signatureLabel];
        
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        self.here_location  = locationManager.location;
    }
    return self;
}

- (void)setData:(NSDictionary *)data
{
    //// avatar
    NSURL *avatarURL = [[NSURL alloc]initWithString:[data objectForKey:@"thumbnail"]];
    [self.avatarView setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:@"placeholder_user.png"]];
    
    //// gender 
    if ([[data objectForKey:@"gender"] isEqual:@"f"]) {
        [self.genderView setImage:[UIImage imageNamed:@"famale_icon.png"]];
    }else{
        [self.genderView setImage:[UIImage imageNamed:@"male_icon.png"]];
    }
    
    //// location && time
    
    NSString *lon  = [data objectForKey:@"lon"];
    NSString *lat  = [data objectForKey:@"lat"];
    CLLocation *dataLocation = [[CLLocation alloc] initWithLatitude:[lat doubleValue]
                                                          longitude:[lon doubleValue]];
	CLLocationDistance dataDistance = -1.0f;
	if (self.here_location != nil && dataLocation != nil)
		dataDistance = [dataLocation distanceFromLocation:self.here_location];
    
    // time
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc]init];
    [dateFormater setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *updateDate = [dateFormater dateFromString:[data objectForKey:@"last_updated"]];
    
    // location , timeago
    self.locationLabel.text = [self distanceDisplay:dataDistance];
    self.timeLabel.text     = [updateDate timesinceAgo];
                               
    //// nickname
    if ([[data objectForKey:@"nickname"] length] != 0) {
        CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
        CGSize nameSize = [[data objectForKey:@"nickname"] sizeWithFont:self.nameLabel.font constrainedToSize:nameMaxSize lineBreakMode: UILineBreakModeTailTruncation];
        self.nameLabel.text         = [data objectForKey:@"nickname"];
        self.nameLabel.frame = CGRectMake(MIDDLE_COLUMN_OFFSET +3, 7, nameSize.width + SUMMARY_PADDING, nameSize.height);
        self.genderView.frame = CGRectMake(MIDDLE_COLUMN_OFFSET + nameSize.width +10, 10.5, 15, 15);
    }else{
        [self.nameLabel removeFromSuperview];
        [self.genderView removeFromSuperview];
    }
    
    
    ///// signature
    
    NSString * signatureString = [data objectForKey:@"signature"];
    
    if ([signatureString length] != 0 && signatureString != nil ) {
        CGSize summaryMaxSize = CGSizeMake(SUMMARY_WIDTH, LABEL_HEIGHT*2);
        CGFloat _labelHeight;
        CGSize signatureSize = [signatureString sizeWithFont:self.signatureLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
        if (signatureSize.height > LABEL_HEIGHT) {
            _labelHeight = 10.0;
        }else {
            _labelHeight = 20.0;
        }
        self.signatureLabel.text = signatureString ;
        self.signatureLabel.frame = CGRectMake(310 - signatureSize.width - SUMMARY_PADDING, _labelHeight, signatureSize.width + SUMMARY_PADDING, signatureSize.height+SUMMARY_PADDING);
    }else{
        [self.signatureLabel removeFromSuperview];
    }
    
    
}

- (NSString *)distanceDisplay:(CLLocationDistance)_distance
{
    
    CLLocationDistance distance = _distance;
    
    NSString *distanceString = @"";
    if ((int)floor(distance) == 0) {
        distanceString = T(@"就在这");
    } else if ((int)floor(distance) < 1000) {   // less than 1KM，count by m
        distanceString = [NSString stringWithFormat:T(@"%.0f米"), distance];
    } else if ((int)floor(distance) < 50000) { // less than 50KM，count by KM,show decimals
        distanceString = [NSString stringWithFormat:T(@"%.1f公里"), distance / 1000.0f];
    } else if ((int)floor(distance) < 1000000) { // less than 100KM，count by KM, NOT show decimals
        distanceString = [NSString stringWithFormat:T(@"%.0f公里"), distance / 1000.0f];
    } else {
        distanceString = T(@"太远了"); // more than 1000KM，count by KM,too for
    }
    
    return distanceString;
}

//-(void)drawRect:(CGRect)rect
//{
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    
//    /* background iamge */
//    UIImage *backView = [UIImage imageNamed:@"cell_bg.png"];
//    CGContextDrawImage(ctx, CGRectMake(0, 0 , CELL_W, CELL_H), [backView CGImage]);
//    
//    /* avator mask */
//    CGContextRef c = CreateBitmapContext(50, 50);
//    CGContextSetRGBFillColor(c, 1, 1, 1, 1.0f);
//    CGContextFillEllipseInRect(c, CGRectMake(0, 0, 50, 50));
//    CGImageRef mask = CGBitmapContextCreateImage(c);
//    CGContextRelease(c);
//    
//    /* avator graphics context */
//    c = CreateBitmapContext(50, 50);
//    CGContextClipToMask(c, CGRectMake(0, 0, 50, 50), mask);
//    CGImageRelease(mask);
//    CGContextDrawImage(c, CGRectMake(0, 0, 50, 50), [self.avatarImage CGImage]);
//    CGImageRef newAvantor = CGBitmapContextCreateImage(c);
//    CGContextRelease(c);
//
//}


/* this function is steal from Apple            */
/* see http://bit.ly/HRCud6                     */
/* section Creating a Bitmap Graphics Context   */
static CGContextRef
CreateBitmapContext (int pixelsWide, int pixelsHigh)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    bitmapBytesPerRow   = pixelsWide * 4;
    bitmapByteCount     = bitmapBytesPerRow * pixelsHigh;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    bitmapData = malloc(bitmapByteCount);
    bzero(bitmapData, bitmapByteCount);
    if (bitmapData == NULL) {
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedLast);
    if (context== NULL) {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease(colorSpace);
    return context;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
