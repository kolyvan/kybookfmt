//
//  KxTarArchiveTests.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KxTarArchiveReader.h"
#import "KxTarArchiveWriter.h"
#import "TestsHelpers.h"

@interface KxTarArchiveTests : XCTestCase
@end

@implementation KxTarArchiveTests

- (void)testReader {
    
    NSString *tarPath = [TestsHelpers bundleFileWithPath:@"sample.tar"];
    NSArray *entries = [KxTarArchiveReader entriesWithPath:tarPath withContent:NO error:nil];
    XCTAssertEqual(entries.count, 9);
}

- (void)testReaderWriter {
    
    NSString *tmpPath = [TestsHelpers tmpFilePath];
    
    KxTarArchiveWriter *writer = [KxTarArchiveWriter writerWithPath:tmpPath error:nil];
    XCTAssertNotNil(writer);
    
    NSArray<NSString *> *texts = [TestsHelpers sampleTexts];
    
    NSUInteger counter = 0;
    for (NSString *text in texts) {
        
        BOOL res = [writer writeData:[text dataUsingEncoding:NSUTF8StringEncoding]
                                path:[@"text" stringByAppendingFormat:@"%zd", counter]
                               error:nil];
        
        XCTAssertEqual(res, YES);
        
        counter += 1;
    }
    
    [writer closeWriter];
    
    NSArray *entries = [KxTarArchiveReader entriesWithPath:tmpPath withContent:YES error:nil];
    XCTAssertEqual(texts.count, entries.count);
    
    counter = 0;
    for (KxTarArchiveReaderEntry *entry in entries) {
    
        NSString *path = [@"text" stringByAppendingFormat:@"%zd", counter];
        XCTAssertEqualObjects(entry.path, path);
        
        XCTAssertNotNil(entry.content);
        
        NSString *text = [[NSString alloc] initWithData:entry.content encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(text, texts[counter]);
        
        counter += 1;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
}

@end
