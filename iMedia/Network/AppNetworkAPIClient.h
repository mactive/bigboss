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
#define DATA_SERVER_PATH        @"/upload/imagehead/"
#define REGISTER_PATH           @"/base/register/"

@interface AppNetworkAPIClient : AFHTTPClient

@property (nonatomic) NSNumber * kNetworkStatus;
@property (nonatomic) BOOL isLoggedIn;

+ (AppNetworkAPIClient *)sharedClient;

//- (void)updateChannelInfo:(Channel *)channel withBlock:(void (^)(NSError *error))block;

- (void)loginWithRetryCount:(NSInteger)count username:(NSString *)username andPassword:(NSString *)passwd withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)storeImage:(UIImage *)image thumbnail:(UIImage *)thumbnail forMe:(Me *)me andAvatar:(Avatar *)avatar withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)updateIdentity:(Identity *)identity withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)uploadMe:(Me *)me withBlock:(void (^)(id responseObject, NSError *error))block;
- (void)uploadLog:(NSData *)log withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)loadImage:(NSString *)urlPath withBlock:(void (^)(UIImage *image, NSError *error))block;

- (void)updateMyChannel:(Me *)me withBlock:(void (^)(id responseObject, NSError *error))block;
- (void)updateMyPresetChannel:(Me *)me withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)uploadRating:(NSString *)rateKey rate:(NSString *)rating andComment:(NSString *)comment withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)reportID:(NSString *)hisGUID myID:(NSString *)myGUID type:(NSString *)type description:(NSString *)desc otherInfo:(NSString *)otherInfo withBlock:(void (^)(id responseObject, NSError *error))block;

- (void)updateLocation:(double)latitude andLongitude:(double)longitude;

- (void)getNearestPeopleWithGender:(NSUInteger)gender start:(NSUInteger)start latitude:(double)latitude longitude:(double)longitude andBlock:(void (^)(id, NSError *))block;
// 用户注册
- (void)registerWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(void (^)(id responseObject, NSError *error))block;

// op11 频道信息
- (void)getChannelListWithBlock:(void (^)(id, NSError *))block;
// op12 是否中奖
- (void)getShakeInfoWithBlock:(void (^)(id, NSError *))block;
// op13 签到操作，不需要参数
- (void)sendCheckinMessageWithBlock:(void (^)(id, NSError *))block;
// op14 获取签到奖品列表
- (void)getCheckinInfoWithBlock:(void (^)(id, NSError *))block;
// op15 获取摇一摇活动列表
- (void)getShakeDashboardInfoWithBlock:(void (^)(id, NSError *))block;

// op33
- (void)getCompanyWithName:(NSString *)name withBlock:(void (^)(id, NSError *))block;
// op35 公司分类列表 分类名称, 数量
- (void)getCompanyCategoryWithBlock:(void (^)(id, NSError *))block;
// op37 按分类请求公司 codename
- (void)getCompanyWithCategory:(NSString *)codename withBlock:(void(^)(id, NSError *))block;
// op39 公司的详细信息 by cid
- (void)getcompanyWithCatID:(NSString *)catID withBlock:(void(^)(id, NSError *))block;

// op22 上传devicetoken
- (void)postDeviceToken;


// op16 获取地址
- (void)getWinnerInfoWithBlock:(void (^)(id, NSError *))block;
- (void)updateWinnerName:(NSString *)name andPhone:(NSString *)phone andPriceType:(NSString *)priceType andAddress:(NSString *)address WithBlock:(void (^)(id, NSError *))block;

- (BOOL)isConnectable;

@end
