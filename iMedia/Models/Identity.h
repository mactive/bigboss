//
//  Identity.h
//  iMedia
//
//  Created by Xiaosi Li on 11/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "DataTransformer.h"

@class Conversation, ImageRemote;

@interface Identity : NSManagedObject

@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * ePostalID;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSDate * last_serverupdate_on;
@property (nonatomic, retain) NSString * lastGPSLocation;
@property (nonatomic, retain) NSDate * lastGPSUpdated;
@property (nonatomic)           u_int16_t state;
@property (nonatomic, retain) UIImage * thumbnailImage;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic)           u_int16_t type;
@property (nonatomic, retain) NSSet *images;
@property (nonatomic, retain) NSSet *ownedConversations;

-(NSArray *)getOrderedImages;
-(NSArray *)getOrderedNonNilImages;
@end

@interface Identity (CoreDataGeneratedAccessors)

- (void)addImagesObject:(ImageRemote *)value;
- (void)removeImagesObject:(ImageRemote *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

- (void)addOwnedConversationsObject:(Conversation *)value;
- (void)removeOwnedConversationsObject:(Conversation *)value;
- (void)addOwnedConversations:(NSSet *)values;
- (void)removeOwnedConversations:(NSSet *)values;

@end
