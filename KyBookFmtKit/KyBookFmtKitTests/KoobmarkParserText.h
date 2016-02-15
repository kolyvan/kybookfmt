//
//  KoobmarkParserText.h
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KoobmarkParser.h"

@interface KoobmarkParserText : NSObject<KoobmarkParserDelegate>
@property (readwrite, nonatomic, strong) NSMutableString *text;
+ (NSString *) parseKoobmark:(NSString *)text;
@end
