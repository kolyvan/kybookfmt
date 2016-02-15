//
//  TestsHelpers.h
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KyBookFmtManifest;

@interface TestsHelpers : NSObject
+ (KyBookFmtManifest *) sampleManifest;
+ (NSString *) bundleFileWithPath:(NSString *)path;
+ (NSData *) bundleDataWithPath:(NSString *)path;
+ (NSString *) tmpFilePath;
+ (NSArray<NSString *> *) sampleTexts;
@end
