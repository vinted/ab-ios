//
//  ABTestConfig.m
//  Vinted
//
//  Created by Sarunas Kazlauskas on 16/06/14.
//  Copyright (c) 2014 Vinted. All rights reserved.
//

#import "VNTABTestConfig.h"
#import "VNTABTest.h"
#import "VNTABTestVariant.h"
#import <CommonCrypto/CommonDigest.h>
#import <OpenSSL-Universal/openssl/bn.h>

@implementation VNTABTestConfig

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithDictionary:@{
                                                       @"salt": @"salt",
                                                       @"bucket_count": @"bucketCount",
                                                       @"ab_tests": @"abTests",
                                                       }];
}

- (NSInteger)bucketIdForIdentifier:(NSString *)identifier
{
    BIGNUM *number = [self hexDigestString:[self.salt stringByAppendingString:identifier]];
    return [self modNumber:number byInteger:self.bucketCount];
}

- (NSInteger)weightIdForTest:(VNTABTest *)test identifier:(NSString *)identifier
{
    BIGNUM *number = [self hexDigestString:[test.seed stringByAppendingString:identifier]];
    NSInteger variantWeightSum = [self variantWeightSumOfTest:test];
    return [self modNumber:number byInteger:(variantWeightSum > 0 ? variantWeightSum : 1)];
}

- (NSArray *)assignedTestsForIdentifier:(NSString *)identifier
{
    NSInteger bucketId = [self bucketIdForIdentifier:identifier];
    NSMutableArray *assignedTests = [NSMutableArray array];
    for (VNTABTest *test in self.abTests) {
        if (test.allBuckets || (test.buckets && [test.buckets containsObject:@(bucketId)])) {
            if ([test isRunning]) {
                [assignedTests addObject:test];
            }
        }
    }
    return assignedTests;
}

- (BOOL)testInBucket:(VNTABTest *)test identifier:(NSString *)identifier
{
    NSInteger bucketId = [self bucketIdForIdentifier:identifier];
    return (test.allBuckets || (test.buckets && [test.buckets containsObject:@(bucketId)]));
}

- (VNTABTestVariant *)assignedVariantForTest:(VNTABTest *)test identifier:(NSString *)identifier
{
    if (![test isRunning] || ![self testInBucket:test identifier:identifier]) {
        return nil;
    }
    NSInteger weightId = [self weightIdForTest:test identifier:identifier];
    NSInteger sum = 0;
    for (VNTABTestVariant *variant in test.variants) {
        sum += variant.chanceWeight;
        if (sum > weightId) {
            return variant;
        }
    }
    return nil;
}

- (VNTABTestVariant *)assignedVariantForTestName:(NSString *)testName identifier:(NSString *)identifier
{
    VNTABTest *test = [self testForName:testName];
    return test ? [self assignedVariantForTest:test identifier:identifier] : nil;
}

- (BIGNUM *)hexDigestString:(NSString *)string
{
    if (!string) {
        return nil;
    }
    const char* str = [string UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, strlen(str), result);
    return BN_bin2bn(result, CC_SHA256_DIGEST_LENGTH, NULL);
}

- (NSInteger)variantWeightSumOfTest:(VNTABTest *)test
{
    NSInteger weightSum = 0;
    for (VNTABTestVariant *variant in test.variants) {
        weightSum += variant.chanceWeight;
    }
    return weightSum;
}

- (NSInteger)modNumber:(BIGNUM *)number byInteger:(NSInteger)integer
{
    BIGNUM *remainder = BN_new();
    BIGNUM *modulo = BN_new();
    BN_CTX *ctx = BN_CTX_new();
    BN_dec2bn(&modulo, [[NSString stringWithFormat:@"%d", integer] cStringUsingEncoding:NSUTF8StringEncoding]);
    BN_mod(remainder, number, modulo, ctx);
    return [[NSString stringWithCString:BN_bn2dec(remainder) encoding:NSUTF8StringEncoding] integerValue];
}

- (VNTABTest *)testForName:(NSString *)name
{
    for (VNTABTest *test in self.abTests) {
        if ([test.name isEqualToString:name]) {
            return test;
        }
    }
    return nil;
}

@end
