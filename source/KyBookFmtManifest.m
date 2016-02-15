//
//  KyBookFmtManifest.m
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 05.02.16.
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

#import "KyBookFmtManifest.h"
#import "KyBookFmtUtils.h"


@implementation KyBookFmtManifest

+ (instancetype) manifestFromJsonData:(NSData *)json
                                error:(NSError **)error
{
    id val = [NSJSONSerialization JSONObjectWithData:json
                                             options:0
                                               error:error];
    
    if(!val || ![val isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return [self manifestFromDictionary:val];
}

+ (instancetype) manifestFromDictionary:(NSDictionary *)dict
{
    KyBookFmtManifest *p = [KyBookFmtManifest new];
    
    p.version       = [dict kx_numberForKey:@"version"].unsignedIntegerValue;
    p.title         = [dict kx_stringForKey:@"title"];
    p.subtitle      = [dict kx_stringForKey:@"subtitle"];
    p.authors       = [dict kx_arrayForKey:@"authors" itemClass:[NSString class]];
    p.translators   = [dict kx_arrayForKey:@"translators" itemClass:[NSString class]];
    p.subjects      = [dict kx_arrayForKey:@"subjects" itemClass:[NSString class]];
    p.ids           = [dict kx_arrayForKey:@"ids" itemClass:[NSString class]];
    p.sequence      = [dict kx_stringForKey:@"sequence"];
    p.sequenceNo    = [dict kx_numberForKey:@"sequenceNo"].unsignedIntegerValue;
    p.isbn          = [dict kx_stringForKey:@"isbn"];
    p.link          = [dict kx_stringForKey:@"link"];
    p.rights        = [dict kx_stringForKey:@"rights"];
    p.publisher     = [dict kx_stringForKey:@"publisher"];
    p.date          = [dict kx_stringForKey:@"date"];
    p.language      = [dict kx_stringForKey:@"language"];
    p.keywords      = [dict kx_stringForKey:@"keywords"];
    p.annotation    = [dict kx_stringForKey:@"annotation"];
    p.cover         = [dict kx_stringForKey:@"cover"];
    p.thumbnail     = [dict kx_stringForKey:@"thumbnail"];
    p.creator       = [dict kx_stringForKey:@"creator"];
    p.timestamp     = [dict kx_stringForKey:@"timestamp"];
    p.extra         = [dict kx_valueForKey:@"extra" ofClass:[NSDictionary class]];
    
    id val = dict[@"kind"];
    if ([val isKindOfClass:[NSNumber class]]) {
        p.kind = ((NSNumber *)val).unsignedIntegerValue;
    } else if ([val isKindOfClass:[NSString class]]) {
        if ([val isEqualToString:@"text"] || [val isEqualToString:@"textbook"]) {
            p.kind = KyBookFmtKindTextBook;
        } else if ([val isEqualToString:@"audio"] || [val isEqualToString:@"audiobook"]) {
            p.kind = KyBookFmtKindAudioBook;
        } else if ([val isEqualToString:@"comics"] || [val isEqualToString:@"cartoon"]) {
            p.kind = KyBookFmtKindComicsBook;
        }
    }
    
    return p;
}

- (NSData *) asJsonData:(NSError **)error
{
    NSDictionary *dict = self.asDictionary;
    if (!dict) {
        return nil;
    }
    
    return [NSJSONSerialization dataWithJSONObject:dict
                                           options:NSJSONWritingPrettyPrinted
                                             error:error];
}

- (NSDictionary *) asDictionary
{
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if (_version)               { md[@"version"]        = @(_version); }
    if (_title.length)          { md[@"title"]          = _title; }
    if (_subtitle.length)       { md[@"subtitle"]       = _subtitle; }
    if (_authors.count)         { md[@"authors"]        = _authors; }
    if (_translators.count)     { md[@"translators"]    = _translators; }
    if (_subjects.count)        { md[@"subjects"]       = _subjects; }
    if (_ids.count)             { md[@"ids"]            = _ids; }
    if (_sequence.length)       { md[@"sequence"]       = _sequence; }
    if (_sequenceNo)            { md[@"sequenceNo"]     = @(_sequenceNo); }
    if (_isbn.length)           { md[@"isbn"]           = _isbn; }
    if (_link.length)           { md[@"link"]           = _link; }
    if (_rights.length)         { md[@"rights"]         = _rights; }
    if (_publisher.length)      { md[@"publisher"]      = _publisher; }
    if (_date.length)           { md[@"date"]           = _date; }
    if (_language.length)       { md[@"language"]       = _language; }
    if (_keywords.length)       { md[@"keywords"]       = _keywords; }
    if (_annotation.length)     { md[@"annotation"]     = _annotation; }
    if (_cover.length)          { md[@"cover"]          = _cover; }
    if (_thumbnail.length)      { md[@"thumbnail"]      = _thumbnail; }
    if (_creator.length)        { md[@"creator"]        = _creator; }
    if (_timestamp.length)      { md[@"timestamp"]     = _timestamp; }
    if (_extra.count)           { md[@"extra"]          = _extra; }

    switch (_kind) {
        case KyBookFmtKindCommonBook:   break;
        case KyBookFmtKindTextBook:     md[@"kind"] = @"textbook"; break;
        case KyBookFmtKindAudioBook:    md[@"kind"] = @"audiobook"; break;
        case KyBookFmtKindComicsBook:   md[@"kind"] = @"comics"; break;
    }

    return [md copy];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<manifest %@>", self.asDictionary];
}

@end
