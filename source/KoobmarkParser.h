//
//  KoobmarkParser.h
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KoobmarkTag) {
    
    KoobmarkTagNone,                // no or unknown tag
    
    // blocks
    KoobmarkTagBlock,               // %_ common block, style
    KoobmarkTagPara,                // p paragraph or ¶
    KoobmarkTagHeader,              // h header
    KoobmarkTagTitle,               // t_ title, level
    KoobmarkTagFooter,              // f footer
    KoobmarkTagQuote,               // q quotation
    KoobmarkTagCode,                // ;_ code, lang
    KoobmarkTagBreak,               // ~ hr
    KoobmarkTagOrdItem,             // + ordered list item
    KoobmarkTagUnordItem,           // * unordered list item
    KoobmarkTagTable,               // = table
    KoobmarkTagTableRow,            // - table row
    KoobmarkTagTableCell,           // | table cell
    
    // spans
    KoobmarkTagSpan,                // ._ span, style
    KoobmarkTagStrong,              // b strong
    KoobmarkTagEmphasis,            // i emphasis
    KoobmarkTagUnderline,           // u underline
    KoobmarkTagStrikeout,           // s strikeout
    KoobmarkTagSup,                 // ^ sup
    KoobmarkTagSub,                 // , sub
    
    // navigation/resources
    KoobmarkTagAnchor,              // #_ anchor, id
    KoobmarkTagLink,                // @_ link, url
    KoobmarkTagNote,                // ?_ note, url
    KoobmarkTagImage,               // &_ image, url
    KoobmarkTagMedia,               // $_ media, url
};

@interface KoobmarkPragma : NSObject
@property (readonly, nonatomic) KoobmarkTag tag;
@property (readonly, nonatomic, strong, nullable) NSString *argument;
@property (readonly, nonatomic, strong, nullable) NSString *tagName;

+ (NSUInteger) tagWithName:(nonnull NSString *)name;
+ (nonnull NSString *) nameOfTag:(KoobmarkTag)tag;
@end

@protocol KoobmarkParserDelegate;

@interface KoobmarkParser : NSObject
@property (readonly, nonatomic, strong, nonnull) NSArray *pragmaStack;
@property (readwrite, nonatomic, weak, nullable) id<KoobmarkParserDelegate> delegate;
@property (readwrite, nonatomic) BOOL collapseWhitespaces;

+ (nonnull instancetype) parserWithData:(nonnull NSData *)data;
+ (nonnull instancetype) parserWithText:(nonnull NSString *)text;
- (BOOL) parse;
- (void) abortParsing;
@end

@protocol KoobmarkParserDelegate<NSObject>
- (void) koobmarkParser:(nonnull KoobmarkParser *)parser pushPragma:(nonnull KoobmarkPragma *)pragma;
- (void) koobmarkParser:(nonnull KoobmarkParser *)parser popPragma:(nonnull KoobmarkPragma *)pragma;
- (void) koobmarkParser:(nonnull KoobmarkParser *)parser characters:(nonnull NSString *)text;

@optional
- (void) koobmarkParser:(nonnull KoobmarkParser *)parser
                warning:(nonnull NSString *)warning
                lineNum:(NSUInteger)lineNum
                charPos:(NSUInteger)charPos;
@end
