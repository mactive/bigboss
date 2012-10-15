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
    user.gender = [json valueForKey:@"sex"];
    user.signature = [json valueForKey:@"signature"];
    user.displayName = [json valueForKey:@"nickname"];
    
    return YES;
}

+ (BOOL)populateChannel:(Channel *)channel withServerJSONData:(NSString *)json
{
    channel.guid = [json valueForKey:@"global_id"];
    channel.node = [json valueForKey:@"node_address"];
    channel.displayName = [json valueForKey:@"name"];
    channel.csContactPostalID = [json valueForKey:@"receive_jid"];
    channel.type = [NSNumber numberWithInt:IdentityTypeChannel];
    
    return YES;
}

@end
