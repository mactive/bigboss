//
//  AppNetworkAPIClient.m
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AppNetworkAPIClient.h"
#import "AFJSONRequestOperation.h"
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

static NSString * const kAppNetworkAPIBaseURLString = @"http://192.168.1.104:8000/";
//static NSString * const kAppNetworkAPIBaseURLString = @"http://media.wingedstone.com:8000/";

NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyJIDPassword = @"kXMPPmyJIDPassword";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";
NSString *const kXMPPmyUsername = @"kXMPPmyUsername";

@implementation AppNetworkAPIClient

+ (AppNetworkAPIClient *)sharedClient {
    static AppNetworkAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AppNetworkAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAppNetworkAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
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
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys: csrfToken, @"csrfmiddlewaretoken", UIImagePNGRepresentation(avatar.image), @"image", UIImagePNGRepresentation(avatar.thumbnail), @"thumbnail", nil];
    
    [[AppNetworkAPIClient sharedClient] postPath:IMAGE_SERVER_PATH parameters:paramDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        DDLogInfo(@"upload image received response: %@", responseObject);
        
        if (block) {
            block(responseObject, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)updateIdentity:(Identity *)identity withBlock:(void (^)(id, NSError *))block
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: identity.guid, @"guid", @"1", @"op", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get config JSON received: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        
        if ([type isEqualToString:@"error"]) {
            if (block) {
                block(nil, nil);
            }
        } else if ([type isEqualToString:@"user"] || [type isEqualToString:@"channel"]) {
            [ModelHelper populateIdentity:identity withJSONData:responseObject];
            
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
                              me.avatarURL, @"avatar",
                              me.cell, @"cell",
                              me.signature, @"signature",
                              me.hometown, @"hometown",
                              me.displayName, @"nickname",
                              me.gender, @"gender",
                              me.selfIntroduction, @"self_introduction",
                              csrfToken, @"csrfmiddlewaretoken", @"3", @"op", nil];
    NSArray *imagesURLArray = [me getOrderedImages];
    for (int i = 0; i < 8; i++) {
        ImageRemote* remoteImage = [imagesURLArray objectAtIndex:i];
        NSString *key1 = [NSString stringWithFormat:@"avatar%d", i];
        NSString *key2 = [NSString stringWithFormat:@"thumbnail%d", i];
        [postDict setObject:remoteImage.imageURL forKey:key1];
        [postDict setObject:remoteImage.imageThumbnailURL forKey:key2];
    }
    
    [[AppNetworkAPIClient sharedClient] postPath:LOGIN_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"login JSON received: %@", responseObject);
        
        NSString* status = [responseObject valueForKey:@"status"];
        if ([status isEqualToString:@"success"]) {
            if (block ) {
                block(responseObject, nil);
            }
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"login failed: %@", error);
        if (block) {
            block(nil, error);
        }
    }];

    
}

@end
