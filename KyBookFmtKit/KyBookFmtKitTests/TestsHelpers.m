//
//  TestsHelpers.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 15.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "TestsHelpers.h"
#import "KyBookFmtManifest.h"

@implementation TestsHelpers

+ (KyBookFmtManifest *) sampleManifest
{
    KyBookFmtManifest *manifest = [KyBookFmtManifest new];
    
    manifest.version    = 2;
    manifest.kind       = KyBookFmtKindTextBook;
    manifest.title      = @"The textbook";
    manifest.subtitle   = @"Demo";
    manifest.authors    = @[ @"Kolyvan", @"Konstantin Bukreev" ];
    manifest.translators = @[ @"Иван Иванов" ];
    manifest.subjects   = @[ @"classic", @"poem" ] ;
    manifest.ids        = @[ @"123456", @"abcdef" ];
    manifest.sequence   = @"The great samples";
    manifest.sequenceNo = 42;
    manifest.isbn       = @"123-456-789";
    manifest.link       = @"https://github.com/kolyvan";
    manifest.rights     = @"Public Domain";
    manifest.publisher  = @"Samizdat";
    manifest.date       = @"2016";
    manifest.language   = @"ru";
    manifest.keywords   = @"great,demo,sample";
    manifest.annotation = @"This is a sample book in KyBook format";
    manifest.cover      = @"cover.jpg";
    manifest.thumbnail  = @"thumbnail.png";
    manifest.creator    = @"Kolyvan";
    manifest.timestamp  = @"2016-02-16";
    manifest.extra      = @{ @"color" : @"red" };
    
    return manifest;
}

+ (NSString *) bundleFileWithPath:(NSString *)path
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle.resourcePath stringByAppendingPathComponent:path];
}

+ (NSData *) bundleDataWithPath:(NSString *)path
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *resPath = [bundle.resourcePath stringByAppendingPathComponent:path];
    return [NSData dataWithContentsOfFile:resPath];
}

+ (NSString *) tmpFilePath
{
    NSString *tmpName = [NSString stringWithFormat:@"testtar-%zd", [NSDate timeIntervalSinceReferenceDate]];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:tmpName];
}

+ (NSArray<NSString *> *) sampleTexts
{
    return @[
             
             @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
             
             @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?",
             
             @"But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?",
             ];
}

@end
