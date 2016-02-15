//
//  KxGzipArchiveTests.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KxGzipArchive.h"
#import "TestsHelpers.h"

@interface KxGzipArchiveTests : XCTestCase
@end

@implementation KxGzipArchiveTests

- (void)testGzip {
    
    NSData *data = [TestsHelpers bundleDataWithPath:@"sample.km"];
    XCTAssertNotNil(data);
    NSData *gzipped = [KxGzipArchive gzipData:data];
    XCTAssertNotNil(gzipped);
    NSData *gunzipped = [KxGzipArchive gunzipData:gzipped];
    XCTAssertNotNil(gunzipped);
    XCTAssertEqualObjects(data, gunzipped);
}

@end
