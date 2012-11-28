//
//  Identity.m
//  iMedia
//
//  Created by Xiaosi Li on 11/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "Identity.h"
#import "Conversation.h"
#import "ImageRemote.h"


@implementation Identity

@dynamic avatarURL;
@dynamic displayName;
@dynamic ePostalID;
@dynamic guid;
@dynamic last_serverupdate_on;
@dynamic lastGPSLocation;
@dynamic lastGPSUpdated;
@dynamic state;
@dynamic thumbnailImage;
@dynamic thumbnailURL;
@dynamic type;
@dynamic images;
@dynamic ownedConversations;

-(NSArray *)getOrderedImages
{
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES];
    NSArray *result = [self.images sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    
    return result;
}

-(NSArray *)getOrderedNonNilImages
{
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sequence > 0"];
    NSSet *filteredSet =[self.images filteredSetUsingPredicate:predicate];
    NSArray *result = [filteredSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    
    return result;
}


@end
