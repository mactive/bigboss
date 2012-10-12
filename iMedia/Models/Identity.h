//
//  Identity.h
//  iMedia
//
//  Created by Xiaosi Li on 10/12/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Identity : NSManagedObject

@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSString * ePostalID;

@end
