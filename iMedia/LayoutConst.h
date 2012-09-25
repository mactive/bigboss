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

/*
#pragma mark - Core Data

#define MOCSave(managedObjectContext) { \
NSError __autoreleasing *error = nil; \
NSAssert([managedObjectContext save:&error], @"-[NSManagedObjectContext save] error:\n\n%@", error); }

#define MOCCount(managedObjectContext, fetchRequest) \
NSManagedObjectContextCount(self, _cmd, managedObjectContext, fetchRequest)

#define MOCCountAll(managedObjectContext, entityName) \
MOCCount(_managedObjectContext, [NSFetchRequest fetchRequestWithEntityName:entityName])

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


NS_INLINE NSUInteger NSManagedObjectContextCount(id self, SEL _cmd, NSManagedObjectContext *managedObjectContext, NSFetchRequest *fetchRequest) {
    NSError __autoreleasing *error = nil;
    NSUInteger objectsCount = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    NSAssert(objectsCount != NSNotFound, @"-[NSManagedObjectContext countForFetchRequest:error:] error:\n\n%@", error);
    return objectsCount;
}

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
