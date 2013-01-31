//
//  AppNetworkAPIClient.m
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AppNetworkAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "AFImageRequestOperation.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"
#import "NSData+Godzippa.h"
#import "ServerDataTransformer.h"
#import "DDLog.h"
#import "UIImage+ProportionalFill.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

#import "Avatar.h"
#import "Identity.h"
#import "User.h"
#import "Channel.h"
#import "ModelHelper.h"
#import "Me.h"
#import "ImageRemote.h"
#import "AppDelegate.h" 
#import "ContactListViewController.h"
#import "XMPPJID.h"
#import <Foundation/NSTimer.h>
#import "NSDate-Utilities.h"

#define USE_UYUN_SERVICE YES
#ifdef USE_UYUN_SERVICE
#import "UpYun.h"
#endif

//static NSString * const kAppNetworkAPIBaseURLString = @"http://192.168.1.104:8000/";
static NSString * const kAppNetworkAPIBaseURLString = @"http://c.wingedstone.com:8000/";


NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyJIDPassword = @"kXMPPmyJIDPassword";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";
NSString *const kXMPPmyUsername = @"kXMPPmyUsername";


#ifdef USE_UYUN_SERVICE
@interface AppNetworkAPIClient () <UpYunDelegate>
{
    NSLock *_imageQueueLock;
    NSLock *_queuedOperationLock;
    NSLock *_upYunLock;
}

@property (nonatomic, strong) NSMutableDictionary *imageUploadOperationsInProgress;
@property (nonatomic, strong) id storedLoginResponseObject;
@property (nonatomic, strong) NSMutableArray *queuedOperations;
@property (nonatomic, strong) NSMutableDictionary *upYunRequests;
@property (nonatomic, strong) AFHTTPRequestOperation *updateLocationOperation;
@property (nonatomic, strong) NSDate* lastLoginDate;

- (void)networkChangeReceived:(NSNotification *)notification;
- (void)upYun:(UpYun *)upYun requestDidFailWithError:(NSError *)error;
- (void)upYun:(UpYun *)upYun requestDidSucceedWithResult:(id)result;

@end

#else
@interface AppNetworkAPIClient ()

@property (nonatomic, strong) NSMutableDictionary *imageUploadOperationsInProgress;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic, strong) NSMutableArray *queuedOperations;
@property (nonatomic, strong) AFHTTPRequestOperation *updateLocationOperation;
@property (nonatomic, strong) NSDate* lastLoginDate;

- (void)networkChangeReceived:(NSNotification *)notification;

@end
#endif

@implementation AppNetworkAPIClient

@synthesize kNetworkStatus;
@synthesize imageUploadOperationsInProgress;
@synthesize isLoggedIn = _isLoggedIn;
@synthesize storedLoginResponseObject;
@synthesize queuedOperations;
@synthesize updateLocationOperation;
@synthesize lastLoginDate;
#ifdef USE_UYUN_SERVICE
@synthesize upYunRequests;
#endif  

+ (AppNetworkAPIClient *)sharedClient {
    static AppNetworkAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AppNetworkAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAppNetworkAPIBaseURLString]];
        [_sharedClient setDefaultHeader:@"Accept-Language" value:nil];
    });
    
    return _sharedClient;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

-(void)setIsLoggedIn:(BOOL)isLoggedIn
{
    _isLoggedIn = isLoggedIn;
    
    [_queuedOperationLock lock];
    if (isLoggedIn && [self.queuedOperations count] > 0) {
        [[AppNetworkAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:self.queuedOperations progressBlock:nil completionBlock:nil];
    
        [self.queuedOperations removeAllObjects];
    }
    [_queuedOperationLock unlock];
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    self.imageUploadOperationsInProgress = [[NSMutableDictionary alloc] initWithCapacity:5];
    self.isLoggedIn = NO;
    self.lastLoginDate = [NSDate dateWithTimeIntervalSince1970:0];
    self.queuedOperations = [[NSMutableArray alloc] initWithCapacity:5];
    self.updateLocationOperation = nil;
    
    _upYunLock = [[NSLock alloc] init];
    _imageQueueLock = [[NSLock alloc] init];
    _queuedOperationLock = [[NSLock alloc] init];


#ifdef USE_UYUN_SERVICE
    self.upYunRequests = [[NSMutableDictionary alloc] initWithCapacity:5];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChangeReceived:)
                                                 name:AFNetworkingReachabilityDidChangeNotification object:nil];

    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (void)dealloc
{
    NotificationsUnobserve();
}


