//
//  KyBookFmtUtils.m
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 07.02.16.
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

#import "KyBookFmtUtils.h"

@implementation KyBookFmtUtils

+ (BOOL) probeCollection:(id<NSFastEnumeration>)collection
               itemClass:(Class)klass
{
    for (id p in collection) {
        if (![p isKindOfClass:klass]) {
            return NO;
        }
    }
    return YES;
}

@end


@implementation NSDictionary(KxBookFmt)

- (id) kx_valueForKey:(NSString *)key ofClass:(Class)klass
{
    id val = [self valueForKey:key];
    if (val && [val isKindOfClass:klass]) {
        return val;
    }
    return nil;
}

- (NSNumber *) kx_numberForKey:(NSString *)key
{
    return [self kx_valueForKey:key ofClass:[NSNumber class]];
}

- (NSString *) kx_stringForKey:(NSString *)key
{
    return [self kx_valueForKey:key ofClass:[NSString class]];
}

- (NSArray *) kx_arrayForKey:(NSString *)key itemClass:(Class)itemClass
{
    NSArray *array = [self kx_valueForKey:key ofClass:[NSArray class]];
    if (array && [KyBookFmtUtils probeCollection:array itemClass:itemClass]) {
        return array;
    }
    return nil;
}

- (NSDictionary *) kx_dictionaryForKey:(NSString *)key valueClass:(Class)valueClass
{
    NSDictionary *dict = [self kx_valueForKey:key ofClass:[NSDictionary class]];
    if (dict &&
        [KyBookFmtUtils probeCollection:dict.allKeys itemClass:[NSString class]] &&
        [KyBookFmtUtils probeCollection:dict.allValues itemClass:valueClass]) {
        return dict;
    }
    return nil;
}

@end