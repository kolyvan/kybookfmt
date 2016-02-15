//
//  KxUtarURLProtocol.m
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 07.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "KxUtarURLProtocol.h"
#import "KxTarArchiveReader.h"
#import "KxGzipArchive.h"

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

#if TARGET_OS_IPHONE
@import MobileCoreServices;
#endif

@interface KxUtarURLProtocol()
@property (readwrite, nonatomic) BOOL cancelled;
@end

@implementation KxUtarURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [request.URL.scheme isEqualToString:@"utar"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    __weak __typeof(self) weakSelf = self;
    NSURLRequest *request = self.request;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        if (!weakSelf.cancelled) {
            
            NSError *error; NSUInteger entrySize = 0;
            
            NSData *content = [KxUtarURLProtocol dataWithRequest:request
                                                       entrySize:&entrySize
                                                           error:&error];
            
            NSURLResponse *response;
            if (!error) {
                
                NSString *pathExt = request.URL.query.pathExtension;
                response = [KxUtarURLProtocol responseWithURL:request.URL
                                                      pathExt:pathExt
                                                    entrySize:entrySize];
            }
            
            [weakSelf didReadResponse:response content:content error:error];
        }
    });
}

- (void)stopLoading
{
    self.cancelled = YES;
}

- (void) didReadResponse:(NSURLResponse *)response
                 content:(NSData *)content
                   error:(NSError *)error
{
    if (self.cancelled) {
        return;
    }
    
    id<NSURLProtocolClient> client = self.client;
    
    if (error) {
        
        [client URLProtocol:self didFailWithError:error];
        
    } else {
        
        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        
        if (content.length) {
            [client URLProtocol:self didLoadData:content];
        }
        
        [client URLProtocolDidFinishLoading:self];
    }
}

+ (NSURLResponse *) responseWithURL:(NSURL *)URL
                            pathExt:(NSString *)pathExt
                          entrySize:(NSUInteger)entrySize
{
    NSString *mimeType, *encodingName;
    
    if (pathExt) {
        
        if ([pathExt isEqualToString:@"km"]) {
            mimeType = @"application/x-koobmark";
        } else {
            mimeType = [self.class MIMETypeWithPathExtension:pathExt];
        }
        
        if ([mimeType isEqualToString:@"application/json"] ||
            [mimeType isEqualToString:@"application/xml"] ||
            [mimeType isEqualToString:@"application/x-koobmark"] ||
            [mimeType isEqualToString:@"text/html"] ||
            [mimeType isEqualToString:@"text/xml"] ||
            [mimeType isEqualToString:@"text/plain"])
        {
            encodingName = @"utf-8";
        }
    }
    
    return [[NSURLResponse alloc] initWithURL:URL
                                     MIMEType:mimeType
                        expectedContentLength:entrySize
                             textEncodingName:encodingName];
}

+ (NSString *)MIMETypeWithPathExtension:(NSString *)extension
{
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                             (__bridge CFStringRef)extension ,
                                                             NULL);
    
    NSString *mimeType;
    if (type) {
        mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
        CFRelease(type);
    }
    
    return mimeType ?: @"application/octet-stream";
}

+ (BOOL) parseRequestRangeField:(NSString *)rangeField
                          range:(NSRange *)outRange
{
    // parse offset/length from range header field
    // Range = "bytes=500-999"
    
    NSRange r = [rangeField rangeOfString:@"="];
    
    if (r.location == NSNotFound) {
        NSLog(@"request has invalid rangeField: %@", rangeField);
        return NO;
    }
    
    NSString *bytesUnit = [rangeField substringToIndex:r.location];
    NSString *byteRangeSet = [rangeField substringFromIndex:r.location + 1];
    
    if (![bytesUnit.lowercaseString isEqualToString:@"bytes"]) {
        NSLog(@"loadingRequest has invalid bytesUnit: %@", rangeField);
        return NO;
    }
    
    r = [byteRangeSet rangeOfString:@"-"];
    if (r.location == NSNotFound) {
        NSLog(@"loadingRequest has invalid byteRangeSet: %@", rangeField);
        return NO;
    }
    
    if (outRange) {
        
        NSString *fromString = [byteRangeSet substringToIndex:r.location];
        NSString *toString = [byteRangeSet substringFromIndex:r.location + 1];
        
        outRange->location = [fromString integerValue];
        outRange->length = [toString integerValue] - outRange->location + 1;
    }
    
    return YES;
}

+ (NSData *) dataWithRequest:(NSURLRequest *)request
                   entrySize:(NSUInteger *)entrySize
                       error:(NSError **)error
{
    NSRange range = {NSNotFound, 0};
    NSString *rangeField = request.allHTTPHeaderFields[@"Range"];
    
    if (rangeField.length &&
        ![self.class parseRequestRangeField:rangeField range:&range])
    {
        if (error) {
            *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorCancelled
                                     userInfo:@{ NSLocalizedDescriptionKey  : @"Bad Range" }];
        }
        return  nil;
    }
    
    return [KxTarArchiveReader dataWithURL:request.URL
                                     range:range
                                 entrySize:entrySize
                                     error:error];
}

@end