-(void)loginWithRetryCount:(NSInteger)count username:(NSString *)username andPassword:(NSString *)passwd withBlock:(void (^)(id, NSError *))block
{
    NSDate *oneDayAgo = [NSDate dateWithDaysBeforeNow:1];
    if (self.isLoggedIn && ([self.lastLoginDate isLaterThanDate:oneDayAgo])) {
        if (block) {
            block (self.storedLoginResponseObject, nil);
        }
        return;
    }
    
    if (count < 0) {
        // retry fails we don't have not work
        DDLogError(@"Cannot login after multiple retries");
        return;
    }
    
    self.isLoggedIn = NO;
    
    NSMutableURLRequest *loginRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_CONFIG_PATH parameters:nil];
    AFJSONRequestOperation * loginOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:loginRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        DDLogVerbose(@"get config JSON received: %@", JSON);
        [[NSUserDefaults standardUserDefaults] setObject:[JSON valueForKey:@"logintypes"] forKey:@"logintypes"];
        [[NSUserDefaults standardUserDefaults] setObject:[JSON valueForKey:@"csrfmiddlewaretoken"] forKey:@"csrfmiddlewaretoken"];
        [[NSUserDefaults standardUserDefaults] setObject:[JSON valueForKey:@"ios_ver"] forKey:@"ios_ver"];
        
        NSDictionary *loginDict = [NSDictionary dictionaryWithObjectsAndKeys: username, @"username", passwd, @"password", [JSON valueForKey:@"csrfmiddlewaretoken"], @"csrfmiddlewaretoken", nil];
        NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"POST" path:LOGIN_PATH parameters:loginDict];
        AFJSONRequestOperation *loginOperation2 = [AFJSONRequestOperation JSONRequestOperationWithRequest:postRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            DDLogVerbose(@"login JSON received: %@", JSON);
            
            NSString* status = [JSON valueForKey:@"status"];
            if ([status isEqualToString:@"success"]) {
                
                NSString* jid = [JSON valueForKey:@"jid"];
                NSString *jPassword = [JSON valueForKey:@"jpass"];
                
                [[NSUserDefaults standardUserDefaults] setObject:jid forKey:kXMPPmyJID];
                [[NSUserDefaults standardUserDefaults] setObject:jPassword forKey:kXMPPmyJIDPassword];
                [[NSUserDefaults standardUserDefaults] setObject:username forKey:kXMPPmyUsername];
                [[NSUserDefaults standardUserDefaults] setObject:passwd forKey:kXMPPmyPassword];
                
                self.storedLoginResponseObject = JSON;
                
                if (block ) {
                    block(JSON, nil);
                }
                
                self.isLoggedIn = YES;
                self.lastLoginDate = [NSDate date];
            } else {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                if (block) {
                    block(JSON, error);
                }
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            DDLogVerbose(@"login failed: %@", error);
            if (block) {
                block(nil, error);
            }
            
            [self loginWithRetryCount:(count -1) username:username andPassword:passwd withBlock:block];

        }];
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:loginOperation2];
            
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DDLogVerbose(@"get config failed: %@", error);
        if (block) {
            block(nil, error);
        }
        [self loginWithRetryCount:(count-1) username:username andPassword:passwd withBlock:block];
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:loginOperation];
}

