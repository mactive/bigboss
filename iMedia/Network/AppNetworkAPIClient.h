//
//  AppNetworkAPIClient.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AFHTTPClient.h"

//@class Channel;
@class Me;
@class Avatar;
@class Identity;

extern NSString *const kXMPPmyJID;
extern NSString *const kXMPPmyJIDPassword;
extern NSString *const kXMPPmyPassword;
extern NSString *const kXMPPmyUsername;

#define GET_CONFIG_PATH         @"/base/getconfig/"
#define LOGIN_PATH              @"/base/applogin/"
#define GET_DATA_PATH           @"/base/getjsondata/"
#define POST_DATA_PATH          @"/base/setdata/"
#define IMAGE_SERVER_PATH       @"/upload/image/"


@interface AppNetworkAPIClient : AFHTTPClient

@property (nonatomic) NSNumber * kNetworkStatus;

+ (AppNetworkAPIClient *)sharedClient;

//- (void)updateChannelInfo:(Channel *)channel withBlock:(void (^)(NSError *error))block;

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)passwd withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)storeImage:(UIImage *)image thumbnail:(UIImage *)thumbnail forMe:(Me *)me andAvatar:(Avatar *)avatar withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)updateIdentity:(Identity *)identity withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)uploadMe:(Me *)me withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)loadImage:(NSString *)urlPath withBlock:(void (^)(UIImage *image, NSError *error))block;

- (void)updateMyChannel:(Me *)me withBlock:(void (^)(id responseObject, NSError *error))block;
- (void)updateMyPresetChannel:(Me *)me withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)uploadRating:(NSString *)rateKey rate:(NSString *)rating andComment:(NSString *)comment withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)reportID:(NSString *)hisGUID myID:(NSString *)myGUID type:(NSString *)type description:(NSString *)desc otherInfo:(NSString *)otherInfo withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)updateLocation:(double)latitude andLongitude:(double)longitude;

- (void)getNearestPeopleWithGender:(NSUInteger)gender andStart:(NSUInteger)start andBlock:(void (^)(id, NSError *))block;

- (BOOL)isConnectable;

@end
