//
//  KxBookFmtManifest.h
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

typedef NS_ENUM(NSUInteger, KyBookFmtKindBook) {
    
    KyBookFmtKindCommonBook,
    KyBookFmtKindTextBook,
    KyBookFmtKindAudioBook,
    KyBookFmtKindComicsBook,
};

@interface KyBookFmtManifest : NSObject

@property (readwrite, nonatomic) NSUInteger version;
@property (readwrite, nonatomic) KyBookFmtKindBook kind;
@property (readwrite, nonatomic, strong, nullable) NSString *title;
@property (readwrite, nonatomic, strong, nullable) NSString *subtitle;
@property (readwrite, nonatomic, strong, nullable) NSArray<NSString *> *authors;
@property (readwrite, nonatomic, strong, nullable) NSArray<NSString *> *translators;
@property (readwrite, nonatomic, strong, nullable) NSArray<NSString *> *subjects;
@property (readwrite, nonatomic, strong, nullable) NSArray<NSString *> *ids;
@property (readwrite, nonatomic, strong, nullable) NSString *sequence;
@property (readwrite, nonatomic) NSUInteger sequenceNo;
@property (readwrite, nonatomic, strong, nullable) NSString *isbn;
@property (readwrite, nonatomic, strong, nullable) NSString *link;        // url string
@property (readwrite, nonatomic, strong, nullable) NSString *rights;
@property (readwrite, nonatomic, strong, nullable) NSString *publisher;
@property (readwrite, nonatomic, strong, nullable) NSString *date;
@property (readwrite, nonatomic, strong, nullable) NSString *language;
@property (readwrite, nonatomic, strong, nullable) NSString *keywords;
@property (readwrite, nonatomic, strong, nullable) NSString *annotation;
@property (readwrite, nonatomic, strong, nullable) NSString *cover;
@property (readwrite, nonatomic, strong, nullable) NSString *thumbnail;
@property (readwrite, nonatomic, strong, nullable) NSString *creator;
@property (readwrite, nonatomic, strong, nullable) NSString *timestamp;
@property (readwrite, nonatomic, strong, nullable) NSDictionary *extra;   // origin-lang, origin-title, etc

+ (nullable instancetype) manifestFromJsonData:(nonnull NSData *)json
                                error:(NSError * _Nullable * _Nullable)error;

+ (nonnull instancetype) manifestFromDictionary:(nonnull NSDictionary *)dict;

- (nullable NSData *) asJsonData:(NSError * _Nullable * _Nullable)error;
- (nonnull NSDictionary *) asDictionary;

@end
