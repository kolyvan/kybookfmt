//
//  KoobmarkParserText.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "KoobmarkParserText.h"

@implementation KoobmarkParserText {
    
    BOOL _needSpace;
}

+ (NSString *) parseKoobmark:(NSString *)text
{
    KoobmarkParserText *delegate = [KoobmarkParserText new];
    KoobmarkParser *parser = [KoobmarkParser parserWithText:text];
    parser.delegate = delegate;
    if (![parser parse]) {
        return nil;
    }
    return [delegate.text copy];
}

- (instancetype) init
{
    if ((self = [super init])) {
        _text = [NSMutableString string];
    }
    return self;
}

- (void) koobmarkParser:(nonnull KoobmarkParser *)parser pushPragma:(nonnull KoobmarkPragma *)pragma
{    
    [_text appendFormat:@"{%@", pragma.tagName];
    if (pragma.argument.length) {
        [_text appendString:pragma.argument];
    }
    _needSpace = YES;
}

- (void) koobmarkParser:(nonnull KoobmarkParser *)parser popPragma:(nonnull KoobmarkPragma *)pragma
{
    [_text appendString:@"}"];
    _needSpace = NO;
}

- (void) koobmarkParser:(nonnull KoobmarkParser *)parser characters:(nonnull NSString *)text
{
    if (_needSpace) {
        _needSpace = NO;
        [_text appendString:@" "];
    }
    
    [_text appendString:text];
}

@end
