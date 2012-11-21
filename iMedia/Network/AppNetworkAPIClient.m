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
//#import "UpYun.h"

//static NSString * const kAppNetworkAPIBaseURLString = @"http://192.168.1.104:8000/";//
static NSString * const kAppNetworkAPIBaseURLString = @"http://media.wingedstone.com:8000/";

#define USE_UYUN_SERVICE

NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyJIDPassword = @"kXMPPmyJIDPassword";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";
NSString *const kXMPPmyUsername = @"kXMPPmyUsername";

@interface AppNetworkAPIClient ()

@property (nonatomic, strong) NSMutableDictionary *imageUploadOperationsInProgress;

- (void)networkChangeReceived:(NSNotification *)notification;

@end

@implementation AppNetworkAPIClient

@synthesize kNetworkStatus;
@synthesize imageUploadOperationsInProgress;

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

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    self.imageUploadOperationsInProgress = [[NSMutableDictionary alloc] initWithCapacity:4];
    
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
    [[AppNetworkAPIClient sharedClient] getPath:GET_CONFIG_PATH parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"get config JSON received: %@", responseObject);
        [[NSUserDefaults standardUserDefaults] setObject:[responseObject valueForKey:@"logintypes"] forKey:@"logintypes"];
        [[NSUserDefaults standardUserDefaults] setObject:[responseObject valueForKey:@"csrfmiddlewaretoken"] forKey:@"csrfmiddlewaretoken"];
        
        // now is to login
        NSDictionary *loginDict = [NSDictionary dictionaryWithObjectsAndKeys: username, @"username", passwd, @"password", [responseObject valueForKey:@"csrfmiddlewaretoken"], @"csrfmiddlewaretoken", nil];
        
        [[AppNetworkAPIClient sharedClient] postPath:LOGIN_PATH parameters:loginDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogVerbose(@"login JSON received: %@", responseObject);
            
            NSString* status = [responseObject valueForKey:@"status"];
            if ([status isEqualToString:@"success"]) {
                
                NSString* jid = [responseObject valueForKey:@"jid"];
                NSString *jPassword = [responseObject valueForKey:@"jpass"];
                
                [[NSUserDefaults standardUserDefaults] setObject:jid forKey:kXMPPmyJID];
                [[NSUserDefaults standardUserDefaults] setObject:jPassword forKey:kXMPPmyJIDPassword];
                [[NSUserDefaults standardUserDefaults] setObject:username forKey:kXMPPmyUsername];
                [[NSUserDefaults standardUserDefaults] setObject:passwd forKey:kXMPPmyPassword];
                
                if (block ) {
                    block(responseObject, nil);
                }
            } else {
                NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
                if (block) {
                    block(responseObject, error);
                }
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //
            DDLogVerbose(@"login failed: %@", error);
            if (block) {
                block(nil, error);
            }
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"error received: %@", error);
        if (block) {
            block (nil, error);
        }
    }];
    
}

- (void)storeImage:(UIImage *)image thumbnail:(UIImage *)thumbnail forMe:(Me *)me andAvatar:(Avatar *)avatar withBlock:(void (^)(id, NSError *))block
{

#ifdef USE_UYUN_SERVICE
    /*
    UpYun *uy = [[UpYun alloc] init];
    uy.delegate = self;
    uy.expiresIn = 100;
    uy.bucket = @"wstone";
    */
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
        
        [self.imageUploadOperationsInProgress removeObjectForKey:avatar.sequence];
        
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
        [self.imageUploadOperationsInProgress removeObjectForKey:avatar.sequence];
        if (block) {
            block(nil, error);
        }
    }];
    
    DDLogInfo(@"http request: %@", operation);
    
    [self.imageUploadOperationsInProgress setObject:operation forKey:avatar.sequence];
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
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
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get user %@ data received: %@", identity, responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if ([type isEqualToString:@"user"] || [type isEqualToString:@"channel"]) {
            // compare the incoming new user data with old user data. if thumbnailURL is the same
            // then don't load the image
            NSString *thumbnailURL = [ServerDataTransformer getThumbnailFromServerJSON:responseObject];
            if (thumbnailURL == nil || [thumbnailURL isEqualToString:@""]) {
                identity.thumbnailImage = nil;
#warning TODO: set to the global placeholder
            } else if (thumbnailURL != identity.thumbnailURL) {
                NSURL *url = [NSURL URLWithString:thumbnailURL];

                // Try twice to load the image
                AFImageRequestOperation *imageOper = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:url] imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    identity.thumbnailImage = image;
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    DDLogError(@"Failed to get thumbnail at first time url: %@, response :%@, tryting again", thumbnailURL, responseObject);
                    AFImageRequestOperation  *imageOperAgain = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:url] imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                        identity.thumbnailImage = image;
                        
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        DDLogError(@"ERROR: Failed again to get thumbnail at first time url: %@, response :%@", thumbnailURL, responseObject);
                    }];
                    
                    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:imageOperAgain];
                }];
                
                [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:imageOper];
            }

            
            [[ModelHelper sharedInstance] populateIdentity:identity withJSONData:responseObject];
            
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
                            DDLogInfo(@"load me thumbnail image received response: %@", responseObject);
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
                block (responseObject, nil);
            }

        } else {
            if (block) {
                block(nil, nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"error received: %@", error);
        
       
        if (block) {
            block(nil, error);
        }
    }];

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
                block (nil, nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"upload me failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];
    
    DDLogInfo(@"http request: %@", operation);
    
    NSArray *imageUploadingOpers = [self.imageUploadOperationsInProgress allValues];
    for (int i = 0; i < [imageUploadOperationsInProgress count]; i++) {
        [operation addDependency:[imageUploadingOpers objectAtIndex:i]];
    }
    
    [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
    
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
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"get channel %@ data received: %@", me, responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                block (nil, nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
}
- (void)updateMyPresetChannel:(Me *)me withBlock:(void (^)(id, NSError *))block
{
    // proceed to make server updates
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"9", @"op", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"get channel %@ data received: %@", me, responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                block (nil, nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
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
                block (nil, nil);
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
                block (nil, nil);
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
    
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:nil failure:nil];
}

- (void)getNearestPeopleWithGender:(NSUInteger)gender andStart:(NSUInteger)start andBlock:(void (^)(id, NSError *))block
{
/*    NSDictionary * result = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"123456", @"fake", @"i am a good guy", "0.12894743","","2012-11-16 14:00:23", nil] forKeys:[NSArray arrayWithObjects:@"guid", @"nickname", @"signature", @"distance", "thumbnail","lastupdated", nil]]] forKeys:[NSArray arrayWithObjects:@"0", nil]];
    
  
    return result;
 */
    
    NSString * genderString = [NSString stringWithFormat:@"%i",gender];
    NSString * startString = [NSString stringWithFormat:@"%i",start];
    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: @"10", @"op", @"20", @"querysize", startString, @"start", genderString, @"gender", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"get nearest user data received: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if (![@"error" isEqualToString:type]) {
            if (block) {
                block (responseObject, nil);
            }
        } else {
            if (block) {
                block (nil, nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block (nil, error);
        }
    }];
    
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
