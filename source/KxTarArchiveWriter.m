//
//  KxTarArchiveWriter.m
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

#import "KxTarArchiveWriter.h"
#import "archive.h"
#import "archive_entry.h"

static NSString *const KxTarArchiveWriterDomain = @"com.kolyvan.tar.writer";

@implementation KxTarArchiveWriter {
    
    struct archive *_archive;
}

+ (instancetype) writerWithPath:(NSString *)path
                          error:(NSError **)error
{
    if (!path.length) {
        if (error) {
            *error = [self errorWithCode:KxTarArchiveWriterErrorPath
                                 archive:NULL
                                 message:NSLocalizedString(@"Bad Path", nil)];
        }
        return NULL;
    }
    
    struct archive *archive = archive_write_new();
    if (!archive) {
        if (error) {
            *error = [self errorWithCode:KxTarArchiveWriterErrorInternal archive:NULL message:nil];
        }
        return nil;        
    }
    
    archive_write_set_format_pax_restricted(archive);
    
    const int r = archive_write_open_filename(archive, path.UTF8String);
    if (r != ARCHIVE_OK) {
        
        if (error) {
            *error = [self errorWithCode:KxTarArchiveWriterErrorOpen archive:archive message:nil];
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        archive_write_finish(archive);
#pragma clang diagnostic pop
        return nil;
    }
    
    return [[self alloc] initWithArchive:archive];
}

- (instancetype) initWithArchive:(struct archive *)archive
{
    if ((self = [super init])) {
        _archive = archive;
    }
    return self;
}

- (void) dealloc
{
    [self closeWriter];
}

- (void) closeWriter
{
    if (_archive) {
        
        archive_write_close(_archive);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        archive_write_finish(_archive);
#pragma clang diagnostic pop
        
        _archive = NULL;
    }
}

- (BOOL) writeData:(NSData *)data
              path:(NSString *)path
             error:(NSError **)error
{
    NSParameterAssert(path.length > 0);
    
    if (path.length == 0) {
        return NO;
    }
    
    if (data.length == 0) {
        return YES;
    }
    
    struct archive_entry *entry = archive_entry_new();
    if (!entry) {
        if (error) {
            *error = [self.class errorWithCode:KxTarArchiveWriterErrorInternal archive:NULL message:nil];
        }
        return NO;
    }
    
    archive_entry_set_pathname(entry, path.UTF8String);
    archive_entry_set_size(entry, data.length);
    archive_entry_set_filetype(entry, AE_IFREG);
    archive_entry_set_perm(entry, 0644);
    
    BOOL result = NO;
    if (ARCHIVE_OK == archive_write_header(_archive, entry)) {
        
        const ssize_t numBytes = archive_write_data(_archive, data.bytes, data.length);
        result = (numBytes == data.length);
        
        if (!result && error) {
            *error = [self.class errorWithCode:KxTarArchiveWriterErrorWrite archive:nil message:nil];
        }
        
    } else if (error) {
        *error = [self.class errorWithCode:KxTarArchiveWriterErrorWrite archive:_archive message:nil];
    }
    
    archive_entry_free(entry);
    
    return result;
}

+ (NSError *) errorWithCode:(KxTarArchiveWriterError)code
                    archive:(struct archive *)archive
                    message:(NSString *)message
{
    NSString *errString;
    
    if (archive) {
        const char *str = archive_error_string(archive);
        if (str && strlen(str) > 0) {
            errString = [NSString stringWithUTF8String:str];
        }
    }
    
    if (!errString) {
        errString = message ?: NSLocalizedString(@"ERROR", nil);
    }
    
    if (archive) {
        const int errNo = archive_errno(archive);
        if (errNo) {
            errString = [errString stringByAppendingFormat:@" #%d", errNo];
        }
    }
    
    return [NSError errorWithDomain:KxTarArchiveWriterDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey : errString }];
}

@end
