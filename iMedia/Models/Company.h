//
//  Company.h
//  iMedia
//
//  Created by meng qian on 13-1-29.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Me;

@interface Company : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * companyID;
@property (nonatomic, retain) NSString * serverbotJID;
@property (nonatomic)          u_int16_t status;
@property (nonatomic, retain) NSNumber * isPrivate;
@property (nonatomic, retain) NSString * website;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * logo;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) Me *owner;

@end
