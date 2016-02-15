//
//  AppDelegate.m
//  KyBookFmtDemo
//
//  Created by Konstantin Bukreev on 05.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "BrowserController.h"
#import "KoobmarkController.h"
#import <KyBookFmtKit/KyBookFmtKit.h>

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask,
                                                              YES) lastObject];
    
    NSLog(@"run in: %@", docsPath);
    
    [self copySamples];
    
    [NSURLProtocol registerClass:[KxUtarURLProtocol class]];
        
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    //ViewController *vc = [ViewController new];
    //vc.readPath = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"tar"];
    
    BrowserController *vc = [BrowserController new];
    vc.filePath = docsPath;
    
    //KoobmarkController *vc = [KoobmarkController new];
    //vc.filePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"sample.km"];
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.window makeKeyAndVisible];
    
    //[self testUntar: [docsPath stringByAppendingPathComponent:@"audio.tar"]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void) copySamples
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask,
                                                              YES) lastObject];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm contentsOfDirectoryAtPath:docsPath error:nil].count == 0) {
        
        NSString *resPath = [NSBundle mainBundle].resourcePath;
        NSArray *samples = @[ @"sample.tar", ];
        
        for (NSString *sample in samples) {
            
            NSString *srcPath = [resPath stringByAppendingPathComponent:sample];
            NSString *destPath = [docsPath stringByAppendingPathComponent:sample];
            [fm copyItemAtPath:srcPath toPath:destPath error:nil];
        }
    }
}

- (void) testUntar:(NSString *)filePath
{
    NSString *folderPath = filePath.stringByDeletingPathExtension;
    [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    NSArray *entries = [KxTarArchiveReader entriesWithPath:filePath withContent:NO error:nil];
    
    for (KxTarArchiveReaderEntry *entry in entries) {
        
        NSMutableData *mdata = [NSMutableData data];
        
        while (1) {
            
            const NSRange range = {mdata.length, 64*1024};
            
            NSData *data = [KxTarArchiveReader dataWithPath:filePath
                                                      entry:entry
                                                      range:range
                                                      error:NULL];
            if (!data) {
                break;
            }
            
            [mdata appendData:data];
        }
        
        NSString *copyPath = [folderPath stringByAppendingPathComponent:entry.path];
        [mdata writeToFile:copyPath atomically:NO];
    }
}

@end
