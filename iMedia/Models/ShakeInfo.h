//
//  ShakeInfo.h
//  iMedia
//
//  Created by Xiaosi Li on 11/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ShakeInfo : NSManagedObject

@property (nonatomic, retain) NSDate * lastShakeDate;
@property (nonatomic, retain) NSNumber * daysContinued;

@end