//  用户注册
- (void)registerWithUsername:(NSString *)username andPassword:(NSString *)password withBlock:(void (^)(id , NSError *))block
{
    
    NSMutableURLRequest *getconfigRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_CONFIG_PATH parameters:nil];
    AFJSONRequestOperation *getconfigOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:getconfigRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DDLogVerbose(@"getconfig JSON received: %@", JSON);
        NSDictionary *registerDict = [NSDictionary dictionaryWithObjectsAndKeys: username, @"u", password, @"p", [JSON valueForKey:@"csrfmiddlewaretoken"], @"csrfmiddlewaretoken",@"iOS App",@"s", nil];

        NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"POST" path:REGISTER_PATH parameters:registerDict];

        AFJSONRequestOperation *registerOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:postRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            //
            NSString* status = [JSON valueForKey:@"status"];
            
            DDLogVerbose(@"register JSON received: %@", JSON);
            if ([status isEqualToString:@"0"]) {
                [[NSUserDefaults standardUserDefaults] setObject:username forKey:kXMPPmyUsername];

                if (block ) {
                    block(JSON, nil);
                }
            }else{
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                if (block) {
                    block(JSON, error);
                }
            }

        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            DDLogVerbose(@"register failed: %@", error);
            if (block) {
                block(nil, error);
            }
        }];
        
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:registerOperation];


    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DDLogVerbose(@"getconfig failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getconfigOperation];


}

#ifdef USE_UYUN_SERVICE
- (void)upYun:(UpYun *)upYun requestDidFailWithError:(NSError *)error
{
    DDLogError(@"upload image failed: %@", error);
    
    [_upYunLock lock];
    NSDictionary *savedObjects = [self.upYunRequests objectForKey:upYun.name];
    [_upYunLock unlock];
    
    void (^block)(id, NSError *) ;
    block = [savedObjects objectForKey:@"block"];
    if (block) {
        block(nil, error);
    }
}

- (void)upYun:(UpYun *)upYun requestDidSucceedWithResult:(id)result
{
    DDLogInfo(@"upload image succeeded: %@", result);
    
    [_upYunLock lock];
    NSDictionary *savedObjects = [self.upYunRequests objectForKey:upYun.name];
    [_upYunLock unlock];
    
    // succeed, save all the objects
    Avatar *avatar = [savedObjects objectForKey:@"avatar"];
    Me*  me = [savedObjects objectForKey:@"me"];
    void (^block)(id, NSError *) ;
    block = [savedObjects objectForKey:@"block"];
    
    UIImage *image = [savedObjects objectForKey:@"image"];
    UIImage *thumbnail = [savedObjects objectForKey:@"thumbnail"];
    
    NSString *url = [NSString stringWithFormat:@"http://bigbossapp.b0.upaiyun.com%@?%.0f", upYun.name, [[NSDate date] timeIntervalSince1970]];
    NSString *thumbnailURL = [NSString stringWithFormat:@"http://bigbossapp.b0.upaiyun.com%@!tm?%.0f", upYun.name, [[NSDate date] timeIntervalSince1970]];
    
    avatar.image = image;
    avatar.thumbnail = thumbnail;
    avatar.imageRemoteThumbnailURL = thumbnailURL;
    avatar.imageRemoteURL = url;
    
    if (avatar.sequence.intValue == 1) {
        me.avatarURL = url;
        me.thumbnailURL = thumbnailURL;
        me.thumbnailImage = avatar.thumbnail;
    }
    
    if (block) {
        block(result, nil);
    }

}
#endif

