//
//  Avatar.h
//  iMedia
//
//  Created by Xiaosi Li on 10/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DataTransformer.h"

@class Me;


@interface Avatar : NSManagedObject

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSNumber * sequence;
@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Me *me;

@end
