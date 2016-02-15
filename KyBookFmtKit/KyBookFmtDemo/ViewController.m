//
//  ViewController.m
//  KyBookFmtDemo
//
//  Created by Konstantin Bukreev on 05.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "ViewController.h"
#import <KyBookFmtKit/KyBookFmtKit.h>

@interface ViewController ()
@end

@implementation ViewController

- (id) init
{
    if ((self = [self initWithNibName:nil bundle:nil])) {
        self.title = @"Demo";
        
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_readPath) {
        [self readFileAtPath:_readPath];
    }
}

- (void) readFileAtPath:(NSString *)filePath
{
    NSError *error;
    KyBookFmtReader *reader = [KyBookFmtReader readerWithPath:filePath withContent:NO error:&error];
    
    if (!reader) {
        NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
        return;
    }
    
    for (KyBookFmtItem *item in reader.items) {
        [item content]; // force to read content
        NSLog(@"%@", item);
    }
    
    NSLog(@"MANIFEST: %@", ([reader readManifest:&error] ?: error)); error = nil;
    NSLog(@"INDEX: %@", ([reader readIndex:&error] ?: error)); error = nil;
    NSLog(@"TOC: %@", ([reader readToc:&error] ?: error)); error = nil;
    
    //for (KyBookFmtItem *item in [reader itemsOfKind:KyBookFmtItemKindKoobmark]) {
    //    NSLog(@"\n---- %@ ----\n%@", item.path, [reader readTextOfItem:item.path error:nil]);
    //}
}

@end
