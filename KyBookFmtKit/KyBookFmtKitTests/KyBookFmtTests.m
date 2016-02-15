//
//  KyBookFmtTests.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KyBookFmtReader.h"
#import "KyBookFmtManifest.h"
#import "TestsHelpers.h"

@interface KyBookFmtTests : XCTestCase
@end

@implementation KyBookFmtTests

- (void)testReader {
    
    NSString *filePath = [TestsHelpers bundleFileWithPath:@"sample.tar"];
    KyBookFmtReader *reader = [KyBookFmtReader readerWithPath:filePath];
    XCTAssertNotNil(reader);
    XCTAssertEqual(reader.items.count, 9);
    
    KyBookFmtManifest *manifest = [reader readManifest:nil];
    XCTAssertNotNil(manifest);
    XCTAssertEqual(manifest.version, 1);
    XCTAssertEqualObjects(manifest.title, @"Sample KyBook Format");
    XCTAssertEqualObjects(manifest.creator, @"Kolyvan");
    
    NSArray *index = [reader readIndex:nil];
    XCTAssertEqual(index.count, 7);
    
    KyBookFmtItem *item = [reader itemOfKind:KyBookFmtItemKindManifest];
    XCTAssertNotNil(item);
    
    item = [reader itemOfKind:KyBookFmtItemKindIndex];
    XCTAssertNotNil(item);
    
    id indexVal = [NSJSONSerialization JSONObjectWithData:item.content options:0 error:nil];
    XCTAssertNotNil(item);
    XCTAssertEqualObjects(indexVal, index);
}

@end
