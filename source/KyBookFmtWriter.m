//
//  KyBookFmtWriter.m
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

#import "KyBookFmtWriter.h"
#import "KyBookFmtManifest.h"
#import "KxTarArchiveWriter.h"

@implementation KyBookFmtWriter {
    
    KxTarArchiveWriter *_tarWriter;
}

+ (instancetype) writerWithPath:(NSString *)path
{
    return [self writerWithPath:path error:nil];
}

+ (instancetype) writerWithPath:(NSString *)path
                          error:(NSError **)error
{
    KxTarArchiveWriter *tarWriter = [KxTarArchiveWriter writerWithPath:path error:error];
    if (!tarWriter) {
        return nil;
    }
    return [[self alloc] initWithTarWriter:tarWriter];
}

- (instancetype) initWithTarWriter:(KxTarArchiveWriter *)tarWriter
{
    if ((self = [super init])) {
        _tarWriter = tarWriter;
    }
    return self;
}

- (void) closeWriter
{
    if (_tarWriter) {
        [_tarWriter closeWriter];
        _tarWriter = nil;
    }
}

- (BOOL) writeManifest:(KyBookFmtManifest *)manifest
                 error:(NSError **)error
{
    if (!manifest) {
        return NO;
    }
    
    NSData *data = [manifest asJsonData:error];
    if (!data) {
        return NO;
    }
    
    return [_tarWriter writeData:data path:@"_manifest.json" error:error];
}

- (BOOL) writeIndex:(NSArray *)index
              error:(NSError **)error
{
    return [self writeJsonValue:index path:@"_index.json" error:error];
}

- (BOOL) writeToc:(NSArray *)toc
            error:(NSError **)error
{
    return [self writeJsonValue:toc path:@"_toc.json" error:error];
}

- (BOOL) writeGuide:(NSArray *)guide
              error:(NSError **)error
{
    return [self writeJsonValue:guide path:@"_guide.json" error:error];
}

- (BOOL) writeData:(NSData *)data
              path:(NSString *)path
             error:(NSError **)error
{
    return [_tarWriter writeData:data path:path error:error];
}

- (BOOL) writeText:(NSString *)text
              path:(NSString *)path
             error:(NSError **)error
{
    if (!text.length) {
        return YES;
    }
    
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return NO;
    }
    
    return [_tarWriter writeData:data path:path error:error];
}

- (BOOL) writeJsonValue:(id)val
                   path:(NSString *)path
                  error:(NSError **)error
{
    if (!val) {
        return YES;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:val
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:error];
    if (!data) {
        return NO;
    }
    
    return [_tarWriter writeData:data path:path error:error];
}

@end
