//
//  KyBookFmtItem.m
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

#import "KyBookFmtItem.h"
#import "KxGzipArchive.h"
#import "KxTarArchiveReader.h"

@interface KyBookFmtItem()
@property (readwrite, nonatomic, strong) NSString *path;
@property (readwrite, nonatomic) int64_t offset;                // internal
@property (readwrite, nonatomic) int64_t size;
@property (readwrite, nonatomic, strong) NSData *content;
@property (readwrite, nonatomic, strong) NSString *filePath;    // internal
@end

@implementation KyBookFmtItem {
    
    KyBookFmtItemKind   _kind;
    NSData              *_content;
    BOOL                _unzipped;
}

- (KyBookFmtItemKind) kind
{
    if (_kind == KyBookFmtItemKindNone) {
        
        NSString *name = _path.lastPathComponent.lowercaseString;
        
        if ([name isEqualToString:@"_manifest.json"]) {
            
            _kind = KyBookFmtItemKindManifest;
            
        } else if ([name isEqualToString:@"_index.json"]) {
            
            _kind = KyBookFmtItemKindIndex;
            
        } else if ([name isEqualToString:@"_toc.json"]) {
            
            _kind = KyBookFmtItemKindToc;
            
        } else if ([name isEqualToString:@"_guide.json"]) {
            
            _kind = KyBookFmtItemKindGuide;
            
        } else {
            
            NSString *pathExt = name.pathExtension;
            
            if ([pathExt isEqualToString:@"gz"]) { // drop .gz
                pathExt = name.stringByDeletingPathExtension.pathExtension;
            }
            
            if ([pathExt isEqualToString:@"txt"]) {
                
                _kind = KyBookFmtItemKindText;
                
            } else if ([pathExt isEqualToString:@"km"]) {
                
                _kind = KyBookFmtItemKindKoobmark;
                
            } else if ([pathExt isEqualToString:@"html"] ||
                       [pathExt isEqualToString:@"xhtml"] ||
                       [pathExt isEqualToString:@"htm"])
            {
                _kind = KyBookFmtItemKindHTML;
                
            } else if ([pathExt isEqualToString:@"png"] ||
                       [pathExt isEqualToString:@"jpg"] ||
                       [pathExt isEqualToString:@"jpeg"] ||
                       [pathExt isEqualToString:@"jp2"])
            {
                _kind = KyBookFmtItemKindImage;
                
            } else if ([pathExt isEqualToString:@"gif"] ||
                       [pathExt isEqualToString:@"webm"] ||
                       [pathExt isEqualToString:@"apng"])
            {
                _kind = KyBookFmtItemKindMedia;
                
            } else if ([pathExt isEqualToString:@"svg"])
            {
                _kind = KyBookFmtItemKindSVG;
                
            } else if ([pathExt isEqualToString:@"wav"] ||
                       [pathExt isEqualToString:@"aac"] ||
                       [pathExt isEqualToString:@"mp3"] ||
                       [pathExt isEqualToString:@"m4a"] ||
                       [pathExt isEqualToString:@"m4b"])
            {
                _kind = KyBookFmtItemKindAudio;
                
            } else if ([pathExt isEqualToString:@"ttf"] ||
                       [pathExt isEqualToString:@"otf"])
            {
                _kind = KyBookFmtItemKindFont;
                
            } else if ([pathExt isEqualToString:@"css"]) {
                
                _kind = KyBookFmtItemKindCSS;
                
            } else if ([pathExt isEqualToString:@"srt"]) {
                
                _kind = KyBookFmtItemKindSubtitle;
                
            } else {
                
                _kind = KyBookFmtItemKindUnsupported;
            }            
        }
    }

    return _kind;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<item '%@' %llu/%zd bytes>", _path, _size, _content.length];
}

- (NSData *) content
{
    if (!_content && _filePath) {
        
        if (_offset < 0 || _size == 0) {
            
            _content = [KxTarArchiveReader contentOfEntry:_path
                                                 filePath:_filePath
                                                    error:NULL];
        } else {
            
            NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:_filePath];
            if (fh) {
                [fh seekToFileOffset:_offset];
                _content = [fh readDataOfLength:(NSUInteger)_size];
                [fh closeFile];
            }
        }
        
        if (!_content) {
            _content = [NSData new]; // prevent more attempts to read data
        }
    }
    
    if (_content.length > 0 &&
        !_unzipped &&
        NSOrderedSame == [_path.pathExtension compare:@"gz" options:NSCaseInsensitiveSearch])
    {
        _unzipped = YES;
        NSData *tmp = [KxGzipArchive gunzipData:_content];
        if (tmp) {
            _content = tmp;
        }
    }
    
    return _content;
}

- (NSString *) mimeType
{
    switch (self.kind) {
        case KyBookFmtItemKindManifest:
        case KyBookFmtItemKindIndex:
        case KyBookFmtItemKindToc:
        case KyBookFmtItemKindGuide:
            return @"application/json";
            
        case KyBookFmtItemKindText:
            return @"text/plain";
            
        case KyBookFmtItemKindKoobmark:
            return @"application/x-koobmark";
        
        case KyBookFmtItemKindHTML:
            return [@"text/" stringByAppendingString:_path.pathExtension.lowercaseString];
            
        case KyBookFmtItemKindImage:
            return [@"image/" stringByAppendingString:_path.pathExtension.lowercaseString];
            
        case KyBookFmtItemKindMedia:
            if ([_path.pathExtension.lowercaseString isEqualToString:@"webm"]) {
                return @"video/webm";
            } else {
                return [@"image/" stringByAppendingString:_path.pathExtension.lowercaseString];
            }
            
        case KyBookFmtItemKindSVG:
            return @"image/svg+xml";
            
        case KyBookFmtItemKindAudio:
            return [@"audio/" stringByAppendingString:_path.pathExtension.lowercaseString];
            
        case KyBookFmtItemKindFont:
            
            if ([_path.pathExtension.lowercaseString isEqualToString:@"ttf"]) {
                return @"application/x-font-truetype";
            } else if ([_path.pathExtension.lowercaseString isEqualToString:@"otf"]) {
                return @"application/x-font-opentype";
            }
        
        case KyBookFmtItemKindCSS:
            return @"text/css";
        
        case KyBookFmtItemKindSubtitle:
            return [@"text/" stringByAppendingString:_path.pathExtension.lowercaseString];
        
        default:
            break;
    }
    
    return nil;
}

@end
