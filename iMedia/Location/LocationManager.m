//
//  LocationManager.m
//  iMedia
//
//  Created by Xiaosi Li on 10/30/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "LocationManager.h"
#import "Me.h"
#import "AppNetworkAPIClient.h"

@interface LocationManager () <CLLocationManagerDelegate>
{
    CLLocationManager *_manager;
    CLLocationManager *_significantChangeManager;
    Me                *_me;
}

@end

@implementation LocationManager

@synthesize lastLocation;
@synthesize isAllowed;
@synthesize pastLocations;

+ (LocationManager *)sharedInstance {
    static LocationManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[LocationManager alloc] init];
    });
    
    return _sharedClient;
}

- (void)setMe:(Me *)me
{
    _me = me;
    if (lastLocation != nil) {
        _me.lastGPSUpdated = lastLocation.timestamp;
        _me.lastGPSLocation = [NSString stringWithFormat:@"%f,%f", lastLocation.coordinate.latitude, lastLocation.coordinate.longitude];
        
        [[AppNetworkAPIClient sharedClient] updateLocation:lastLocation.coordinate.latitude andLongitude:lastLocation.coordinate.longitude];
    } else {
        _me.lastGPSLocation = @"";
        _me.lastGPSUpdated = nil;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        _manager = [[CLLocationManager alloc] init];
        self.isAllowed = [CLLocationManager locationServicesEnabled];
        self.pastLocations = [[NSMutableArray alloc] init];
        _manager.delegate = self;
        _manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _manager.distanceFilter = 100;
        self.lastLocation = _manager.location;
        
        [_manager startUpdatingLocation];
        
        _significantChangeManager = [[CLLocationManager alloc] init];
        _significantChangeManager.delegate = self;
        _significantChangeManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
//        [_significantChangeManager startMonitoringSignificantLocationChanges];
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.lastLocation = newLocation;
    if (oldLocation != nil) {
        [self.pastLocations addObject:oldLocation];
    }
    
    if (_me != nil) {
        _me.lastGPSUpdated = newLocation.timestamp;
        _me.lastGPSLocation = [NSString stringWithFormat:@"%f,%f", newLocation.coordinate.latitude, newLocation.coordinate.longitude];
         [[AppNetworkAPIClient sharedClient] updateLocation:newLocation.coordinate.latitude andLongitude:newLocation.coordinate.longitude];
    }
    
   
    
//    NSLog(@"location information received: %@, from old location %@", newLocation, oldLocation);
}

@end
