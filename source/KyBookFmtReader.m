//
//  KyBookFmtReader.m
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

#import "KyBookFmtReader.h"
#import "KyBookFmtItem_Private.h"
#import "KyBookFmtManifest.h"
#import "KyBookFmtUtils.h"
#import "KxTarArchiveReader.h"

@implementation KyBookFmtReader

+ (instancetype) readerWithPath:(NSString *)path
{
    return [self readerWithPath:path withContent:NO error:nil];
}

+ (instancetype) readerWithPath:(NSString *)path
                    withContent:(BOOL)withContent
                          error:(NSError **)error
{
    NSArray *entries = [KxTarArchiveReader entriesWithPath:path
                                               withContent:withContent
                                                     error:error];
    if (!entries) {
        return nil;
    }
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:entries.count];
    
    for (KxTarArchiveReaderEntry *entry in entries) {
        
        KyBookFmtItem *item = [KyBookFmtItem new];
        item.path = entry.path;
        item.offset = entry.offset;
        item.size = entry.size;
        item.content = entry.content;
        item.filePath = path;
        [items addObject:item];
    }
    
    return [[self alloc] initWithPath:path items:[items copy]];
}

- (instancetype) initWithPath:(NSString *)path
                        items:(NSArray *)items
{
    if ((self = [super init])) {
        
        _filePath = path;
        _items = items;
    }
    return self;
}

- (KyBookFmtItem *) itemOfKind:(KyBookFmtItemKind)kind
{
    for (KyBookFmtItem *item in _items) {
        if (item.kind == kind) {
            return item;
        }
    }
    return nil;
}

- (NSArray<KyBookFmtItem *> *) itemsOfKind:(KyBookFmtItemKind)kind
{
    NSMutableArray *result = [NSMutableArray array];
    for (KyBookFmtItem *item in _items) {
        if (item.kind == kind) {
            [result addObject:item];
        }
    }
    return result;
}

- (KyBookFmtItem *) itemWithPath:(NSString *)path
{
    for (KyBookFmtItem *item in _items) {
        if (NSOrderedSame == [item.path compare:path options:NSCaseInsensitiveSearch]) {
            return item;
        }
    }
    return nil;
}

- (KyBookFmtManifest *) readManifest:(NSError **)error
{
    NSData *content = [self dataOfItemKind:KyBookFmtItemKindManifest error:error];
    if (!content) {
        return nil;
    }
    return [KyBookFmtManifest manifestFromJsonData:content error:error];
}

- (NSArray<NSString *> *) readIndex:(NSError **)error
{
    id val = [self valueOfItemKind:KyBookFmtItemKindIndex error:error];
    if (!val ||
        ![val isKindOfClass:[NSArray class]] ||
        ![KyBookFmtUtils probeCollection:val itemClass:[NSString class]])
    {
        return nil;
    }
    return val;
}

- (NSArray<NSDictionary *> *) readToc:(NSError **)error
{
    id val = [self valueOfItemKind:KyBookFmtItemKindToc error:error];
    if (!val ||
        ![val isKindOfClass:[NSArray class]] ||
        ![KyBookFmtUtils probeCollection:val itemClass:[NSDictionary class]])
    {
        return nil;
    }
    return val;
}

- (NSArray<NSDictionary *> *) readGuide:(NSError **)error
{
    id val = [self valueOfItemKind:KyBookFmtItemKindGuide error:error];
    if (!val ||
        ![val isKindOfClass:[NSArray class]] ||
        ![KyBookFmtUtils probeCollection:val itemClass:[NSDictionary class]])
    {
        return nil;
    }
    return val;
}

- (NSData *) readDataOfItem:(NSString *)path
                      error:(NSError **)error
{
    KyBookFmtItem *item = [self itemWithPath:path];
    if (!item) {
        return nil;
    }
    return item.content;
}

- (NSString *) readTextOfItem:(NSString *)path
                        error:(NSError **)error
{
    NSData *content = [self readDataOfItem:path error:error];
    if (!content) {
        return nil;
    }
    return [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
}

#pragma mark - private

- (NSData *) dataOfItemKind:(KyBookFmtItemKind)kind
                      error:(NSError **)error
{
    KyBookFmtItem *item = [self itemOfKind:kind];
    if (!item) {
        return nil;
    }
    return item.content;
}

- (id) valueOfItemKind:(KyBookFmtItemKind)kind
                 error:(NSError **)error
{
    NSData *content = [self dataOfItemKind:kind error:error];
    if (!content) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:content options:0 error:error];
}

@end
