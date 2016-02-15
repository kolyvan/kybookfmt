//
//  KyBookFmtKit.h
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

#import <UIKit/UIKit.h>

//! Project version number for KyBookFmtKit.
FOUNDATION_EXPORT double KyBookFmtKitVersionNumber;

//! Project version string for KyBookFmtKit.
FOUNDATION_EXPORT const unsigned char KyBookFmtKitVersionString[];

#import <KyBookFmtKit/KyBookFmtManifest.h>
#import <KyBookFmtKit/KyBookFmtItem.h>
#import <KyBookFmtKit/KyBookFmtReader.h>
#import <KyBookFmtKit/KyBookFmtWriter.h>
#import <KyBookFmtKit/KxTarArchiveReader.h>
#import <KyBookFmtKit/KxTarArchiveWriter.h>
#import <KyBookFmtKit/KxGzipArchive.h>
#import <KyBookFmtKit/KoobmarkParser.h>
#import <KyBookFmtKit/KoobmarkHtmlRender.h>
#import <KyBookFmtKit/KxUtarURLProtocol.h>
#import <KyBookFmtKit/KxTarAssetResourceLoader.h>
