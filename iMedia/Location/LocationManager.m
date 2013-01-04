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
@property (nonatomic, strong) CLLocation *lastLocation;
@end

@implementation LocationManager

@synthesize lastLocation = _lastLocation;
@synthesize isAllowed = _isAllowed;
@synthesize pastLocations = _pastLocations;

+ (LocationManager *)sharedInstance {
    static LocationManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[LocationManager alloc] init];
    });
    
    return _sharedClient;
}

- (CLLocation *)location
{
    if (_manager) {
        return _manager.location;
    } else {
        [self initLocationManager];
        return _manager.location;
    }
}
- (void)setMe:(Me *)me
{
    _me = me;
    if (_manager) {
        _me.lastGPSUpdated = _manager.location.timestamp;
        _me.lastGPSLocation = [NSString stringWithFormat:@"%f,%f", _manager.location.coordinate.latitude, _manager.location.coordinate.longitude];
        
        [[AppNetworkAPIClient sharedClient] updateLocation:_manager.location.coordinate.latitude andLongitude:_manager.location.coordinate.longitude];
    } else {
        _me.lastGPSLocation = @"";
        _me.lastGPSUpdated = nil;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        if (([CLLocationManager locationServicesEnabled] == YES) && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
            self.isAllowed = YES;
        }else{
            self.isAllowed = NO;
        }
        [self initLocationManager];
        _pastLocations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) initLocationManager
{
    _manager = [[CLLocationManager alloc] init];
    _manager.delegate = self;
    _manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    _manager.distanceFilter = 100;
    _lastLocation = _manager.location;
    
    [_manager startUpdatingLocation];
    
    _significantChangeManager = [[CLLocationManager alloc] init];
    _significantChangeManager.delegate = self;
    _significantChangeManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    //[_significantChangeManager startMonitoringSignificantLocationChanges];
    

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

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ([CLLocationManager locationServicesEnabled] == YES && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        self.isAllowed = YES;
        _lastLocation = _manager.location;
    }else{
        self.isAllowed = NO;
    }
}

@end
