//
//  KxTarArchiveReader.m
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

#import "KxTarArchiveReader.h"
#import "archive.h"
#import "archive_entry.h"

static NSString *const KxTarArchiveReaderDomain = @"com.kolyvan.tar.reader";

@interface KxTarArchiveReaderEntry()
@property (readwrite, nonatomic, strong) NSString *path;
@property (readwrite, nonatomic) int64_t offset;
@property (readwrite, nonatomic) int64_t size;
@property (readwrite, nonatomic, strong) NSData *content;
@end

@implementation KxTarArchiveReaderEntry
@end

@implementation KxTarArchiveReader

+ (NSArray *) entriesWithPath:(NSString *)path
                  withContent:(BOOL)withContent
                        error:(NSError **)error
{
    struct archive *archive = [self openArchive:path error:error];
    if (!archive) {
        return nil;
    }
    
    NSArray *entries = [self entriesWithArchive:archive withContent:withContent error:error];
    [self closeArchive:archive];
    return entries;
}

+ (NSArray *) entriesWithArchive:(struct archive *)archive
                     withContent:(BOOL)withContent
                           error:(NSError **)error
{
    NSMutableArray *result = [NSMutableArray array];
    
    struct archive_entry *entry;
    
    while (1) {
        
        const int r = archive_read_next_header(archive, &entry);
        if (r == ARCHIVE_EOF) {
            
            break; // ok, eof
            
        } else if (r == ARCHIVE_OK) {
            
            if (S_ISREG(archive_entry_mode(entry))) {
                
                const char *path = archive_entry_pathname(entry);
                if (path) {
                    
                    NSString *nspath = [NSString stringWithUTF8String:path];
                    if (nspath) {
                        
                        KxTarArchiveReaderEntry *p = [KxTarArchiveReaderEntry new];
                        
                        p.path = nspath;
                        p.size = archive_entry_size(entry);
                        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        p.offset = archive_position_uncompressed(archive);
#pragma clang diagnostic pop
                        
                        if (withContent) {
                            p.content = [self readContent:archive];
                        }
                        
                        [result addObject:p];
                    }
                }
            }
            
        } else {
            
            if (error) {
                *error = [self errorWithCode:KxTarArchiveReaderErrorNext archive:archive message:nil];
            }
            break;
        }
    }
    
    return [result copy];
}

+ (NSData *) readContent:(struct archive *)archive
{
    NSMutableData *data;
    
    while (1) {
        
        const void *buff = NULL;
        off_t offset = 0;
        size_t size = 0;
                
        const int r = archive_read_data_block(archive, &buff, &size, &offset);
        
        if (r == ARCHIVE_EOF) {
            break;
        }
        
        if (r == ARCHIVE_OK) {
            
            if (size > 0) {
                
                if (!data) {
                    data = [NSMutableData new];
                }
                [data appendBytes:buff length:size];
            }
            
        } else {
            
            return nil;
        }
    }
    
    return data;
}

+ (NSData *) contentOfEntry:(NSString *)entryPath
                   filePath:(NSString *)filePath
                      error:(NSError **)error
{
    if (!entryPath.length) {
        if (error) {
            *error = [self errorWithCode:KxTarArchiveReaderErrorEntry
                                 archive:nil
                                 message:NSLocalizedString(@"Bad Entry", nil)];
        }
        return nil;
    }
    
    struct archive *archive = [self openArchive:filePath error:error];
    if (!archive) {
        return nil;
    }
    
    NSData *content = [self contentOfEntry:entryPath
                                   archive:archive
                                     error:error];
    [self closeArchive:archive];
    return content;
}

+ (NSData *) contentOfEntry:(NSString *)entryPath
                    archive:(struct archive *)archive
                      error:(NSError **)error
{
    struct archive_entry *entry;
    
    while (1) {
        
        const int r = archive_read_next_header(archive, &entry);
        if (r == ARCHIVE_EOF) {
            
            break;
            
        } else if (r == ARCHIVE_OK) {
            
            if (S_ISREG(archive_entry_mode(entry))) {
                
                const char *path = archive_entry_pathname(entry);
                if (path) {
                    
                    NSString *nspath = [NSString stringWithUTF8String:path];
                    if (nspath && [nspath isEqualToString:entryPath]) {
                        return [self readContent:archive];
                    }
                }
            }
            
        } else {
            
            if (error) {
                *error = [self errorWithCode:KxTarArchiveReaderErrorNext archive:archive message:nil];
            }
            return nil;
        }
    }
    
    if (error) {
        *error = [self errorWithCode:KxTarArchiveReaderErrorNotFound
                             archive:nil
                             message:NSLocalizedString(@"Not Found", nil)];
    }
    
    return nil;
}

+ (KxTarArchiveReaderEntry *) entry:(NSString *)entryPath
                           filePath:(NSString *)filePath
                        withContent:(BOOL)withContent
                              error:(NSError **)error
{
    if (!entryPath.length) {
        if (error) {
            *error = [self errorWithCode:KxTarArchiveReaderErrorEntry
                                 archive:nil
                                 message:NSLocalizedString(@"Bad Entry", nil)];
        }
        return nil;
    }
    
    struct archive *archive = [self openArchive:filePath error:error];
    if (!archive) {
        return nil;
    }
    
    KxTarArchiveReaderEntry *entry = [self entry:entryPath
                                         archive:archive
                                     withContent:withContent
                                           error:error];
    
    [self closeArchive:archive];
    return entry;
}

