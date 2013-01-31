//
//  Information.h
//  iMedia
//
//  Created by Xiaosi Li on 11/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum _InformationType
{
    WinnerCodeFromShake = 1,
    LastMessageFromServer = 2
} InformationType;


@interface Information : NSManagedObject

@property (nonatomic) u_int16_t type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSDate * createdOn;

@end
