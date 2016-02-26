//
//  main.swift
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 07.02.16.
//  Copyright © 2016 Konstantin Bukreev. All rights reserved.
//

import Foundation
import KyBookFmtKitOSX


func listItemsInTar(path: String) {
    
    guard let reader = KyBookFmtReader(path: path) else {
        return
    }
    for item in reader.items {
        print("\(item.path) size:\(item.size)")
    }
}

func processFb2File(fb2Path: String, outPath: String, args: [String:String]) {
    
    do {
        
        if let package = try FB2Loader.loadPackage(fb2Path) {
            
            if let title = package.desc.titleInfo.title.text {
                print("loaded '\(title)'")
            }
            
            var opt = FB2KyBook.Options();
            
            if let val = args["gzip"] {
                switch val {
                case "0", "n", "no": opt.gzipChapter = false
                default: break
                }
            }
            
            if try FB2KyBook.convertPackage(package, outPath:outPath, opt: opt) {
                print("done \(outPath)")
            }
        }
        
    } catch let err {
        print("failed: \(err)")
    }    
}

func run() {

    guard Process.arguments.count > 1 else {
        print("usage: file [gzip n|y]")
        return
    }
    
    let file = Process.arguments[1]
    
    var args = [String:String]()
    
    if Process.arguments.count > 2  {
        
        var key : String?
        for arg in Process.arguments.dropFirst(2) {
            if let s = key  {
                args[s] = arg
                key = nil
            } else {
                key = arg
            }
        }
    }
    
    print("process file: \(file) args: \(args)")
    
    let pathExt = (file as NSString).pathExtension
    
    switch (pathExt) {
    
    case "tar":
        listItemsInTar(file)
        
    case "fb2":
        let outPath = file + ".tar"
        processFb2File(file, outPath:outPath, args: args)
        
    default:
        print("unsupported format: \(pathExt)")
    }
}

run()
