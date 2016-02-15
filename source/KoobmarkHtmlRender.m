//
//  KoobmarkHtmlRender.m
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 11.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

/*
 Copyright (c) 2016 Konstantin Bukreev All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "KoobmarkHtmlRender.h"
#import "KoobmarkParser.h"

typedef NS_ENUM(NSUInteger, KoobmarkHtmlRenderListStack) {
    KoobmarkHtmlRenderListStackItem,
    KoobmarkHtmlRenderListStackOrd,
    KoobmarkHtmlRenderListStackUnord,
};

@interface KoobmarkHtmlRender() <KoobmarkParserDelegate>
@property (readonly, nonnull, strong) NSMutableString *html;
@end

@implementation KoobmarkHtmlRender {

    NSMutableArray<NSNumber *> *_listStack;
}

+ (NSData *) htmlDataFromKoobmarkData:(NSData *)data
{
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *html = [self htmlStringFromKoobmarkText:text];
    return [html dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *) htmlStringFromKoobmarkText:(NSString *)text
{
    KoobmarkHtmlRender *render = [KoobmarkHtmlRender new];
    KoobmarkParser *parser = [KoobmarkParser parserWithText:text];
    parser.delegate = render;
    
    [render.html appendString:@"<!doctype html><html><head><meta charset=\"UTF-8\"></head><body>\n"];
    
    if (![parser parse]) {
        return nil;
    }
    
    [render.html appendString:@"</body></html>"];
    
    return render.html;
}

- (instancetype) init
{
    if ((self = [super init])) {
        _html = [NSMutableString string];
        _listStack = [NSMutableArray array];
    }
    return self;
}

- (void) koobmarkParser:(nonnull KoobmarkParser *)parser pushPragma:(nonnull KoobmarkPragma *)pragma
{
    if (pragma.tag == KoobmarkTagBreak) {
        [_html appendString:@"<hr />"];
        return;
    }
    
    NSString *name = [self htmlTagName:pragma];
    if (name) {
        
        [self probeBeginList:pragma];
        
        [_html appendString:@"<"];
        [_html appendString:name];
        
        if (pragma.tag == KoobmarkTagLink)
        {
            [_html appendFormat:@" href='%@'", pragma.argument];
            
        } else if (pragma.tag == KoobmarkTagNote) {
            
            [_html appendFormat:@" class='note' href='%@'", pragma.argument];
            
        } else if (pragma.tag == KoobmarkTagImage) {
            
            [_html appendFormat:@" src='%@'", pragma.argument];
            
        } else if (pragma.tag == KoobmarkTagMedia) {
            
            [_html appendFormat:@" data='%@'", pragma.argument];
            
        } else if (pragma.tag == KoobmarkTagAnchor) {
            
            [_html appendFormat:@" id='%@'", pragma.argument];
            
        } else if (pragma.tag == KoobmarkTagBlock ||
                   pragma.tag == KoobmarkTagSpan)
        {
            if (pragma.argument.length) {
                [_html appendFormat:@" class='%@'", pragma.argument];
            }
        }
        
        [_html appendString:@">"];
        
        if (pragma.tag == KoobmarkTagCode) {
            
            [_html appendString:@"<code>\n"];
        }
        
    } else {
        
        [_html appendString:@"{"];
    }
}

- (void) koobmarkParser:(nonnull KoobmarkParser *)parser popPragma:(nonnull KoobmarkPragma *)pragma
{
    if (pragma.tag == KoobmarkTagBreak) {
        return;
    }
    
    NSString *name = [self htmlTagName:pragma];
    if (name) {
        
        [self probeEndList:pragma];
        
        if (pragma.tag == KoobmarkTagCode) {
            [_html appendString:@"</code>"];
        }
    
        [_html appendString:@"</"];
        [_html appendString:name];
        [_html appendString:@">"];
        
        if (pragma.tag > KoobmarkTagNone && pragma.tag < KoobmarkTagSpan) {
            [_html appendString:@"\n"];
        }
        
    } else {
        
        [_html appendString:@"}"];
    }
}

- (void) koobmarkParser:(nonnull KoobmarkParser *)parser characters:(nonnull NSString *)text
{
    if (text.length) {
        [_html appendString:text];
    }
}

- (void) probeBeginList:(KoobmarkPragma *)pragma
{
    if (pragma.tag == KoobmarkTagOrdItem ||
        pragma.tag == KoobmarkTagUnordItem)
    {
        if (_listStack.count == 0 ||
            _listStack.lastObject.unsignedIntegerValue == KoobmarkHtmlRenderListStackItem) {
            
            if (pragma.tag == KoobmarkTagOrdItem){
                [_html appendString:@"\n<ol>\n"];
                [_listStack addObject:@(KoobmarkHtmlRenderListStackOrd)];
            } else if (pragma.tag == KoobmarkTagUnordItem){
                [_html appendString:@"\n<ul>\n"];
                [_listStack addObject:@(KoobmarkHtmlRenderListStackUnord)];
            }
        }
        
        [_listStack addObject:@(KoobmarkHtmlRenderListStackItem)];
        
    } else if (_listStack.count) {
        
        const KoobmarkHtmlRenderListStack last = _listStack.lastObject.unsignedIntegerValue;
        
        if (last == KoobmarkHtmlRenderListStackOrd) {
            [_html appendString:@"</ol>\n"];
            [_listStack removeLastObject];
        } else if (last == KoobmarkHtmlRenderListStackUnord) {
            [_html appendString:@"</ul>\n"];
            [_listStack removeLastObject];
        }
    }
}

- (void) probeEndList:(KoobmarkPragma *)pragma
{
    if (_listStack.count) {
        
        const KoobmarkHtmlRenderListStack last = _listStack.lastObject.unsignedIntegerValue;
     
        if (last == KoobmarkHtmlRenderListStackOrd) {
            
            [_html appendString:@"</ol>\n"];
            [_listStack removeLastObject];
            
        } else if (last == KoobmarkHtmlRenderListStackUnord) {
            
            [_html appendString:@"</ul>\n"];
            [_listStack removeLastObject];
        }
        
        if ((pragma.tag == KoobmarkTagOrdItem ||
             pragma.tag == KoobmarkTagUnordItem) &&
            _listStack.count > 0 &&
            _listStack.lastObject.unsignedIntegerValue == KoobmarkHtmlRenderListStackItem)
        {
            [_listStack removeLastObject];
        }
    }
}

- (NSString *) htmlTagName:(KoobmarkPragma *)pragma
{
    switch (pragma.tag) {
        case KoobmarkTagNone:       break;
        case KoobmarkTagBlock:      return @"div";
        case KoobmarkTagPara:       return @"p";
        case KoobmarkTagHeader:     return @"header";
        case KoobmarkTagTitle:      return [@"h" stringByAppendingString:pragma.argument];
        case KoobmarkTagFooter:     return @"footer";
        case KoobmarkTagQuote:      return @"blockquote";
        case KoobmarkTagCode:       return @"pre";
        case KoobmarkTagBreak:      return @"hr";
        case KoobmarkTagOrdItem:    return @"li";
        case KoobmarkTagUnordItem:  return @"li";
        case KoobmarkTagTable:      return @"table";
        case KoobmarkTagTableRow:   return @"tr";
        case KoobmarkTagTableCell:  return @"td";
        case KoobmarkTagSpan:       return @"span";
        case KoobmarkTagStrong:     return @"strong";
        case KoobmarkTagEmphasis:   return @"i";
        case KoobmarkTagUnderline:  return @"u";
        case KoobmarkTagStrikeout:  return @"s";
        case KoobmarkTagSup:        return @"sup";
        case KoobmarkTagSub:        return @"sub";
        case KoobmarkTagAnchor:     return @"div";
        case KoobmarkTagLink:       return @"a";
        case KoobmarkTagNote:       return @"a";
        case KoobmarkTagImage:      return @"img";
        case KoobmarkTagMedia:      return @"object";
    }
    
    return nil;
}

@end
