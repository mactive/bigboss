//
//  ModelSearchHelper.m
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "ModelHelper.h"
#import "User.h"
#import "Me.h"
#import "Channel.h"
#import "ImageRemote.h"
#import "ServerDataTransformer.h"
#import "FriendRequest.h"
#import "NSObject+SBJson.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface ModelHelper ()

+ (void)populateUser:(User *)user withJSONData:(NSString *)json;
+ (void)populateMe:(Me *)user withJSONData:(NSString *)json;
+ (void)populateChannel:(Channel *)channel withServerJSONData:(NSString *)json;

@end

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

+ (Channel *)findChannelWithSubrequestID:(NSString *)subID inContext:(NSManagedObjectContext *)context
{
    NSManagedObjectContext *moc = context;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Channel" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(subrequestID = %@)", subID];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    if ([array count] == 0)
    {
        DDLogError(@"Channel doesn't exist: %@", error);
        return nil;
    } else {
        if ([array count] > 1) {
            DDLogError(@"More than one user object with same postal id: %@", subID);
        }
        return [array objectAtIndex:0];
    }
}

+ (void)populateIdentity:(Identity *)identity withJSONData:(NSString *)json
{
    
    if ([identity isKindOfClass:[User class]]) {
        [self populateUser:(User *)identity withJSONData:json];
    } else if ([identity isKindOfClass:[Channel class]]) {
        [self populateChannel:(Channel *)identity withServerJSONData:json];
    } else {
        [self populateMe:(Me *)identity withJSONData:json];
    }
}

+ (void )populateMe:(Me *)user withJSONData:(id)json
{
    user.ePostalID = [ServerDataTransformer getEPostalIDFromServerJSON:json];
    user.gender = [ServerDataTransformer getGenderFromServerJSON:json];
    user.signature = [ServerDataTransformer getSignatureFromServerJSON:json];
    user.displayName = [ServerDataTransformer getNicknameFromServerJSON:json];
    user.birthdate = [ServerDataTransformer getBirthdateFromServerJSON:json];
    user.career = [ServerDataTransformer getCareerFromServerJSON:json];
    user.selfIntroduction = [ServerDataTransformer getSelfIntroductionFromServerJSON:json];
    user.hometown = [ServerDataTransformer getHometownFromServerJSON:json];
    user.avatarURL = [ServerDataTransformer getAvatarFromServerJSON:json];
    user.thumbnailURL = [ServerDataTransformer getThumbnailFromServerJSON:json];
    user.cell = [ServerDataTransformer getCellFromServerJSON:json];
    user.name = [ServerDataTransformer getNicknameFromServerJSON:json];
    
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

+ (void)populateUser:(User *)user withJSONData:(id)json
{
    if (user.ePostalID == nil) {
        user.ePostalID = [ServerDataTransformer getEPostalIDFromServerJSON:json];
    } else {
        ;
    }
    
    user.gender = [ServerDataTransformer getGenderFromServerJSON:json];
    user.signature = [ServerDataTransformer getSignatureFromServerJSON:json];
    user.displayName = [ServerDataTransformer getNicknameFromServerJSON:json];
    user.birthdate = [ServerDataTransformer getBirthdateFromServerJSON:json];
    user.career = [ServerDataTransformer getCareerFromServerJSON:json];
    user.selfIntroduction = [ServerDataTransformer getSelfIntroductionFromServerJSON:json];
    user.hometown = [ServerDataTransformer getHometownFromServerJSON:json];
    user.guid = [ServerDataTransformer getGUIDFromServerJSON:json];
    user.avatarURL = [ServerDataTransformer getAvatarFromServerJSON:json];
    user.thumbnailURL = [ServerDataTransformer getThumbnailFromServerJSON:json];
    user.lastGPSUpdated = [ServerDataTransformer getLastGPSUpdatedFromServerJSON:json];

    NSMutableDictionary *imageURLDict = [[NSMutableDictionary alloc] initWithCapacity:8];
    for (int i = 1; i <=8; i++) {
        NSString *key = [NSString stringWithFormat:@"avatar%d", i];
        NSString *url = [ServerDataTransformer getStringObjFromServerJSON:json byName:key];
        if (url != nil && ![url isEqualToString:@""]) {
            [imageURLDict setValue:url forKey:[NSString stringWithFormat:@"%d", i]];
        }
    }
    NSMutableDictionary *imageThumbnailURLDict = [[NSMutableDictionary alloc] initWithCapacity:8];
    for (int i = 1; i <=8; i++) {
        NSString *key = [NSString stringWithFormat:@"thumbnail%d", i];
        NSString *url = [ServerDataTransformer getStringObjFromServerJSON:json byName:key];
        if (url != nil && ![url isEqualToString:@""]) {
            [imageThumbnailURLDict setValue:url forKey:[NSString stringWithFormat:@"%d", i]];
        }
    }
    // Update avatar with incoming data
    NSArray *imageArray = [user getOrderedImages];
    for (int i = 1; i <= 8 ; i++) {
        ImageRemote *imageRemote = [imageArray objectAtIndex:(i-1)];
        NSString *key = [NSString stringWithFormat:@"%d", i];
        if ([imageURLDict objectForKey:key] != nil && [imageThumbnailURLDict objectForKey:key] != nil) {
            imageRemote.imageURL = [imageURLDict objectForKey:key];
            imageRemote.imageThumbnailURL = [imageThumbnailURLDict objectForKey:key];
            imageRemote.sequence = [NSNumber numberWithInt:i];
        } else {
            imageRemote.imageURL = @"";
            imageRemote.imageThumbnailURL = @"";
            imageRemote.sequence = 0;
        }
    }
}


+ (void)populateChannel:(Channel *)channel withServerJSONData:(NSString *)json
{
    channel.guid = [ServerDataTransformer getGUIDFromServerJSON:json];
    channel.node = [ServerDataTransformer getNodeFromServerJSON:json];
    channel.displayName = [ServerDataTransformer getNicknameFromServerJSON:json];
    channel.ePostalID = [ServerDataTransformer getCSContactIDFromServerJSON:json];
    channel.csContactPostalID = [ServerDataTransformer getCSContactIDFromServerJSON:json];
    channel.avatarURL = [ServerDataTransformer getAvatarFromServerJSON:json];
    channel.thumbnailURL = [ServerDataTransformer getThumbnailFromServerJSON:json];
    channel.selfIntroduction = [ServerDataTransformer getSelfIntroductionFromServerJSON:json];
    channel.lastGPSUpdated = [ServerDataTransformer getLastGPSUpdatedFromServerJSON:json];

    channel.type = [NSNumber numberWithInt:IdentityTypeChannel];
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

+ (FriendRequest *)newFriendRequestWithEPostalID:(NSString *)jid json:(id)jsonData andInContext:(NSManagedObjectContext *)context
{
    FriendRequest *newFriendRequest = [NSEntityDescription insertNewObjectForEntityForName:@"FriendRequest" inManagedObjectContext:context];
    newFriendRequest.requesterEPostalID = jid;
    newFriendRequest.requestDate = [NSDate date];
    newFriendRequest.userJSONData = jsonData;
    newFriendRequest.state = [NSNumber numberWithInt:FriendRequestUnprocessed];
    
    return newFriendRequest;
}

@end