- (void)storeImage:(UIImage *)image thumbnail:(UIImage *)thumbnail forMe:(Me *)me andAvatar:(Avatar *)avatar withBlock:(void (^)(id, NSError *))block
{

#ifdef USE_UYUN_SERVICE
    
    UpYun *uy = [[UpYun alloc] init];
    uy.delegate = self;
    uy.expiresIn = 100;
    uy.bucket = @"bigbossapp";
    uy.passcode = @"2Q7/2EDFIVh00kxhZE4D62lH/2M=";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    //    [params setObject:@"0,1000" forKey:@"content-length-range"];
    //    [params setObject:@"png" forKey:@"allow-file-type"];
    uy.params = params;
    
    NSString *saveKey = nil;
    if (StringHasValue(avatar.imageRemoteURL)) {
        NSURL *url = [NSURL URLWithString:avatar.imageRemoteURL];
        saveKey = [url path];
    } else {
        saveKey = [NSString stringWithFormat:@"/%@/%.0f.jpg", me.guid, [[NSDate date] timeIntervalSince1970]];
    }
    uy.name = saveKey;
    
    [uy uploadImageData:UIImageJPEGRepresentation(image, 1.0) savekey:saveKey];
    
    //void (^handlerCopy)(id, NSError *) ;
    //handlerCopy = Block_copy(block);
    NSDictionary* results = [NSDictionary dictionaryWithObjectsAndKeys:image, @"image", me, @"me", thumbnail, @"thumbnail", avatar, @"avatar", saveKey, @"pathname", [block copy], @"block", nil];
    //Block_release(handlerCopy); // dict will -retain/-release, this balances the copy.
  
    [_upYunLock lock];
    [self.upYunRequests setObject:results forKey:uy.name];
    [_upYunLock unlock];
    
    return;

    
#else
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys: csrfToken, @"csrfmiddlewaretoken", nil];
    NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] multipartFormRequestWithMethod:@"POST" path:IMAGE_SERVER_PATH parameters:paramDict constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 1.0) name:@"image" fileName:@"testimage" mimeType:@"image/jpeg"];
        [formData appendPartWithFileData:UIImageJPEGRepresentation(thumbnail, 1.0) name:@"thumbnail" fileName:@"testimageThumb" mimeType:@"image/jpeg"];
    }];
    
    AFHTTPRequestOperation *operation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:postRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogInfo(@"upload image generated operation: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogError(@"upload image failed generate operation: %@", error);
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"upload image received response: %@", responseObject);
        NSString* url = [responseObject valueForKey:@"image"];
        NSString *thumbnailURL = [responseObject valueForKey:@"thumbnail"];
        
        [_imageQueueLock lock];
        [self.imageUploadOperationsInProgress removeObjectForKey:avatar.sequence];
        [_imageQueueLock unlock];
        
        
        avatar.image = image;
        avatar.thumbnail = thumbnail;
        avatar.imageRemoteThumbnailURL = thumbnailURL;
        avatar.imageRemoteURL = url;
        
        if (avatar.sequence.intValue == 1) {
            me.avatarURL = url;
            me.thumbnailURL = thumbnailURL;
            me.thumbnailImage = avatar.thumbnail;
        }

        if (block) {
            block(responseObject, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"upload image failed: %@", error);
        [_imageQueueLock lock];
        [self.imageUploadOperationsInProgress removeObjectForKey:avatar.sequence];
        [_imageQueueLock unlock];
        
        if (block) {
            block(nil, error);
        }
    }];
    
    DDLogInfo(@"http request: %@", operation);
    [_imageQueueLock lock];
    [self.imageUploadOperationsInProgress setObject:operation forKey:avatar.sequence];
    [_imageQueueLock unlock];
    
    
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:operation];
        [_queuedOperationLock unlock];
    }
   
#endif
    
}

