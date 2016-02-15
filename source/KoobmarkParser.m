//
//  KoobmarkParser.m
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 10.02.16.
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

#import "KoobmarkParser.h"

//////////

@interface NSString(KoobmarkParser)
- (NSUInteger) koobmark_numberOfLinesAtLocatation:(NSUInteger)location charPos:(NSUInteger *)charPos;
- (NSString *) koobmark_collapseWhitespacesAndNewlines;
@end

//////////

@interface NSScanner(KoobmarkParser)
- (BOOL)koobmark_scanOneCharacterFromSet:(NSCharacterSet *)set
                              intoString:(NSString **)result;
@end

//////////

@interface KoobmarkPragma()
- (instancetype) initWithTag:(KoobmarkTag)tag argument:(NSString *)argument;
+ (NSUInteger) tagWithName:(NSString *)name;
+ (NSString *) nameOfTag:(KoobmarkTag)tag;
+ (BOOL) tagCouldHasArgs:(KoobmarkTag)tag;
@end

//////////

@implementation KoobmarkParser {
    
    NSString        *_text;
    NSMutableArray  *_stack;
    BOOL            _abortParsing;
}

+ (instancetype) parserWithData:(NSData *)data
{
    return [self parserWithText:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}

+ (instancetype) parserWithText:(NSString *)text
{
    return [[self alloc] initWithText:text];
}

- (instancetype) initWithText:(NSString *)text
{
    if ((self = [super init])) {
        _text = text;
        _collapseWhitespaces = YES;
    }
    return self;
}

- (NSArray *) pragmaStack
{
    return [_stack copy];
}

- (BOOL) parse
{
    id<KoobmarkParserDelegate> delegate = self.delegate;
    if (!delegate) {
        return YES;
    }
    
    if (!_text.length) {
        return YES;
    }
    
    _stack = [NSMutableArray new];
    
    NSCharacterSet *brackets = [self.class bracketsCharset];
    NSCharacterSet *commandTerm =  [self.class commandTermCharset];
    
    NSScanner *scanner = [NSScanner scannerWithString:_text];
    scanner.charactersToBeSkipped = nil;
    
    while (!scanner.isAtEnd) {

        NSString *text;
        [scanner scanUpToCharactersFromSet:brackets intoString:&text];
        
        NSString *bracket;
        if ([scanner koobmark_scanOneCharacterFromSet:brackets intoString:&bracket]) {
            
            // is backslash escaped?
            if (text.length && [text hasSuffix:@"\\"]) {
                if (text.length > 1) {
                    text = [text substringToIndex:text.length - 1];
                    text = [text stringByAppendingString:bracket];
                } else {
                    text = bracket;
                }
                bracket = nil;
            }
        }
        
        if (text.length) {
            
            if (_collapseWhitespaces && ![self pragmaStackHasCodeTag]) {
                text = text.koobmark_collapseWhitespacesAndNewlines;
            }
            
            [delegate koobmarkParser:self characters:text];
            if (_abortParsing) {
                return NO;
            }
        }
        
        if (bracket) {
            
            // {% } {t1 text} {~} {}
            
            if ([bracket isEqualToString:@"{"]) {
                
                KoobmarkPragma *pragma;
                NSString *commandString, *termString;
                
                [scanner scanUpToCharactersFromSet:commandTerm intoString:&commandString];
                if ([scanner koobmark_scanOneCharacterFromSet:commandTerm intoString:&termString]) {
                    
                    if ([termString isEqualToString:@"{"]||
                        [termString isEqualToString:@"}"])
                    {
                        scanner.scanLocation -= 1; // pushback
                    }
                }
                                
                NSString *tagName = commandString.length > 1 ? [commandString substringToIndex:1] : commandString;
                const NSUInteger tagid = [KoobmarkPragma tagWithName:tagName];
                
                if (tagid == NSNotFound) {
                    
                    [self fireWarning:[NSString stringWithFormat:@"bad tag {%@}", tagName]
                             location:scanner.scanLocation-1];
                    
                    // handle unknown tag as none
                    pragma = [[KoobmarkPragma alloc] initWithTag:KoobmarkTagNone argument:nil];
                    
                } else {
                    
                    NSString *argument = commandString.length > 1 ? [commandString substringFromIndex:1] : nil;
                    
                    if (![KoobmarkPragma tagCouldHasArgs:tagid] && argument.length) {
                        
                        [self fireWarning:[NSString stringWithFormat:@"odd argument {%@%@}", tagName, argument]
                                 location:scanner.scanLocation-1];
                    }
                    
                    pragma = [[KoobmarkPragma alloc] initWithTag:tagid argument:argument];
                }
                
                [_stack addObject:pragma];
                [delegate koobmarkParser:self pushPragma:pragma];
                
            } else if ([bracket isEqualToString:@"}"]) {
                
                if (_stack.count) {
                
                    KoobmarkPragma *last = _stack.lastObject;
                    [_stack removeLastObject];
                    [delegate koobmarkParser:self popPragma:last];
                    
                } else {
                    
                    [self fireWarning:@"odd bracket" location:scanner.scanLocation-1];
                    [delegate koobmarkParser:self characters:bracket];
                }
            }
            
            if (_abortParsing) {
                return NO;
            }
        }
    }
    
    if (_stack.count) {
        
        [self fireWarning:@"pragma stack is not empty" location:_text.length];
        
        while (_stack.count) {
        
            KoobmarkPragma *last = _stack.lastObject;
            [_stack removeLastObject];
            [delegate koobmarkParser:self popPragma:last];
        }
    }
    
    return YES;
}

- (void) abortParsing
{
    _abortParsing = YES;
}

- (void) fireWarning:(NSString *)warning location:(NSUInteger)location
{
    NSUInteger charPos = 0;
    const NSUInteger lineNum = [_text koobmark_numberOfLinesAtLocatation:location
                                                                 charPos:&charPos];
    
    id<KoobmarkParserDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(koobmarkParser:warning:lineNum:charPos:)]) {
        [delegate koobmarkParser:self warning:warning lineNum:lineNum+1 charPos:charPos+1];
    } else {
        NSLog(@"at:%zd pos:%zd - %@", lineNum + 1, charPos + 1, warning);
    }
}

