//
//  ImageRemote.h
//  iMedia
//
//  Created by Xiaosi Li on 10/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Identity;

@interface ImageRemote : NSManagedObject

@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * imageThumbnailURL;
@property (nonatomic, retain) NSNumber * sequence;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Identity *owner;

@end