- (void)updateIdentity:(Identity *)identity withBlock:(void (^)(id, NSError *))block
{
    DDLogInfo(@"Update Identity: %@", identity.ePostalID);
    
    [XFox logEvent:TIMER_UPDATE_IDENTITY withParameters:[NSDictionary dictionaryWithObjectsAndKeys:identity.guid, @"guid", nil] timed:YES];
    
    // define a minimum time period to throttle call to server
    const NSTimeInterval min_time_gap = -10;
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:min_time_gap];
    if ([now compare:identity.last_serverupdate_on] == NSOrderedAscending && (block == nil)) {
        [XFox endTimedEvent:TIMER_UPDATE_IDENTITY withParameters:nil];
        return;
    }
    
    // proceed to make server updates
    NSDictionary *getDict ;
    if (identity.guid != nil && ![identity.guid isEqualToString:@""]) {
        getDict = [NSDictionary dictionaryWithObjectsAndKeys: identity.guid, @"guid", @"1", @"op", nil];
    } else {
        getDict = [NSDictionary dictionaryWithObjectsAndKeys:identity.ePostalID , @"jid", @"2", @"op", nil];
    }
    
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFJSONRequestOperation *getOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:getRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
//        DDLogVerbose(@"get user %@ data received: %@", identity, JSON);
        
        NSString* type = [JSON valueForKey:@"type"];
        
        if ([type isEqualToString:@"user"] || [type isEqualToString:@"channel"]) {
            // compare the incoming new user data with old user data. if thumbnailURL is the same
            // then don't load the image
            NSString *thumbnailURL = [ServerDataTransformer getThumbnailFromServerJSON:JSON];
            if (thumbnailURL == nil || [thumbnailURL isEqualToString:@""]) {
                identity.thumbnailImage = nil;
#warning TODO: set to the global placeholder
            } else if (thumbnailURL != identity.thumbnailURL) {
                NSURL *url = [NSURL URLWithString:thumbnailURL];
                
                // Try twice to load the image
                AFImageRequestOperation *imageOper = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:url] imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    identity.thumbnailImage = image;
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    DDLogError(@"Failed to get thumbnail at first time url: %@, response :%@, tryting again", thumbnailURL, JSON);
                    AFImageRequestOperation  *imageOperAgain = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:url] imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                        identity.thumbnailImage = image;
                        
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        DDLogError(@"ERROR: Failed again to get thumbnail at first time url: %@, response :%@", thumbnailURL, JSON);
                    }];
                    
                    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:imageOperAgain];
                }];
                
                [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:imageOper];
            }
            
            
            [[ModelHelper sharedInstance] populateIdentity:identity withJSONData:JSON];
            
            if (identity.state == IdentityStatePendingServerDataUpdate) {
                identity.state = IdentityStateActive;
            }
            identity.last_serverupdate_on = [NSDate date];

            // Fix some inconsistent issues if it exists
            
            // if identity is Me, we need to check local avatar against the server. If local doesn't have the image
            // we need to download and save.
            if ([identity isKindOfClass:[Me class]]) {
                Me *me = (Me *)identity;
                NSArray *avatarArray = [me getOrderedAvatars];
                for (int i = 0; i < [avatarArray count] ; i++) {
                    Avatar *avatar = [avatarArray objectAtIndex:i];
                    // only update image if not exist
                    if (avatar.image == nil && avatar.imageRemoteURL != nil && ![avatar.imageRemoteURL isEqualToString:@""] ) {
                        AFImageRequestOperation *oper = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:avatar.imageRemoteURL]] success:^(UIImage *image) {
                            DDLogInfo(@"load me thumbnail image received response: %@", JSON);
                            avatar.image = image;
                            avatar.thumbnail= [image imageCroppedToFitSize:CGSizeMake(75, 75)];
                        }];
                        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:oper];
                    }
                }
            }
            
            
            if (block) {
                block (JSON, nil);
            }
            
            [[self appDelegate] saveContextInDefaultLoop];
            [[self appDelegate].contactListController contentChanged];
            
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
        
        [XFox endTimedEvent:TIMER_UPDATE_IDENTITY withParameters:nil];

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        //
        DDLogVerbose(@"error received: %@", error);
        
        if (block) {
            block(nil, error);
        }
        
        [XFox endTimedEvent:TIMER_UPDATE_IDENTITY withParameters:nil];

    }];
    
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:getOperation];
        [_queuedOperationLock unlock];
    }

}

-(void)uploadMe:(Me *)me withBlock:(void (^)(id, NSError *))block
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              csrfToken, @"csrfmiddlewaretoken",
                              @"3", @"op", 
                              me.avatarURL, @"avatar",
                              me.thumbnailURL, @"thumbnail",
                              me.cell, @"cell",
                              me.signature, @"signature",
                              me.hometown, @"hometown",
                              me.displayName, @"nickname",
                              me.gender, @"gender",
                              me.selfIntroduction, @"self_introduction",
                              me.career, @"career",
                              [ServerDataTransformer dateStrfromNSDate:me.birthdate], @"birthdate",
                              [ServerDataTransformer datetimeStrfromNSDate:me.lastGPSUpdated], @"last_gps_updated",
                              me.lastGPSLocation, @"last_gps_loc",
                              me.sinaWeiboID , @"sina_weibo_id",
                              me.alwaysbeen , @"alwaysbeen",
                              me.interest , @"interest",
                              me.school , @"school",
                              me.company , @"company",
                                nil];
    NSArray *imagesURLArray = [me getOrderedAvatars];
    for (int i = 0; i < [imagesURLArray count]; i++) {
        Avatar* avatar = [imagesURLArray objectAtIndex:i];
        NSString *key1 = [NSString stringWithFormat:@"avatar%d", (i+1)];
        NSString *key2 = [NSString stringWithFormat:@"thumbnail%d", (i+1)];
        [postDict setObject:avatar.imageRemoteURL forKey:key1];
        [postDict setObject:avatar.imageRemoteThumbnailURL forKey:key2];
    }
    
    NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"POST" path:POST_DATA_PATH parameters:postDict];
    
    // no gzip in local network
