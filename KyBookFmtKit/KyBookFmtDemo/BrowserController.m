//
//  BrowserController.m
//  KyBookFmtKit
//
//  Created by Konstantin Bukreev on 07.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

#import "BrowserController.h"
#import <KyBookFmtKit/KyBookFmtKit.h>
@import QuickLook;
@import AVFoundation;

@interface BrowserController() <UITableViewDelegate, UITableViewDataSource, QLPreviewControllerDelegate, QLPreviewControllerDataSource>
@property (readonly, nonatomic, strong) UITableView *tableView;
@end

@implementation BrowserController {
    NSArray     *_items;
    NSURL       *_previewItem;
    AVPlayer    *_avPlayer;
    BOOL        _avPlayerPlaying;
    
    KxTarAssetResourceLoader *_avResLoader;
}

- (id) init
{
    if ((self = [self initWithNibName:nil bundle:nil])) {
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _tableView = ({
        
        UITableView *v = [[UITableView alloc] initWithFrame:self.view.bounds
                                                      style:UITableViewStyleGrouped];
        
        v.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        v.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        v.backgroundColor = [UIColor whiteColor];
        v.delegate = self;
        v.dataSource = self;
        v;
    });
    
    [self.view addSubview:_tableView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_items && _filePath) {
        
        [self loadItems];
        [self.tableView reloadData];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopAudio];
}

- (void) loadItems
{
    self.title = _filePath.lastPathComponent;
    
    if ([_filePath.pathExtension isEqualToString:@"tar"]) {
        
        NSError *error;
        KyBookFmtReader *reader = [KyBookFmtReader readerWithPath:_filePath withContent:NO error:&error];
        if (reader) {
                     
            NSMutableArray *items = [NSMutableArray array];
            for (KyBookFmtItem *item in reader.items) {
                
                NSURLComponents *components = [NSURLComponents new];
                components.scheme = @"utar";
                components.path = _filePath;
                components.query = item.path;
                NSURL *URL = components.URL;
                [items addObject:URL];
            }
            
            _items = items;
            
        } else {
            NSLog(@"%@", error);
        }
        
    } else {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        _items = [fm contentsOfDirectoryAtPath:_filePath error:nil];
    }
}

- (void) presentTarItem:(NSURL *)URL
{
    NSString *pathExt = URL.query.pathExtension;
    
    if ([pathExt isEqualToString:@"mp3"] ||
        [pathExt isEqualToString:@"m4a"])
    {
        [self playAudio:URL];
        return;
    }
    
    [self stopAudio];
    
    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSError *error;
        NSData *data = [NSData dataWithContentsOfURL:URL options:0 error:&error];
        if (data) {
            
            NSString *name = URL.query.stringByRemovingPercentEncoding.lastPathComponent;
            if ([name.pathExtension isEqualToString:@"gz"]) {
                
                NSData *gunzipped = [KxGzipArchive gunzipData:data];
                if (gunzipped) {
                    data = gunzipped;
                    name = name.stringByDeletingPathExtension;
                }
            }
            if ([name.pathExtension isEqualToString:@"km"]) {
                // render for quicklook
                name = [name.stringByDeletingPathExtension stringByAppendingPathExtension:@"html"];
                data = [KoobmarkHtmlRender htmlDataFromKoobmarkData:data];
            }
            
            NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
            [data writeToFile:tmpPath options:0 error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf previewFile:tmpPath];
            });
        } else {
            NSLog(@"%@", error);
        }
    });
}

