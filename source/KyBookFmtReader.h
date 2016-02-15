//
//  KyBookFmtReader.h
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

#import <Foundation/Foundation.h>
#import "KyBookFmtItem.h"

@class KyBookFmtManifest;

@interface KyBookFmtReader : NSObject

@property (readonly, nonatomic, strong, nonnull) NSString *filePath;
@property (readonly, nonatomic, strong, nonnull) NSArray<KyBookFmtItem *> *items;

+ (nullable instancetype) readerWithPath:(nonnull NSString *)path;

+ (nullable instancetype) readerWithPath:(nonnull NSString *)path
                             withContent:(BOOL)withContent
                                   error:(NSError * _Nullable * _Nullable)error;

- (nullable KyBookFmtItem *) itemOfKind:(KyBookFmtItemKind)kind;
- (nonnull NSArray<KyBookFmtItem *> *) itemsOfKind:(KyBookFmtItemKind)kind;

- (nullable KyBookFmtItem *) itemWithPath:(nonnull NSString *)path;

- (nullable KyBookFmtManifest *) readManifest:(NSError * _Nullable * _Nullable)error;
- (nullable NSArray<NSString *> *) readIndex:(NSError * _Nullable * _Nullable)error;
- (nullable NSArray<NSDictionary *> *) readToc:(NSError * _Nullable * _Nullable)error;
- (nullable NSData *) readDataOfItem:(nonnull NSString *)path error:(NSError * _Nullable * _Nullable)error;
- (nullable NSString *) readTextOfItem:(nonnull NSString *)path error:(NSError * _Nullable * _Nullable)error;

@end