+ (KxTarArchiveReaderEntry *) entry:(NSString *)entryPath
                            archive:(struct archive *)archive
                        withContent:(BOOL)withContent
                              error:(NSError **)error
{
    struct archive_entry *entry;
    
    while (1) {
        
        const int r = archive_read_next_header(archive, &entry);
        if (r == ARCHIVE_EOF) {
            
            break;
            
        } else if (r == ARCHIVE_OK) {
            
            if (S_ISREG(archive_entry_mode(entry))) {
                
                const char *path = archive_entry_pathname(entry);
                if (path) {
                    
                    NSString *nspath = [NSString stringWithUTF8String:path];
                    if (nspath && [nspath isEqualToString:entryPath]) {

                        KxTarArchiveReaderEntry *p = [KxTarArchiveReaderEntry new];
                        
                        p.path = nspath;
                        p.size = archive_entry_size(entry);
                        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        p.offset = archive_position_uncompressed(archive);
#pragma clang diagnostic pop
                        
                        if (withContent) {
                            p.content = [self readContent:archive];
                        }

                        return p;
                    }
                }
            }
            
        } else {
            
            if (error) {
                *error = [self errorWithCode:KxTarArchiveReaderErrorNext archive:archive message:nil];
            }
            return nil;
        }
    }
    
    if (error) {
        *error = [self errorWithCode:KxTarArchiveReaderErrorNotFound
                             archive:nil
                             message:NSLocalizedString(@"Not Found", nil)];
    }
    
    return nil;
}


+ (struct archive *) openArchive:(NSString *)path
                           error:(NSError **)error
{
    if (!path.length) {
        if (error) {
            *error = [self errorWithCode:KxTarArchiveReaderErrorPath
                                 archive:NULL
                                 message:NSLocalizedString(@"Bad Path", nil)];
        }
        return NULL;
    }
    
    struct archive *archive = archive_read_new();
    if (!archive) {
        if (error) {
            *error = [self errorWithCode:KxTarArchiveReaderErrorInternal archive:NULL message:nil];
        }
        return NULL;
    }
    
    archive_read_support_format_tar(archive);
    
    const int r = archive_read_open_filename(archive, path.UTF8String, 10240);
    
    if (r != ARCHIVE_OK) {
        if (error) {
            *error = [self errorWithCode:KxTarArchiveReaderErrorOpen archive:archive message:nil];
        }
        [self closeArchive:archive];
        return NULL;
    }
    
    return archive;
}

+ (void) closeArchive:(struct archive *)archive
{
    archive_read_close(archive);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    archive_read_finish(archive);
#pragma clang diagnostic pop
}

+ (NSError *) errorWithCode:(KxTarArchiveReaderError)code
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
    
    return [NSError errorWithDomain:KxTarArchiveReaderDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey : errString }];
}

+ (nullable NSData *) dataWithURL:(NSURL *)URL
                            error:(NSError **)error
{
    return [self dataWithURL:URL range:NSMakeRange(NSNotFound, 0) entrySize:NULL error:error];
}

+ (NSData *) dataWithURL:(NSURL *)URL
                   range:(NSRange)range
               entrySize:(NSUInteger *)entrySize
                   error:(NSError **)error
{
    NSString *entryName = URL.query.stringByRemovingPercentEncoding;
    NSString *filePath = URL.path;
    
    if (range.location != NSNotFound && range.length > 0) {
        
        KxTarArchiveReaderEntry *entry;
        entry = [KxTarArchiveReader entry:entryName
                                 filePath:filePath
                              withContent:NO
                                    error:error];
        if (!entry) {
            return nil;
        }
        
        if (entrySize) {
            *entrySize = (NSUInteger)entry.size;
        }
        
        return [self dataWithPath:filePath
                            entry:entry
                            range:range
                            error:error];
    } else {
        
        NSData *data = [KxTarArchiveReader contentOfEntry:entryName
                                                 filePath:filePath
                                                    error:error];
        if (data && entrySize) {
            *entrySize = data.length;
        }
        
        return data;
    }
}

+ (NSData *) dataWithPath:(NSString *)filePath
                    entry:(KxTarArchiveReaderEntry *)entry
                    range:(NSRange)range
                   error:(NSError **)error
{
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!fh) {
        return nil;
    }
    
    NSData *data;
    NSInteger length, offset;
    
    if (range.location == NSNotFound ||
        (range.location == 0 && range.length == entry.size)) {
        
        offset = (NSInteger)entry.offset;
        length = (NSInteger)entry.size;
        
    } else {
        
        if (NSMaxRange(range) > entry.size) {
            length = (NSInteger)(entry.size - range.location);
        } else {
            length = range.length;
        }
        
        if (length <= 0) {
            return  nil; // EOF
        }
        
        offset = (NSInteger)(entry.offset + range.location);
    }
    
    [fh seekToFileOffset:offset];
    data = [fh readDataOfLength:length];
    [fh closeFile];
    
    return data;
}

+ (NSData *) dataWithPath:(NSString *)filePath
                entryPath:(NSString *)entryPath
                    range:(NSRange)range
                    error:(NSError **)error
{
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = @"file";
    components.path = filePath;
    components.query = entryPath;
    
    return [self dataWithURL:components.URL
                       range:range
                   entrySize:NULL
                       error:error];
}

+ (NSData *) dataWithPath:(NSString *)filePath
                entryPath:(NSString *)entryPath
                    error:(NSError **)error
{
    return [self dataWithPath:filePath
                    entryPath:entryPath
                        range:NSMakeRange(NSNotFound, 0)
                        error:error];
}

@end
