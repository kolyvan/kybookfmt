//
//  KxGzipArchive.m
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

#define GZIP_WITH_ZLIB 1

#import "KxGzipArchive.h"
#if GZIP_WITH_ZLIB
#import <zlib.h>
#else
#import "archive.h"
#import "archive_entry.h"
#endif

@implementation KxGzipArchive

#if GZIP_WITH_ZLIB

+ (NSData *) gzipData:(NSData *)data
{
    if (data.length == 0) {
        return data;
    }
    
    z_stream zs;
    
    zs.next_in = (Bytef *)data.bytes;
    zs.avail_in = (uInt)data.length;
    zs.total_out = 0;
    zs.avail_out = 0;
    zs.zalloc = Z_NULL;
    zs.zfree = Z_NULL;
    zs.opaque = Z_NULL;
    //zs.data_type = Z_TEXT;
    
    const NSUInteger buffSize = 16*1014;
    NSMutableData *deflated = [NSMutableData dataWithLength:buffSize];
    
    const BOOL asZLib = NO;
    
    if (Z_OK != deflateInit2(&zs,
                             Z_BEST_COMPRESSION,
                             Z_DEFLATED,
                             MAX_WBITS+(asZLib ? 0 : 16),
                             8,
                             Z_DEFAULT_STRATEGY))
    {
        return nil;
    }
    
    do {
        
        if (zs.total_out >= deflated.length) {
            [deflated increaseLengthBy:buffSize];
        }
        
        zs.next_out = deflated.mutableBytes + zs.total_out;
        zs.avail_out = (uInt)(deflated.length - zs.total_out);
        int status =  deflate(&zs, Z_FINISH);
        
        if (Z_OK != status &&
            Z_STREAM_END != status)
        {
            return nil; // some error
        }
        
    } while (0 == zs.avail_out);
    
    deflateEnd(&zs);
    deflated.length = zs.total_out;
    
    return deflated;
}

+ (NSData *) gunzipData:(NSData *)data
{
    const NSUInteger halfLen = data.length / 2;
    
    NSMutableData *inflated = [NSMutableData dataWithLength:data.length + halfLen];
    
    z_stream zs;
    
    zs.next_in = (Bytef *)data.bytes;
    zs.avail_in = (uInt)data.length;
    zs.total_out = 0;
    zs.avail_out = 0;
    zs.zalloc = Z_NULL;
    zs.zfree = Z_NULL;
    zs.opaque = Z_NULL;
    
    if (Z_OK != inflateInit2(&zs, MAX_WBITS+32)) {
        return nil;
    }
    
    int status = Z_OK;
    while (Z_OK == status) {
        
        if (zs.total_out >= inflated.length) {
            [inflated increaseLengthBy:halfLen];
        }
        
        zs.next_out = inflated.mutableBytes + zs.total_out;
        zs.avail_out = (uInt)(inflated.length - zs.total_out);
        
        status = inflate(&zs, Z_SYNC_FLUSH);
    }
    
    if ((Z_STREAM_END == status) &&
        (Z_OK == inflateEnd(&zs)))
    {
        inflated.length = zs.total_out;
        return inflated;
    }
    
    return nil;
}

#else

// libarchive

+ (NSData *) gunzipData:(NSData *)data
{
    if (!data.length) {
        return nil;
    }
    
    struct archive *archive = archive_read_new();
    if (!archive) {
        return nil;
    }
    
    //archive_read_support_filter_gzip(archive);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    archive_read_support_compression_gzip(archive);
#pragma clang diagnostic pop
    
    archive_read_support_format_raw(archive);
    
    const int r = archive_read_open_memory(archive, data.bytes, data.length);
    
    NSData *result;
    if (r == ARCHIVE_OK) {

        result = [self gunzipArchive:archive
                            capacity:data.length * 1.5];
    }
    
    //archive_read_close(archive);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    archive_read_finish(archive);
#pragma clang diagnostic pop
    
    return result;
}

+ (NSData *) gunzipArchive:(struct archive *)archive
                  capacity:(NSUInteger)capacity
{
    struct archive_entry *entry;
    
    const int r = archive_read_next_header(archive, &entry);
    if (r != ARCHIVE_OK) {
        return nil;
    }
    
    NSMutableData *result;
    char buffer[1024];
    
    while (1) {
        
        const ssize_t size = archive_read_data(archive, buffer, sizeof(buffer));
        if (size < 0) {
            
            result = nil;
            break;
            
        } else if (size == 0) {
            
            break; // eof
            
        } else {
            
            if (!result) {
                result = [NSMutableData dataWithCapacity:capacity];
            }
            [result appendBytes:buffer length:size];
        }
    }

    return result;
}

+ (NSData *) gzipData:(NSData *)data
{
    if (!data.length) {
        return data;
    }
    
    struct archive *archive = archive_write_new();
    if (!archive) {
        return nil;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    archive_write_set_compression_gzip(archive);
#pragma clang diagnostic pop
    archive_write_set_format_raw(archive);      // ios libarchive does not support write_raw
        
    NSData *result;
    
    const size_t buffSize = data.length * 1.1;
    void *buffer = malloc(buffSize);
    if (buffer) {
        
        size_t usedSize = 0;
        const int r = archive_write_open_memory(archive, buffer, buffSize, &usedSize);
        
        if (r == ARCHIVE_OK &&
            [self gzipArchive:archive data:data] &&
            usedSize > 0)
        {
            result = [NSData dataWithBytesNoCopy:buffer length:usedSize freeWhenDone:YES];
            
        } else {
            
            free(buffer);
        }
    }

    //archive_write_close(archive);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    archive_write_finish(archive);
#pragma clang diagnostic pop
    
    return result;
}

+ (BOOL) gzipArchive:(struct archive *)archive
                data:(NSData *)data
{
    if (data.length == 0) {
        return NO;
    }
    
    struct archive_entry *entry = archive_entry_new();
    if (!entry) {
        return NO;
    }

    archive_entry_set_pathname(entry, "test");
    archive_entry_set_size(entry, data.length);
    archive_entry_set_filetype(entry, AE_IFREG);
    archive_entry_set_perm(entry, 0644);
    
    BOOL result = NO;
    if (ARCHIVE_OK == archive_write_header(archive, entry))
    {
        const ssize_t numBytes = archive_write_data(archive, data.bytes, data.length);
        result = (numBytes == data.length);
    }
    
    archive_entry_free(entry);
    
    return result;
}
#endif

@end
