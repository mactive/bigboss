//
//  ModelSearchHelper.m
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ModelHelper.h"
#import "User.h"
#import "Channel.h"
#import "ImageRemote.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ModelHelper

+ (User *)findUserWithEPostalID:(NSString *)ePostalID inContext:(NSManagedObjectContext *)context
{
    NSManagedObjectContext *moc = context;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"User" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(ePostalID = %@)", ePostalID];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    if ([array count] == 0)
    {
        DDLogError(@"User doesn't exist: %@", error);
        return nil;
    } else {
        if ([array count] > 1) {
            DDLogError(@"More than one user object with same postal id: %@", ePostalID);
        }
        return [array objectAtIndex:0];
    }
}

+ (Channel *)findChannelWithNode:(NSString *)node inContext:(NSManagedObjectContext *)context
{
    NSManagedObjectContext *moc = context;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Channel" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(node = %@)", node];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    if ([array count] == 0)
    {
        DDLogError(@"Channel doesn't exist: %@", error);
        return nil;
    } else {
        if ([array count] > 1) {
            DDLogError(@"More than one user object with same postal id: %@", node);
        }
        return [array objectAtIndex:0];
    }
}

+ (BOOL)populateUser:(User *)user withJSONData:(id)json
{
    user.ePostalID = [json valueForKey:@"jid"];
    user.gender = [json valueForKey:@"gender"];
    user.signature = [json valueForKey:@"signature"];
    user.displayName = [json valueForKey:@"nickname"];
    
    return YES;
}

+ (BOOL)populateChannel:(Channel *)channel withServerJSONData:(NSString *)json
{
    channel.guid = [json valueForKey:@"global_id"];
    channel.node = [json valueForKey:@"node_address"];
    channel.displayName = [json valueForKey:@"name"];
    channel.ePostalID = [json valueForKey:@"receive_jid"];
    channel.csContactPostalID = [json valueForKey:@"receive_jid"];
    channel.type = [NSNumber numberWithInt:IdentityTypeChannel];
    
    return YES;
}

+ (void)populateUser:(User *)user withJSONData:(NSString *)json inContext:(NSManagedObjectContext *)context
{
    [ModelHelper populateUser:user withJSONData:json];
    
    NSMutableArray *imageURLArray = [[NSMutableArray alloc] init];
    for (int i = 1; i <=8; i++) {
        NSString *key = [NSString stringWithFormat:@"avatar%d", i];
        NSString *url = [json valueForKey:key];
        if (url != nil && ![url isEqualToString:@""]) {
            [imageURLArray addObject:url];
        }
    }
    
    // Update avatar with incoming data
    NSArray *imageArray = [user getOrderedImages];
    for (int i = 0; i < [imageArray count]; i++) {
        ImageRemote *imageRemote = [imageArray objectAtIndex:i];
        if (i < [imageURLArray count]) {
            imageRemote.imageURL = [imageURLArray objectAtIndex:i];
            imageRemote.sequence = [NSNumber numberWithInt:i];
        } else {
            imageRemote.imageURL = nil;
            imageRemote.sequence = 0;
        }
    }
}

+ (User *)newUserInContext:(NSManagedObjectContext *)context
{
    User *newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    for (int i = 0; i < 8; i++) {
        ImageRemote *image = [NSEntityDescription insertNewObjectForEntityForName:@"ImageRemote" inManagedObjectContext:context];
        image.sequence = 0;
        [newUser addImagesObject:image];
    }
    
    return newUser;
}

@end
