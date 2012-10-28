//
//  Identity.h
//  iMedia
//
//  Created by Xiaosi Li on 10/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ImageRemote;

@interface Identity : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * ePostalID;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *images;

-(NSArray *)getOrderedImages;
-(NSArray *)getOrderedNonNilImages;
@end

@interface Identity (CoreDataGeneratedAccessors)

- (void)addImagesObject:(ImageRemote *)value;
- (void)removeImagesObject:(ImageRemote *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
