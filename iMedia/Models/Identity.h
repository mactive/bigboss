//
//  Identity.h
//  iMedia
//
//  Created by Xiaosi Li on 11/2/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DataTransformer.h"

#define THUMBNAIL_IMAGE_CHANGE_NOTIFICATION  @"Thumbnail_Image_Change_Notification"

@class ImageRemote;

@interface Identity : NSManagedObject

@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * ePostalID;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSString * lastGPSLocation;
@property (nonatomic, retain) NSDate * lastGPSUpdated;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) UIImage  * thumbnailImage;
@property (nonatomic, retain) NSSet *images;
@property (nonatomic, retain) NSDate * last_serverupdate_on;

-(NSArray *)getOrderedImages;
-(NSArray *)getOrderedNonNilImages;

@end

@interface Identity (CoreDataGeneratedAccessors)

- (void)addImagesObject:(ImageRemote *)value;
- (void)removeImagesObject:(ImageRemote *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