- (BOOL) pragmaStackHasCodeTag
{
    for (KoobmarkPragma *pragma in _stack) {
        if (pragma.tag == KoobmarkTagCode) {
            return YES;
        }
    }
    return  NO;
}

+ (NSCharacterSet *) bracketsCharset {

    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charset = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
    });
    return charset;
}

+ (NSCharacterSet *) commandTermCharset
{
    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *m = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [m addCharactersInString:@"{}"];
        charset = [m copy];
    });
    return charset;
}

@end

//////////

@implementation KoobmarkPragma

- (instancetype) initWithTag:(KoobmarkTag)tag argument:(NSString *)argument
{
    if ((self = [super init])) {
        _tag = tag;
        _argument = argument;
    }
    return self;
}

@dynamic tagName;
- (NSString *)tagName
{
    return [KoobmarkPragma nameOfTag:_tag];
}

+ (NSUInteger) tagWithName:(NSString *)name
{
    if (name.length == 0) {
        return KoobmarkTagNone;
    } else if (name.length > 1) {
        return NSNotFound;
    }
    
    const unichar letter = [name characterAtIndex:0];
    switch (letter) {
        case '%':   return KoobmarkTagBlock;
        case 182: // ¶
        case 'p':   return KoobmarkTagPara;
        case 'h':   return KoobmarkTagHeader;
        case 't':   return KoobmarkTagTitle;
        case 'f':   return KoobmarkTagFooter;
        case 'q':   return KoobmarkTagQuote;
        case ';':   return KoobmarkTagCode;
        case '~':   return KoobmarkTagBreak;
        case '+':   return KoobmarkTagOrdItem;
        case '*':   return KoobmarkTagUnordItem;
        case '=':   return KoobmarkTagTable;
        case '-':   return KoobmarkTagTableRow;
        case '|':   return KoobmarkTagTableCell;
        case '.':   return KoobmarkTagSpan;
        case 'b':   return KoobmarkTagStrong;
        case 'i':   return KoobmarkTagEmphasis;
        case 'u':   return KoobmarkTagUnderline;
        case 's':   return KoobmarkTagStrikeout;
        case '^':   return KoobmarkTagSup;
        case ',':   return KoobmarkTagSub;
        case '#':   return KoobmarkTagAnchor;
        case '@':   return KoobmarkTagLink;
        case '?':   return KoobmarkTagNote;
        case '&':   return KoobmarkTagImage;
        case '$':   return KoobmarkTagMedia;
        default:    return NSNotFound;
    }
}

+ (NSString *) nameOfTag:(KoobmarkTag)tag
{
    switch (tag) {
        case KoobmarkTagNone:       return @"";
        case KoobmarkTagBlock:      return @"%";
        case KoobmarkTagPara:       return @"¶";
        case KoobmarkTagHeader:     return @"h";
        case KoobmarkTagTitle:      return @"t";
        case KoobmarkTagFooter:     return @"f";
        case KoobmarkTagQuote:      return @"q";
        case KoobmarkTagCode:       return @";";
        case KoobmarkTagBreak:      return @"~";
        case KoobmarkTagOrdItem:    return @"+";
        case KoobmarkTagUnordItem:  return @"*";
        case KoobmarkTagTable:      return @"=";
        case KoobmarkTagTableRow:   return @"-";
        case KoobmarkTagTableCell:  return @"|";
        case KoobmarkTagSpan:       return @".";
        case KoobmarkTagStrong:     return @"b";
        case KoobmarkTagEmphasis:   return @"i";
        case KoobmarkTagUnderline:  return @"u";
        case KoobmarkTagStrikeout:  return @"s";
        case KoobmarkTagSup:        return @"^";
        case KoobmarkTagSub:        return @",";
        case KoobmarkTagAnchor:     return @"#";
        case KoobmarkTagLink:       return @"@";
        case KoobmarkTagNote:       return @"?";
        case KoobmarkTagImage:      return @"&";
        case KoobmarkTagMedia:      return @"$";
    }
}

