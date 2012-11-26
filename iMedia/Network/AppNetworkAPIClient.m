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
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
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
#import "UIImage+Resize.h"
#import "XMPPJID.h"

#define USE_UYUN_SERVICE YES
#ifdef USE_UYUN_SERVICE
#import "UpYun.h"
#endif

//static NSString * const kAppNetworkAPIBaseURLString = @"http://192.168.1.104:8000/";//
static NSString * const kAppNetworkAPIBaseURLString = @"http://media.wingedstone.com:8000/";



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
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic, strong) NSMutableArray *queuedOperations;
@property (nonatomic, strong) NSMutableDictionary *upYunRequests;
@property (nonatomic, strong) AFHTTPRequestOperation *updateLocationOperation;

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

- (void)networkChangeReceived:(NSNotification *)notification;

@end
#endif

@implementation AppNetworkAPIClient

@synthesize kNetworkStatus;
@synthesize imageUploadOperationsInProgress;
@synthesize isLoggedIn = _isLoggedIn;
@synthesize queuedOperations;
@synthesize updateLocationOperation;
#ifdef USE_UYUN_SERVICE
@synthesize upYunRequests;
#endif  

+ (AppNetworkAPIClient *)sharedClient {
    static AppNetworkAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AppNetworkAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAppNetworkAPIBaseURLString]];
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
    self.queuedOperations = [[NSMutableArray alloc] initWithCapacity:5];;
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

-(void)loginWithUsername:(NSString *)username andPassword:(NSString *)passwd withBlock:(void (^)(id responseObject, NSError *))block
{
    self.isLoggedIn = NO;
    
    NSMutableURLRequest *loginRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_CONFIG_PATH parameters:nil];
    AFJSONRequestOperation * loginOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:loginRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        DDLogVerbose(@"get config JSON received: %@", JSON);
        [[NSUserDefaults standardUserDefaults] setObject:[JSON valueForKey:@"logintypes"] forKey:@"logintypes"];
        [[NSUserDefaults standardUserDefaults] setObject:[JSON valueForKey:@"csrfmiddlewaretoken"] forKey:@"csrfmiddlewaretoken"];
        
        NSDictionary *loginDict = [NSDictionary dictionaryWithObjectsAndKeys: username, @"username", passwd, @"password", [JSON valueForKey:@"csrfmiddlewaretoken"], @"csrfmiddlewaretoken", nil];
        NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"POST" path:LOGIN_PATH parameters:loginDict];
        AFJSONRequestOperation *loginOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:postRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            DDLogVerbose(@"login JSON received: %@", JSON);
            
            NSString* status = [JSON valueForKey:@"status"];
            if ([status isEqualToString:@"success"]) {
                
                NSString* jid = [JSON valueForKey:@"jid"];
                NSString *jPassword = [JSON valueForKey:@"jpass"];
                
                [[NSUserDefaults standardUserDefaults] setObject:jid forKey:kXMPPmyJID];
                [[NSUserDefaults standardUserDefaults] setObject:jPassword forKey:kXMPPmyJIDPassword];
                [[NSUserDefaults standardUserDefaults] setObject:username forKey:kXMPPmyUsername];
                [[NSUserDefaults standardUserDefaults] setObject:passwd forKey:kXMPPmyPassword];
                
                if (block ) {
                    block(JSON, nil);
                }
                
                self.isLoggedIn = YES;
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

        }];
        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:loginOperation];
            
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DDLogVerbose(@"get config failed: %@", error);
        if (block) {
            block(nil, error);
        }

    }];
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:loginOperation];
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
    
    NSString *url = [NSString stringWithFormat:@"http://wstone.b0.upaiyun.com%@?%.0f", upYun.name, [[NSDate date] timeIntervalSince1970]];
    NSString *thumbnailURL = [NSString stringWithFormat:@"http://wstone.b0.upaiyun.com%@!tm?%.0f", upYun.name, [[NSDate date] timeIntervalSince1970]];
    
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
    uy.bucket = @"wstone";
    uy.passcode = @"MIovWfblZEf/dLP2y9SsNUu3uig=";
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
    // define a minimum time period to throttle call to server
    const NSTimeInterval min_time_gap = -10;
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:min_time_gap];
    if ([now compare:identity.last_serverupdate_on] == NSOrderedAscending) {
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
        
        DDLogVerbose(@"get user %@ data received: %@", identity, JSON);
        
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
                            avatar.thumbnail= [image resizedImageToSize:CGSizeMake(75, 75)];
                        }];
                        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:oper];
                    }
                }
                
            }
            if (identity.state.intValue == IdentityStatePendingServerDataUpdate) {
                identity.state = [NSNumber numberWithInt:IdentityStateActive];
            }
            [[self appDelegate].contactListController contentChanged];
            
            identity.last_serverupdate_on = [NSDate date];
            
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
        //
        DDLogVerbose(@"error received: %@", error);
        
        if (block) {
            block(nil, error);
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
    
    // Compress data
    /*
    NSData *originalData = [postRequest HTTPBody];
    NSData *compressedData = [originalData dataByGZipCompressingWithError:nil];
    [postRequest setHTTPBody:compressedData];
    [postRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    */
    
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

- (void)updateMyChannel:(Me *)me withBlock:(void (^)(id, NSError *))block
{
    // proceed to make server updates
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: me.guid, @"guid", @"8", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFJSONRequestOperation *getOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:getRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DDLogVerbose(@"get channel %@ data received: %@", me, JSON);
        
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
- (void)updateMyPresetChannel:(Me *)me withBlock:(void (^)(id, NSError *))block
{
    // proceed to make server updates
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"9", @"op", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    AFJSONRequestOperation *getOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:getRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DDLogVerbose(@"get preset channel %@ data received: %@", me, JSON);
        
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

- (void)getNearestPeopleWithGender:(NSUInteger)gender start:(NSUInteger)start querysize:(NSUInteger)querySize andBlock:(void (^)(id, NSError *))block
{    
    NSString * genderString = [NSString stringWithFormat:@"%i",gender];
    NSString * startString = [NSString stringWithFormat:@"%i",start];
    NSString * querySizeStr = [NSString stringWithFormat:@"%i", querySize];
    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"10", @"op", querySizeStr, @"querysize", startString, @"start", genderString, @"gender", nil];
    NSMutableURLRequest *getRequest = [[AppNetworkAPIClient sharedClient] requestWithMethod:@"GET" path:GET_DATA_PATH parameters:getDict];
    
    AFHTTPRequestOperation *getOperation = [[AppNetworkAPIClient sharedClient] HTTPRequestOperationWithRequest:getRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get nearest user data received: %@", responseObject);
        
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

// 签到奖励列表
- (void)getCheckinInfoWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"14", @"op", nil];
    // 11 是频道列表
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

// 频道列表
- (void)getChannelListWithBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"11", @"op", nil];
    // 11 是频道列表
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
