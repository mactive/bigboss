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
#import "pinyin.h"
#import "POAPinyin.h"
#import "Channel.h"

@interface Identity ()
- (void)setPrimitiveDisplayName:(NSString *)newName;
@end

@implementation Identity

@dynamic avatarURL;
@dynamic displayName;
@dynamic ePostalID;
@dynamic guid;
@dynamic last_serverupdate_on;
@dynamic lastGPSLocation;
@dynamic lastGPSUpdated;
@dynamic sectionName;
@dynamic state;
@dynamic thumbnailImage;
@dynamic thumbnailURL;
@dynamic type;
@dynamic images;
@dynamic ownedConversations;

- (void)setDisplayName:(NSString *)displayName
{
    [self willChangeValueForKey:@"displayName"];
    [self setPrimitiveDisplayName:displayName];
   
    
    // update section here
    NSString* _pinyin = [POAPinyin quickConvert:displayName];
        
    if (_pinyin == nil || [_pinyin isEqualToString:@""]) {
        self.sectionName = @"[";
    } else {
        self.sectionName = [[NSString stringWithFormat:@"%c", [_pinyin characterAtIndex:0] ] uppercaseString];
        unichar letter = [self.sectionName characterAtIndex:0];
        if (letter < 'A' || letter > 'Z') {
            self.sectionName = @"[";
        }
    }
    
    if ([self isKindOfClass:[Channel class]]) {
        self.sectionName = @"@";
    }
    
    [self didChangeValueForKey:@"displayName"];
}

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