+ (BOOL) tagCouldHasArgs:(KoobmarkTag)tag
{
    switch (tag) {
        case KoobmarkTagNone:       return NO;
        case KoobmarkTagBlock:      return YES;
        case KoobmarkTagPara:       return NO;
        case KoobmarkTagHeader:     return NO;
        case KoobmarkTagTitle:      return YES;
        case KoobmarkTagFooter:     return NO;
        case KoobmarkTagQuote:      return NO;
        case KoobmarkTagCode:       return YES;
        case KoobmarkTagBreak:      return NO;
        case KoobmarkTagOrdItem:    return NO;
        case KoobmarkTagUnordItem:  return NO;
        case KoobmarkTagTable:      return NO;
        case KoobmarkTagTableRow:   return NO;
        case KoobmarkTagTableCell:  return NO;
        case KoobmarkTagSpan:       return YES;
        case KoobmarkTagStrong:     return NO;
        case KoobmarkTagEmphasis:   return NO;
        case KoobmarkTagUnderline:  return NO;
        case KoobmarkTagStrikeout:  return NO;
        case KoobmarkTagSup:        return NO;
        case KoobmarkTagSub:        return NO;
        case KoobmarkTagAnchor:     return YES;
        case KoobmarkTagLink:       return YES;
        case KoobmarkTagNote:       return YES;
        case KoobmarkTagImage:      return YES;
        case KoobmarkTagMedia:      return YES;
    }
}

@end

//////////

@implementation NSString(KoobmarkParser)

- (NSUInteger) koobmark_numberOfLinesAtLocatation:(NSUInteger)location charPos:(NSUInteger *)charPos
{
    NSUInteger lineNum = 0;
    NSUInteger loc = 0;
    while (loc < location) {
        
        const NSRange r = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                                options:0
                                                  range:NSMakeRange(loc, location - loc)];
        
        if (r.location == NSNotFound) {
            break;
        } else {
            lineNum += 1;
            loc = NSMaxRange(r); // skip newline
        }
    }
    
    if (charPos) {
        *charPos = location - loc - 1;
    }
    
    return lineNum;
}

- (NSString *) koobmark_collapseWhitespacesAndNewlines
{
    if (!self.length) {
        return self;
    }
    
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    
    static NSCharacterSet *whites;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *m = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [m removeCharactersInRange:NSMakeRange(0xa0, 1)]; // No-Break Space
        whites = [m copy];
    });
        
    BOOL needTrim = NO;
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = nil;
    
    [scanner scanUpToCharactersFromSet:newlines intoString:nil];
    if ([scanner scanCharactersFromSet:newlines intoString:nil]) {
        
        needTrim = true;
        
    } else {
        
        scanner.scanLocation = 0;
        NSUInteger scanLocation = 0;
        
        while (!scanner.atEnd) {
            
            if ([scanner scanCharactersFromSet:whites intoString:nil]) {
                
                if ((scanner.scanLocation - scanLocation) > 1) {
                    needTrim = YES;
                    break;
                }
            }
            
            if ([scanner scanUpToCharactersFromSet:whites intoString:nil]) {
                scanLocation = scanner.scanLocation;
            }
        }
    }
    
    if (!needTrim) {
        return self;
    }
    
    NSMutableString *buffer = [[NSMutableString alloc] initWithCapacity:self.length];
    
    scanner.scanLocation = 0;
    while (!scanner.isAtEnd) {
        
        if ([scanner scanCharactersFromSet:whites intoString:NULL]) {
            if (buffer.length) {
                [buffer appendString:@" "];
            }
        }
                
        NSString *s;
        if ([scanner scanUpToCharactersFromSet:whites intoString:&s]) {
            [buffer appendString:s];
        }
    }
    
    return buffer;
}

@end

//////////

@implementation NSScanner(KoobmarkParser)

- (BOOL)koobmark_scanOneCharacterFromSet:(NSCharacterSet *)set
                                    intoString:(NSString **)result
{
    NSString *string = self.string;
    const NSUInteger scanLoc = self.scanLocation;
    if (scanLoc < string.length) {
        
        const unichar ch = [string characterAtIndex:scanLoc];
        if ([set characterIsMember:ch]) {
            if (result) {
                *result = [string substringWithRange:NSMakeRange(scanLoc, 1)];
            }
            self.scanLocation = scanLoc + 1;
            return YES;
        }
    }
    return NO;
}

@end
