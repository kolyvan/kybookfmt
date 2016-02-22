//
//  KyBookFmtWriter.h
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 06.02.16.
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

@class KyBookFmtItem;
@class KyBookFmtManifest;

@interface KyBookFmtWriter : NSObject

+ (nullable instancetype) writerWithPath:(nonnull NSString *)path;

+ (nullable instancetype) writerWithPath:(nonnull NSString *)path
                                   error:(NSError * _Nullable * _Nullable)error;

- (void) closeWriter;

- (BOOL) writeManifest:(nonnull KyBookFmtManifest *)manifest
                 error:(NSError * _Nullable * _Nullable)error;

- (BOOL) writeIndex:(nonnull NSArray *)index
              error:(NSError * _Nullable * _Nullable)error;

- (BOOL) writeToc:(nonnull NSArray *)toc
            error:(NSError * _Nullable * _Nullable)error;

- (BOOL) writeGuide:(nonnull NSArray *)guide
              error:(NSError * _Nullable * _Nullable)error;

- (BOOL) writeData:(nonnull NSData *)data
              path:(nonnull NSString *)path
             error:(NSError * _Nullable * _Nullable)error;

- (BOOL) writeText:(nonnull NSString *)text
              path:(nonnull NSString *)path
             error:(NSError * _Nullable * _Nullable)error;

- (BOOL) writeJsonValue:(nonnull id)val
                   path:(nonnull NSString *)path
                  error:(NSError * _Nullable * _Nullable)error;

@end