//    NSRange range = [kAppNetworkAPIBaseURLString rangeOfString:@"http://192.168"];
//    if (range.location == NSNotFound) {
//        NSData *originalData = [postRequest HTTPBody];
//        NSData *compressedData = [originalData dataByGZipCompressingWithError:nil];
//        [postRequest setHTTPBody:compressedData];
//    }
    
    AFHTTPRequestOperation *operation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:postRequest success:nil failure:nil];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"upload me received response: %@", responseObject);
        NSString* status = [responseObject valueForKey:@"status"];
        if ([status isEqualToString:@"success"]) {
            if (block ) {
                block(responseObject, nil);
            }
        }
        else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"upload me failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
    
    DDLogInfo(@"http request: %@", operation);
    
    [_imageQueueLock lock];
    NSArray *imageUploadingOpers = [self.imageUploadOperationsInProgress allValues];
    for (int i = 0; i < [imageUploadOperationsInProgress count]; i++) {
        [operation addDependency:[imageUploadingOpers objectAtIndex:i]];
    }
    [_imageQueueLock unlock];
    
        
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:operation];
        [_queuedOperationLock unlock];
    }

    
}

- (void)loadImage:(NSString *)urlPath withBlock:(void (^)(UIImage *, NSError *))block
{
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlPath]] imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (block) {
            block (image, nil);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
}
// 我的频道
- (void)updateMyChannel:(Me *)me withBlock:(void (^)(id, NSError *))block
{
    // proceed to make server updates
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: me.guid, @"guid", @"8", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFJSONRequestOperation *getOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:getRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        DDLogVerbose(@"get channel %@ data received: %@", me, JSON);
        
        NSString* type = [JSON valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (JSON, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) {
            block (nil, error);
        }
    }];
    
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:getOperation];
        [_queuedOperationLock unlock];
    }
}
// 默认订阅
- (void)updateMyPresetChannel:(Me *)me withBlock:(void (^)(id, NSError *))block
{
    // proceed to make server updates
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"9", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFJSONRequestOperation *getOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:getRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        DDLogVerbose(@"get preset channel %@ data received: %@", me, JSON);
        
        NSString* type = [JSON valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (JSON, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) {
            block (nil, error);
        }
    }];
    
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:getOperation];
        [_queuedOperationLock unlock];
    }
    
}

- (void)uploadRating:(NSString *)rateKey rate:(NSString *)rating andComment:(NSString *)comment withBlock:(void (^)(id, NSError *))block
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     csrfToken, @"csrfmiddlewaretoken",
                                     @"6", @"op",
                                     rateKey, @"ratekey",
                                     rating, @"rate",
                                     comment, @"ratemore",
                                     nil];
    
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"upload rating received response: %@", responseObject);
        NSString* status = [responseObject valueForKey:@"status"];
        if ([status isEqualToString:@"success"]) {
            if (block ) {
                block(responseObject, nil);
            }
        }
        else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"upload rating failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)reportID:(NSString *)hisGUID myID:(NSString *)myGUID type:(NSString *)type description:(NSString *)desc otherInfo:(NSString *)otherInfo withBlock:(void (^)(id, NSError *))block
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     csrfToken, @"csrfmiddlewaretoken",
                                     @"7", @"op",
                                     hisGUID, @"guid",
                                     myGUID, @"myguid",
                                     type, @"type",
                                     desc, @"note",
                                     otherInfo, @"other_info",
                                     nil];
    DDLogInfo(@"%@",postDict);
    
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"upload report received response: %@", responseObject);
        NSString* status = [responseObject valueForKey:@"status"];
        if ([status isEqualToString:@"success"]) {
            if (block ) {
                block(responseObject, nil);
            }
        }
        else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"upload rating failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)updateLocation:(double)latitude andLongitude:(double)longitude
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     csrfToken, @"csrfmiddlewaretoken",
                                     @"20", @"op",
                                     [NSString stringWithFormat:@"%f", latitude], @"lat",
                                     [NSString stringWithFormat:@"%f", longitude], @"lon",
                                     nil];
    
    NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"POST" path:POST_DATA_PATH parameters:postDict];
    self.updateLocationOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:postRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.updateLocationOperation = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.updateLocationOperation = nil;
    }];
    
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:self.updateLocationOperation];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:self.updateLocationOperation   ];
        [_queuedOperationLock unlock];
    }
}

