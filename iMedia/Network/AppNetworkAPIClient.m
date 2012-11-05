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

//static NSString * const kAppNetworkAPIBaseURLString = @"http://192.168.1.104:8000/";
static NSString * const kAppNetworkAPIBaseURLString = @"http://media.wingedstone.com:8000/";

NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyJIDPassword = @"kXMPPmyJIDPassword";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";
NSString *const kXMPPmyUsername = @"kXMPPmyUsername";

@implementation AppNetworkAPIClient

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

- (void)storeAvatar:(Avatar *)avatar forMe:(Me *)me andOrder:(int)sequence withBlock:(void (^)(id, NSError *))block
{    
    NSString* csrfToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys: csrfToken, @"csrfmiddlewaretoken", nil];
    NSMutableURLRequest *postRequest = [[AppNetworkAPIClient sharedClient] multipartFormRequestWithMethod:@"POST" path:IMAGE_SERVER_PATH parameters:paramDict constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(avatar.image, 1.0) name:@"image" fileName:@"testimage" mimeType:@"image/jpeg"];
        [formData appendPartWithFileData:UIImageJPEGRepresentation(avatar.thumbnail, 1.0) name:@"thumbnail" fileName:@"testimageThumb" mimeType:@"image/jpeg"];
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
        
        NSArray *imagesURLArray = [me getOrderedImages];
        ImageRemote *imageRemote = [imagesURLArray objectAtIndex:(avatar.sequence.intValue-1)];
        imageRemote.sequence = avatar.sequence;
        imageRemote.imageThumbnailURL = thumbnailURL;
        imageRemote.imageURL = url;
        
        if (avatar.sequence.intValue == 1) {
            me.avatarURL = imageRemote.imageURL;
            me.thumbnailURL = imageRemote.imageThumbnailURL;
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
    
}

- (void)updateIdentity:(Identity *)identity withBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict ;
    if (identity.guid != nil && ![identity.guid isEqualToString:@""]) {
        getDict = [NSDictionary dictionaryWithObjectsAndKeys: identity.guid, @"guid", @"1", @"op", nil];
    } else {
        getDict = [NSDictionary dictionaryWithObjectsAndKeys: identity.ePostalID, @"jid", @"2", @"op", nil];
    }
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get user %@ data received: %@", identity, responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if ([type isEqualToString:@"error"]) {
            if (block) {
                block(nil, nil);
            }
        } else if ([type isEqualToString:@"user"] || [type isEqualToString:@"channel"]) {
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
            
            // if identity is Me, we need to check local avatar against the server. If local doesn't have the image
            // we need to download and save.
            if ([identity isKindOfClass:[Me class]]) {
                Me *me = identity;
                NSArray *imageArray = [me getOrderedNonNilImages];
                NSArray *avatarArray = [me getOrderedAvatars];
                for (int i = 0; i < [imageArray count] ; i++) {
                    ImageRemote *imageRemote = [imageArray objectAtIndex:i];
                    if (i < [avatarArray count]) {
                        Avatar *avatar = [avatarArray objectAtIndex:i];
                        
                        AFImageRequestOperation *oper = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imageRemote.imageURL]] success:^(UIImage *image) {
                            avatar.image = image;
                            UIImage *thumbnail = [image resizedImageToSize:CGSizeMake(75, 75)];
                            avatar.thumbnail = thumbnail;
                        }];
                        [[AppNetworkAPIClient sharedClient] enqueueHTTPRequestOperation:oper];
                    }
                }
                
            }
            if (identity.state.intValue == IdentityStatePendingServerDataUpdate) {
                identity.state = [NSNumber numberWithInt:IdentityStateActive];
                [[self appDelegate].contactListController contentChanged];
            }
            if (block) {
                block (responseObject, nil);
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
    NSArray *imagesURLArray = [me getOrderedNonNilImages];
    for (int i = 0; i < [imagesURLArray count]; i++) {
        ImageRemote* remoteImage = [imagesURLArray objectAtIndex:i];
        if (remoteImage.sequence == 0) {
            //empty, skip
            continue;
        }
        NSString *key1 = [NSString stringWithFormat:@"avatar%d", (i+1)];
        NSString *key2 = [NSString stringWithFormat:@"thumbnail%d", (i+1)];
        [postDict setObject:remoteImage.imageURL forKey:key1];
        [postDict setObject:remoteImage.imageThumbnailURL forKey:key2];
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

@end
