//
//  ABTest.m
//  Vinted
//
//  Created by Sarunas Kazlauskas on 16/06/14.
//  Copyright (c) 2014 Vinted. All rights reserved.
//

#import "VNTABTest.h"
#import "VNTABTestVariant.h"

static NSString * const VNTABTestDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

@implementation VNTABTest

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithDictionary:@{
                                                       @"id": @"identifier",
                                                       @"name": @"name",
                                                       @"start_at": @"startAt",
                                                       @"end_at": @"endAt",
                                                       @"seed": @"seed",
                                                       @"buckets": @"buckets",
                                                       @"all_buckets": @"allBuckets",
                                                       @"variants": @"variants",
                                                       }];
}


+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    if ([propertyName isEqualToString:NSStringFromSelector(@selector(allBuckets))]) {
        return YES;
    }
    return NO;
}

#pragma mark - Private intance methods

+ (NSDate *)ISODateFromString:(NSString *)string
{
    if (!string) {
        return nil;
    }
    
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        dateFormatter.dateFormat = VNTABTestDateFormat;
    });

    return [dateFormatter dateFromString:string];
}

#pragma mark - Public instance methods

- (BOOL)isRunning
{
    if (!self.startAt && !self.endAt) {
        return YES;
    }
    
    NSDate *date = [NSDate date];
    return [date compare:[VNTABTest ISODateFromString:self.startAt]] == NSOrderedDescending &&
           [date compare:[VNTABTest ISODateFromString:self.endAt]]  == NSOrderedAscending;
}

@end
