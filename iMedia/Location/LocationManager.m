//
//  LocationManager.m
//  iMedia
//
//  Created by Xiaosi Li on 10/30/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "LocationManager.h"

@interface LocationManager () <CLLocationManagerDelegate>
{
    CLLocationManager *_manager;
    CLLocationManager *_significantChangeManager;
}

@end

@implementation LocationManager

@synthesize lastLocation;
@synthesize isAllowed;

+ (LocationManager *)sharedInstance {
    static LocationManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[LocationManager alloc] init];
    });
    
    return _sharedClient;
}

- (id)init {
    self = [super init];
    if (self) {
        _manager = [[CLLocationManager alloc] init];
        self.isAllowed = [CLLocationManager locationServicesEnabled];
        _manager.delegate = self;
        _manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _manager.distanceFilter = 100;
        
        [_manager startUpdatingLocation];
        
        _significantChangeManager = [[CLLocationManager alloc] init];
        _significantChangeManager.delegate = self;
        _significantChangeManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [_significantChangeManager startMonitoringSignificantLocationChanges];
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.lastLocation = newLocation;
    if (oldLocation != nil) {
        [self.pastLocations addObject:oldLocation];
    }
    
    NSLog(@"location information received: %@, from old location %@", newLocation, oldLocation);
}

@end
