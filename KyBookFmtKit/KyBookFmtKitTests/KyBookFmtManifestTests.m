//
//  KyBookFmtManifestTests.m
//  KyBookFmtKitTests
//
//  Created by Konstantin Bukreev on 05.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KyBookFmtManifest.h"
#import "TestsHelpers.h"

@interface KyBookFmtManifestTests : XCTestCase
@end

@implementation KyBookFmtManifestTests

- (void)testJson {
    
    KyBookFmtManifest *m = [TestsHelpers sampleManifest];
    
    NSData *json = [m asJsonData:nil];
    XCTAssertNotNil(json);
    
    KyBookFmtManifest *test = [KyBookFmtManifest manifestFromJsonData:json error:nil];
    XCTAssertNotNil(test);
    
    XCTAssertEqual(test.version, m.version);
    XCTAssertEqual(test.kind, m.kind);
    XCTAssertEqualObjects(test.title, m.title);
    XCTAssertEqualObjects(test.subtitle, m.subtitle);
    XCTAssertEqualObjects(test.authors, m.authors);
    XCTAssertEqualObjects(test.translators, m.translators);
    XCTAssertEqualObjects(test.subjects, m.subjects);
    XCTAssertEqualObjects(test.ids, m.ids);
    XCTAssertEqualObjects(test.sequence, m.sequence);
    XCTAssertEqual(test.sequenceNo, m.sequenceNo);
    XCTAssertEqualObjects(test.isbn, m.isbn);
    XCTAssertEqualObjects(test.link, m.link);
    XCTAssertEqualObjects(test.rights, m.rights);
    XCTAssertEqualObjects(test.publisher, m.publisher);
    XCTAssertEqualObjects(test.date, m.date);
    XCTAssertEqualObjects(test.language, m.language);
    XCTAssertEqualObjects(test.keywords, m.keywords);
    XCTAssertEqualObjects(test.annotation, m.annotation);
    XCTAssertEqualObjects(test.cover, m.cover);
    XCTAssertEqualObjects(test.thumbnail, m.thumbnail);
    XCTAssertEqualObjects(test.creator, m.creator);
    XCTAssertEqualObjects(test.timestamp, m.timestamp);
    XCTAssertEqualObjects(test.extra, m.extra);
}

@end
