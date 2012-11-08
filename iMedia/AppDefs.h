//
//  LayoutConst.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#ifndef iMedia_LayoutConst_h
#define iMedia_LayoutConst_h


#define DBNAME @"xiangyuansms.sqlite"
#define DBVERSION @"1"
#define URL_TEMPLATE @"http://www.source3g.com/sms/template.txt"

#define TINY_FONT_HEIGHT 12
#define SMALL_FONT_HEIGHT 14
#define MIDDLE_FONT_HEIGHT 16
#define LARGE_FONT_HEIGHT 18
#define HUGE_FONT_HEIGHT 22

#define SMALL_GAP 5
#define MIDDLE_GAP 10
#define LARGE_GAP 20

#define TAB_BAR_HEIGHT 40
#define SEARCH_BAR_HEIGHT 40
#define SECTION_BAR_HEIGHT 30
#define ACTION_BAR_HEIGHT 40
#define TEXTFEILD_HEIGHT 40
#define NAV_MAX_BUTTON 80
#define TEMPLATE_CELL_HEIGHT 50

#define TEMPLATE_IMAGE_HEIGHT 150


// PROFILE ME EDIT INDEX
#define NICKNAME_ITEM_INDEX     0
#define SEX_ITEM_INDEX          1
#define BIRTH_ITEM_INDEX        2
#define SIGNATURE_ITEM_INDEX    3
#define CELL_ITEM_INDEX         4
#define CAREER_ITEM_INDEX       5
#define HOMETOWN_ITEM_INDEX     6
#define SELF_INTRO_ITEM_INDEX   7
#define JPEG_QUALITY 0.6



#define UIKeyboardNotificationsObserve() \
NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; \
[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];\
[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

#define NotificationsUnobserve() \
[[NSNotificationCenter defaultCenter] removeObserver:self];

#pragma mark - Core Data

#define MOCSave(managedObjectContext) { \
NSError __autoreleasing *error = nil; \
NSAssert([managedObjectContext save:&error], @"-[NSManagedObjectContext save] error:\n\n%@", error); }

#define MOCCount(managedObjectContext, fetchRequest) \
NSManagedObjectContextCount(self, _cmd, managedObjectContext, fetchRequest)

#define MOCCountAll(managedObjectContext, entityName) \
MOCCount(_managedObjectContext, [NSFetchRequest fetchRequestWithEntityName:entityName])

NS_INLINE NSUInteger NSManagedObjectContextCount(id self, SEL _cmd, NSManagedObjectContext *managedObjectContext, NSFetchRequest *fetchRequest) {
    NSError __autoreleasing *error = nil;
    NSUInteger objectsCount = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    NSAssert(objectsCount != NSNotFound, @"-[NSManagedObjectContext countForFetchRequest:error:] error:\n\n%@", error);
    return objectsCount;
}

NS_INLINE BOOL StringHasValue(NSString * str) {
    return (str != nil) && (![str isEqualToString:@""]);
}

typedef enum _MessageType
{
    MessageTypeChat = 1,
    MessageTypePublish = 2,
    MessageTypeRate = 3,
    MessageTypeNone = 10
} MessageType;

typedef enum _IdentityType
{
    IdentityTypeUser = 1,
    IdentityTypeMe      = 2,
    IdentityTypeChannel = 3
} IdentityType;

typedef enum _IdentityState
{
    IdentityStateActive     = 1,
    IdentityStatePendingAddSubscription     = 2,
    IdentityStatePendingAddFriend   = 3,
    IdentityStatePendingRemoveSubscription  = 4,
    IdentityStatePendingRemoveFriend    =5,
    IdentityStatePendingServerDataUpdate = 6,
    IdentityStateInactive   = 100
} IdentityState;

///////////////////////////////////////////////////////////////////////////////////////////////////
// add by mactive
#define T(a)    NSLocalizedString((a), nil)

#define INT(a)  [NSNumber numberWithInt:(a)]
#define STR(a)  [NSString stringWithFormat:@"%@", (a)]
#define STR_INT(a)  [NSString stringWithFormat:@"%d", (a)]

#define NUMBER_OR_NIL(a)	\
(((a) && [(a) isKindOfClass:[NSNumber class]]) ? (a) : nil)

#define STRING_OR_NIL(a)	\
(((a) && [(a) isKindOfClass:[NSString class]]) ? (a) : nil)

#define STRING_OR_EMPTY(a)	\
(((a) && [(a) isKindOfClass:[NSString class]]) ? (a) : @"")

#define kDateFormat  @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z"

///////////////////////////////////////////////////////////////////////////////////////////////////
// Color helpers

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f \
alpha:(a)]

#define HSVCOLOR(h,s,v) [UIColor colorWithHue:(h) saturation:(s) value:(v) alpha:1]
#define HSVACOLOR(h,s,v,a) [UIColor colorWithHue:(h) saturation:(s) value:(v) alpha:(a)]

#define RGBA(r,g,b,a) (r)/255.0f, (g)/255.0f, (b)/255.0f, (a)
#define BGCOLOR [UIColor colorWithRed:222.0f/255.0f green:224.0f/255.0f blue:227.0f/255.0f alpha:1]

///////////////////////////////////////////////////////////////////////////////////////////////////
#define NAMEFIRSTLATTER	@"&ABCDEFGHIJKLMNOPQRSTUVWXYZ"

/*
#define MOCFetch(managedObjectContext, fetchRequest) \
NSManagedObjectContextFetch(self, _cmd, managedObjectContext, fetchRequest)

#define MOCFetchAll(managedObjectContext, entityName) \
MOCFetch(_managedObjectContext, [NSFetchRequest fetchRequestWithEntityName:entityName])

#define MOCDelete(managedObjectContext, fetchRequest, cascadeRelationships) \
NSManagedObjectContextDelete(self, _cmd, managedObjectContext, fetchRequest, cascadeRelationships)

#define MOCDeleteAll(managedObjectContext, entityName, cascadeRelationships) \
MOCDelete(managedObjectContext, [NSFetchRequest fetchRequestWithEntityName:entityName], cascadeRelationships)

#define FRCPerformFetch(fetchedResultsController) { \
NSError __autoreleasing *error = nil; \
NSAssert([fetchedResultsController performFetch:&error], @"-[NSFetchedResultsController performFetch:] error:\n\n%@", error); }


NS_INLINE NSArray *NSManagedObjectContextFetch(id self, SEL _cmd, NSManagedObjectContext *managedObjectContext, NSFetchRequest *fetchRequest) {
    NSError __autoreleasing *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(fetchedObjects, @"-[NSManagedObjectContext executeFetchRequest:error:] error:\n\n%@", error);
    return fetchedObjects;
}

NS_INLINE void NSManagedObjectContextDelete(id self, SEL _cmd, NSManagedObjectContext *managedObjectContext, NSFetchRequest *fetchRequest, NSArray *cascadeRelationships) {
    fetchRequest.includesPropertyValues = NO;
    fetchRequest.includesPendingChanges = NO;
    fetchRequest.relationshipKeyPathsForPrefetching = cascadeRelationships;
    NSArray *fetchedObjects = MOCFetch(managedObjectContext, fetchRequest);
    for (NSManagedObject *fetchedObject in fetchedObjects) {
        [managedObjectContext deleteObject:fetchedObject];
    }
}
*/

#endif