- (void) previewFile:(NSString *)path
{
    _previewItem = [NSURL fileURLWithPath:path];
    QLPreviewController *vc = [QLPreviewController new];
    vc.delegate = self;
    vc.dataSource = self;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - audio

- (void) playAudio:(NSURL *)URL
{
    [self stopAudio];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
    
    if ([URL.scheme isEqualToString:@"utar"] ||
        [URL.pathExtension isEqualToString:@"tar"]) {
        
        _avResLoader = [KxTarAssetResourceLoader new];
        [asset.resourceLoader setDelegate:_avResLoader queue:[KxTarAssetResourceLoader dispatchQueue]];
    }
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    _avPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    
    if (_avPlayer && !_avPlayer.error) {
        
        [_avPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:_avPlayer.currentItem];
        
        [_avPlayer seekToTime:CMTimeMakeWithSeconds(10.0, NSEC_PER_SEC)];
        
    } else {
        
        NSLog(@"avplayer: %@", _avPlayer.error);
        _avPlayer = nil;
    }
}

- (void) stopAudio
{
    if (_avPlayer) {
        
        [_avPlayer pause];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_avPlayer.currentItem];
        
        [_avPlayer removeObserver:self forKeyPath:@"status"];
        
        _avPlayer = nil;
        _avPlayerPlaying = NO;
        _avResLoader = nil;
        
        self.toolbarItems = nil;        
    }
}

- (void) avPlayerDidReady
{
    [self setupToolbarItems];
}

- (void) togglePlayAudio:(id)sender
{
    _avPlayerPlaying = !_avPlayerPlaying;
    if (_avPlayerPlaying) {
        [_avPlayer play];
    } else {
        [_avPlayer pause];
    }
    [self setupToolbarItems];
}

- (void) setupToolbarItems
{
    UIBarButtonSystemItem toggleItem = _avPlayerPlaying ? UIBarButtonSystemItemPause : UIBarButtonSystemItemPlay;
    
    self.toolbarItems = @[
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:toggleItem
                                                                        target:self
                                                                        action:@selector(togglePlayAudio:)],
                          
                          [[UIBarButtonItem alloc] initWithTitle:@" AUDIO "
                                                           style:UIBarButtonItemStylePlain
                                                          target:nil
                                                          action:NULL],
                          
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                        target:self
                                                                        action:@selector(stopAudio)],
                          ];

    self.toolbarItems.firstObject.enabled = _avPlayer.status == AVPlayerStatusReadyToPlay;
    self.navigationController.toolbarHidden = NO;
}

- (void) playerItemDidReachEnd:(NSNotification *)n
{
    [self stopAudio];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == _avPlayer &&
        [keyPath isEqualToString:@"status"])
    {
        if (_avPlayer.status == AVPlayerStatusFailed) {
            
            NSLog(@"avPlayer fail: %@", _avPlayer.error);
            [self stopAudio];
            
        } else if (_avPlayer.status == AVPlayerStatusReadyToPlay) {
            
            [self avPlayerDidReady];
            
        } else if (_avPlayer.status == AVPlayerStatusUnknown) {
            
        }
    }
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
    }
    
    id item = _items[indexPath.row];

    if ([item isKindOfClass:[NSURL class]]) {
        cell.textLabel.text = ((NSURL *)item).query.stringByRemovingPercentEncoding;
    } else if ([item isKindOfClass:[NSString class]]) {
        cell.textLabel.text = ((NSString *)item).lastPathComponent;
    } else {
        cell.textLabel.text = @"?";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    id item = _items[indexPath.row];
    
    if ([item isKindOfClass:[NSURL class]]) {
        
        [self presentTarItem:item];
        
    } else if ([item isKindOfClass:[NSString class]]) {
        
        NSString *path = item;
        
        if ([path.pathExtension isEqualToString:@"tar"]) {
            
            BrowserController *vc = [BrowserController new];
            vc.filePath = [_filePath stringByAppendingPathComponent:item];
            [self.navigationController pushViewController:vc animated:YES];
            
        } else if ([path.pathExtension isEqualToString:@"mp3"] ||
                   [path.pathExtension isEqualToString:@"m4a"] ||
                   [path.pathExtension isEqualToString:@"m4b"])
        {
            NSString *fullPath = [_filePath stringByAppendingPathComponent:path];
            NSURL *URL = [NSURL fileURLWithPath:fullPath];
            [self playAudio:URL];
        }
    }
}

#pragma mark - QLPreviewController

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return _previewItem;
}

@end
