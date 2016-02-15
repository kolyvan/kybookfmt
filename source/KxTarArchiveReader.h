//
//  KxTarArchiveReader.h
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

typedef NS_ENUM(NSUInteger, KxTarArchiveReaderError) {
    
    KxTarArchiveReaderErrorInternal = 1,
    KxTarArchiveReaderErrorPath,
    KxTarArchiveReaderErrorEntry,
    KxTarArchiveReaderErrorOpen,
    KxTarArchiveReaderErrorNext,
    KxTarArchiveReaderErrorNotFound,    
};

@interface KxTarArchiveReaderEntry : NSObject
@property (readonly, nonatomic, strong, nonnull) NSString *path;
@property (readonly, nonatomic) int64_t offset;
@property (readonly, nonatomic) int64_t size;
@property (readonly, nonatomic, strong, nullable) NSData *content;
@end

@interface KxTarArchiveReader : NSObject

+ (nullable NSArray<KxTarArchiveReaderEntry *> *) entriesWithPath:(nonnull NSString *)path
                                                      withContent:(BOOL)withContent
                                                            error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *) contentOfEntry:(nonnull NSString *)entry
                            filePath:(nonnull NSString *)path
                               error:(NSError * _Nullable * _Nullable)error;

+ (nullable KxTarArchiveReaderEntry *) entry:(nonnull NSString *)entryPath
                                    filePath:(nonnull NSString *)filePath
                                 withContent:(BOOL)withContent
                                       error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *) dataWithURL:(nonnull NSURL *)URL  // file:/path.tar?entry
                            error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *) dataWithURL:(nonnull NSURL *)URL  // file:/path.tar?entry
                            range:(NSRange)range
                        entrySize:(NSUInteger * _Nullable)entrySize
                            error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *) dataWithPath:(nonnull NSString *)filePath
                             entry:(nonnull KxTarArchiveReaderEntry *)entry
                             range:(NSRange)range
                             error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *) dataWithPath:(nonnull NSString *)filePath
                         entryPath:(nonnull NSString *)entryPath
                             range:(NSRange)range
                             error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *) dataWithPath:(nonnull NSString *)filePath
                         entryPath:(nonnull NSString *)entryPath
                             error:(NSError * _Nullable * _Nullable)error;

@end
