//
//  KoobmarkController.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 10.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "KoobmarkController.h"
#import <KyBookFmtKit/KyBookFmtKit.h>

@interface KoobmarkController() <KoobmarkParserDelegate>

@end

@implementation KoobmarkController {
    
    NSMutableString *_result;
}

- (id) init
{
    if ((self = [self initWithNibName:nil bundle:nil])) {
        self.title = @"Demo";
        
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_filePath) {
        [self loadKoobmark:_filePath];
    }
    
    //[self parseKoobmark:@"{b{i{s{}}}}"];
}

- (void) loadKoobmark:(NSString *)path
{
    NSString *text = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    
    NSString *html = [KoobmarkHtmlRender htmlStringFromKoobmarkText:text];
    NSLog(@"%@", html);
    
    //[self parseKoobmark:text];
}

- (void) parseKoobmark:(NSString *)text
{
    _result = [NSMutableString new];
    
    KoobmarkParser *parser = [KoobmarkParser parserWithText:text];
    parser.delegate = self;
    
    if ([parser parse]) {
        
        NSLog(@"%@", _result);
    }
}

#pragma mark - KoobmarkParserDelegate

- (void) koobmarkParser:(KoobmarkParser *)parser pushPragma:(KoobmarkPragma *)pragma
{
    [_result appendFormat:@"{%@", pragma.tagName];
    if (pragma.argument.length) {
        [_result appendString:pragma.argument];
    }
    [_result appendString:@" "];
}

- (void) koobmarkParser:(KoobmarkParser *)parser popPragma:(KoobmarkPragma *)pragma
{
    //[_result appendString:@"}"];
    [_result appendFormat:@"/%@}", pragma.tagName];
    if (pragma.tag > KoobmarkTagNone && pragma.tag < KoobmarkTagSpan) {
        [_result appendString:@"\n"];
    }
}

- (void) koobmarkParser:(KoobmarkParser *)parser characters:(NSString *)text
{
    [_result appendString:text];
}

@end