- (void)getNearestPeopleWithGender:(NSUInteger)gender start:(NSUInteger)start latitude:(double)latitude longitude:(double)longitude andBlock:(void (^)(id, NSError *))block
{
    [XFox logEvent:TIMER_GET_NEARBY_USER timed:YES];
    
    NSString * genderString = [NSString stringWithFormat:@"%i",gender];
    NSString * startString = [NSString stringWithFormat:@"%i",start];
    NSString * latitudeStr = [NSString stringWithFormat:@"%f", latitude];
    NSString * longitudeStr = [NSString stringWithFormat:@"%f", longitude];
    

    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"10", @"op", latitudeStr, @"lat", longitudeStr, @"lon", startString, @"start", genderString, @"gender", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
       // DDLogVerbose(@"get nearest user data received: %@", responseObject);
        
        [XFox endTimedEvent:TIMER_GET_NEARBY_USER withParameters:nil];
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        [XFox endTimedEvent:TIMER_GET_NEARBY_USER withParameters:nil];
        if (block) {
            block (nil, error);
        }
    }];
    
    if (self.updateLocationOperation != nil) {
        [getOperation addDependency:self.updateLocationOperation];
    }
    
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:getOperation];
        [_queuedOperationLock unlock];
    }

    
}

// 我的公司
- (void)getMyCompanyWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"31", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient]HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogVerbose(@"getMyCompanyWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}


// 关键字搜索公司
- (void)getCompanyWithName:(NSString *)name withBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: name, @"kw", @"33", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient]HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogVerbose(@"getCompanyWithName: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];

}

// op 35 获取公司分类
- (void)getCompanyCategoryWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"35", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient]HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogVerbose(@"getCompanyCategoryWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}

// op 37 获取公司分类
- (void)getCompanyWithCategory:(NSString *)codename withBlock:(void(^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys:codename, @"cg", @"37", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient]HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogVerbose(@"getCompanyWithCategory: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];

}

// op 39 获取公司详情
- (void)getCompanyWithCompanyID:(NSString *)companyID withBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys:companyID, @"cid", @"39", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient]HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogVerbose(@"getCompanyWithCompanyID: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
    
}

// op 41
- (void)getCompanyMemberWithCompanyID:(NSString *)companyID andStart:(NSUInteger)start withBlock:(void(^)(id, NSError *))block
{
    NSString *startString = [NSString stringWithFormat:@"%d",start];
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys:companyID, @"cid", startString, @"start", @"41", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient]HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogVerbose(@"getCompanyMemberWithCompanyID: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                if ([@"fail" isEqualToString:type]) {
                    NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                    block (nil, error);
                }else{
                    NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:500 userInfo:nil];
                    block (nil, error);
                }

            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}

// op43 获取离线消息 by cid start
- (void)getLastMessageWithBlock:(void(^)(id, NSError *))block{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys:@"43", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient]HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogVerbose(@"getLastMessageWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                if ([@"fail" isEqualToString:type]) {
                    NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                    block (nil, error);
                }else{
                    NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:500 userInfo:nil];
                    block (nil, error);
                }
                
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block (nil, error);
        }
    }];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];

}


