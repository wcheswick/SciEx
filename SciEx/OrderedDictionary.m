//
//  OrderedDictionary.m
//  ChesCharts
//
//  Created by ches on 15/8/22.
//  Copyright (c) 2015 Cheswick.com. All rights reserved.
//

/// *** needs: countByEnumerationWithState:objects:count:

#import "OrderedDictionary.h"

#define kDict   @"Dictionary"
#define kArray  @"Array"


@interface OrderedDictionary ()

@property (assign)              size_t mutations;

@end

@implementation OrderedDictionary

@synthesize dict;
@synthesize keys;
@synthesize mutations;


- (id) init {
    self = [super init];
    if (self) {
        dict = [[NSMutableDictionary alloc] init];
        keys = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        dict = [coder decodeObjectForKey:kDict];
        keys = [coder decodeObjectForKey:kArray];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.dict forKey:kDict];
    [coder encodeObject:self.keys forKey:kArray];
}

- (void) removeObjectAtIndex: (size_t) index {
    NSString *key = [keys objectAtIndex:index];
    [dict removeObjectForKey:key];
    [keys removeObjectAtIndex:index];
    mutations++;
}

- (void) addObject:(id)object withKey:(NSString *)key {
    [dict setObject:object forKey:key];
    [keys addObject:key];
    mutations++;
}

- (void) insertObject: (id) object withKey: (NSString *) key atIndex: (size_t) index {
    [dict setObject:object forKey:key];
    [keys insertObject:key atIndex:index];
    mutations++;
}

- (void) moveObjectAtIndex: (size_t)from to:(size_t) to {
    NSString *key = [self objectAtIndex:from];
    [keys removeObjectAtIndex:from];
    [keys insertObject:key atIndex:to];
    mutations++;
}

- (id) objectAtIndex: (size_t) index {
    NSString *key = [keys objectAtIndex:index];
    return [dict objectForKey:key];
}

- (id) objectForKey:(NSString *)key {
    return [dict objectForKey:key];
}

- (size_t) count {
    return [keys count];
}

- (NSString *) keyAtIndex: (size_t) index {
    return [keys objectAtIndex:index];
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) enumerationState
                                   objects: (id __unsafe_unretained []) stackBuffer
                                     count: (NSUInteger) len {
    
    if (enumerationState->state == 0) { // first time
        enumerationState->mutationsPtr = &mutations;  // Can't be NULL.
    } else if (enumerationState->state == keys.count) {
        return 0;
    }
    mutations = 0;
    
    // Fill up as much of the stack buffer as we can.
    size_t i = enumerationState->state;
    for (; i < len && i + enumerationState->state < keys.count; i++) {
        NSString *key = [keys objectAtIndex:i+ enumerationState->state];
        stackBuffer[i] = [dict objectForKey:key];
    }
    enumerationState->state = i + enumerationState->state;
    enumerationState->itemsPtr = stackBuffer;
    return i;
}

@end
