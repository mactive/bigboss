//
//  LocationManager.h
//  iMedia
//
//  Created by Xiaosi Li on 10/30/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class Me;

@interface LocationManager : NSObject

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) BOOL               isAllowed;

@property (nonatomic, strong) NSMutableArray *pastLocations;

- (void)setMe:(Me *)me;

+ (LocationManager *)sharedInstance;

@end