// op 30 follow company
- (void)followCompanyWithCompanyID:(NSString *)companyID withBlock:(void(^)(id, NSError *))block
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     csrfToken, @"csrfmiddlewaretoken",
                                     companyID, @"cid",
                                     @"30", @"op",
                                     nil];
    
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"followCompanyWithCompanyID: %@", responseObject);
        NSString* status = [responseObject valueForKey:@"status"];
        if ([status isEqualToString:@"success"]) {
            if (block ) {
                block(responseObject, nil);
            }
        }
        else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"followCompanyWithCompanyID failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
}
// op 32 unfollow company
- (void)unfollowCompanyWithCompanyID:(NSString *)companyID withBlock:(void(^)(id, NSError *))block
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];

    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     csrfToken, @"csrfmiddlewaretoken",
                                     companyID, @"cid",
                                     @"32", @"op",
                                     nil];
    
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"followCompanyWithCompanyID: %@", responseObject);
        NSString* status = [responseObject valueForKey:@"status"];
        if ([status isEqualToString:@"success"]) {
            if (block ) {
                block(responseObject, nil);
            }
        }
        else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"followCompanyWithCompanyID failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
}


// 频道列表
- (void)getChannelListWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"11", @"op", nil];
    // 11 是频道列表
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"getChannelListWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}

// 频道列表
- (void)getShakeInfoWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"12", @"op", nil];
    // 13 是频道列表
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"getShakeInfoWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"%@",error);
        if (block) {
            block (nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}

// 发送签到列表
- (void)sendCheckinMessageWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"13", @"op", nil];
    // 11 是频道列表
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"sendCheckinMessageWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}

// 签到奖励列表
- (void)getCheckinInfoWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"14", @"op", nil];
    // 11 是频道列表
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"getCheckinInfoWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}

// 摇一摇活动信息
- (void)getShakeDashboardInfoWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"15", @"op", nil];
    
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"getShakeDashboardInfoWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}


// 获得获奖者信息
- (void)getWinnerInfoWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"16", @"op", nil];
    
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"getShakeDashboardInfoWithBlock: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:getOperation];
}

// 设置获奖者信息
- (void)updateWinnerName:(NSString *)name andPhone:(NSString *)phone andPriceType:(NSString *)priceType andAddress:(NSString *)address WithBlock:(void (^)(id, NSError *))block
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     csrfToken, @"csrfmiddlewaretoken",
                                     @"21", @"op",
                                     name, @"name",
                                     phone, @"phone",
                                     address, @"addr",
                                     priceType, @"prize_type",
                                     nil];
    
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"upload winner received response: %@", responseObject);
        NSString* status = [responseObject valueForKey:@"status"];
        if ([status isEqualToString:@"success"]) {
            if (block ) {
                block(responseObject, nil);
            }
        }
        else {
            if (block) {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                block (nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"upload rating failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
}

// op22 上传devicetoken
- (void)postDeviceToken{
    
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    NSString* dToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     csrfToken, @"csrfmiddlewaretoken",
                                     @"22", @"op",
                                     dToken, @"dt",
                                     nil];
    
    NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"POST" path:POST_DATA_PATH parameters:postDict];
    AFHTTPRequestOperation *oper = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:postRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"device successfully uploaded");
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogInfo(@"device failed uploaded");
    }];
    
    if (self.isLoggedIn) {
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:oper];
    } else {
        [_queuedOperationLock lock];
        [self.queuedOperations addObject:oper];
        [_queuedOperationLock unlock];
    }

}


- (void)uploadLog:(NSData *)log withBlock:(void (^)(id, NSError *))block
{
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys: csrfToken, @"csrfmiddlewaretoken", nil];
    
    NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] multipartFormRequestWithMethod:@"POST" path:DATA_SERVER_PATH parameters:paramDict constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:log name:@"ih" fileName:@"flu.gz" mimeType:@"application/octet-stream"];
    }];

    AFHTTPRequestOperation *operation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:postRequest success:nil failure:nil];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (block) {
            block(responseObject, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
}

- (BOOL)isConnectable
{
    if (self.kNetworkStatus.intValue == AFNetworkReachabilityStatusReachableViaWiFi || self.kNetworkStatus.intValue == AFNetworkReachabilityStatusReachableViaWWAN) {
        return YES;
    } else {
        return NO;
    }
}

- (void)networkChangeReceived:(NSNotification *)notification
{
    self.kNetworkStatus = (NSNumber *)[notification.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem];
}
@end
