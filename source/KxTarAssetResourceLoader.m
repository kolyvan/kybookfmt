//
//  KxTarAssetResourceLoader.m
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 12.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "KxTarAssetResourceLoader.h"
#import "KxTarArchiveReader.h"

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

@implementation KxTarAssetResourceLoader {
    
    KxTarArchiveReaderEntry *_tarEntry;
}

+ (dispatch_queue_t) dispatchQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("KxTarAssetResourceLoader", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURLRequest *request = loadingRequest.request;
    NSString *filePath = request.URL.path;
    
    NSError *error;
    
    if (!_tarEntry) {
        
        NSString *entryName = request.URL.query.stringByRemovingPercentEncoding;
        
        _tarEntry = [KxTarArchiveReader entry:entryName
                                     filePath:filePath
                                  withContent:NO
                                        error:&error];
        if (!_tarEntry) {
        
            [loadingRequest finishLoadingWithError:error];
            return YES;
        }
    }
    
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    const long long offset = dataRequest.requestedOffset;
    const NSUInteger length = dataRequest.requestedLength;
    
    NSData *content = [KxTarArchiveReader dataWithPath:filePath
                                                 entry:_tarEntry
                                                 range:NSMakeRange((NSUInteger)offset, length)
                                                 error:&error];    
    if (content) {
        
        AVAssetResourceLoadingContentInformationRequest *contentInfo = loadingRequest.contentInformationRequest;
        if (contentInfo) {
            
            NSString *pathExt = request.URL.query.pathExtension;
            if (NSOrderedSame == [pathExt compare:@"mp3" options:NSCaseInsensitiveSearch]) {
                
                contentInfo.contentType = @"public.mp3"; // kUTTypeMP3;
                
            } else if (NSOrderedSame == [pathExt compare:@"m4b" options:NSCaseInsensitiveSearch] ||
                       NSOrderedSame == [pathExt compare:@"m4a" options:NSCaseInsensitiveSearch]) {
                
                contentInfo.contentType = @"public.mpeg-4-audio"; // kUTTypeMPEG4Audio;
                
            } else {
                
                contentInfo.contentType = @"public.audio"; //kUTTypeAudio;
            }
            
            contentInfo.byteRangeAccessSupported = YES;
            contentInfo.contentLength = _tarEntry.size;
        }
        
        [dataRequest respondWithData:content];
        [loadingRequest finishLoading];
        
    } else if (error) {
        
        [loadingRequest finishLoadingWithError:error];
        
    } else {
        
        [loadingRequest finishLoading];
    }
    
    return YES;
}

@end
