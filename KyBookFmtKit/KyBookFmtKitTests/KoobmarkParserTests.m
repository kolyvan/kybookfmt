//
//  KoobmarkParserTests.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KoobmarkParser.h"
#import "KoobmarkParserText.h"
#import "TestsHelpers.h"

@interface KoobmarkParserTests : XCTestCase
@end

@implementation KoobmarkParserTests

- (void)testBrackets {

    NSString *res = [KoobmarkParserText parseKoobmark:@""];
    XCTAssertEqualObjects(res, @"");
    
    res = [KoobmarkParserText parseKoobmark:@"{}"];
    XCTAssertEqualObjects(res, @"{}");
    
    res = [KoobmarkParserText parseKoobmark:@"{{}}"];
    XCTAssertEqualObjects(res, @"{{}}");
    
    res = [KoobmarkParserText parseKoobmark:@"{x}"];
    XCTAssertEqualObjects(res, @"{}");
    
    res = [KoobmarkParserText parseKoobmark:@"{ x }"];
    XCTAssertEqualObjects(res, @"{ x }");
    
    res = [KoobmarkParserText parseKoobmark:@"{{ x }}"];
    XCTAssertEqualObjects(res, @"{{ x }}");
    
    res = [KoobmarkParserText parseKoobmark:@"{"];
    XCTAssertEqualObjects(res, @"{}");
    
    res = [KoobmarkParserText parseKoobmark:@"}"];
    XCTAssertEqualObjects(res, @"}");
}

- (void)testSimple {
    
    NSString *res = [KoobmarkParserText parseKoobmark:@"{h}"];
    XCTAssertEqualObjects(res, @"{h}");
    
    res = [KoobmarkParserText parseKoobmark:@"{h abcdef}"];
    XCTAssertEqualObjects(res, @"{h abcdef}");
    
    res = [KoobmarkParserText parseKoobmark:@"{h{t1{@google.com abc}}}{%main{.red hello}{i word}}"];
    XCTAssertEqualObjects(res, @"{h{t1{@google.com abc}}}{%main{.red hello}{i word}}");
}

@end
