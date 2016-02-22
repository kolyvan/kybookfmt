//
//  fb2kybook.swift
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 08.02.16.
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

import Foundation
import KyBookFmtKitOSX

class FB2KyBook {
    
    struct Options {
        
        enum ChapterFormat {
            case Text, Koobmark
        }
        
        var chapterFormat : ChapterFormat = .Koobmark
        var gzipChapter = true
        var flattenToc = true
        
        var chapterPathExt : String {
            switch self.chapterFormat {
            case .Text: return "txt"
            case .Koobmark: return "km"
            }
        }
    }
    
    typealias ListOfTocItems = [[String : AnyObject]]
    
    class Chapter {
        
        let title: String
        let path: String
        let content: NSData
        
        init(title: String, path: String, content: NSData) {
            self.title = title
            self.path = path
            self.content = content
        }

        func gzipContent() -> Chapter {

            if (self.content.length > 256) {
                if let data = KxGzipArchive.gzipData(self.content) {
                    if (data.length < self.content.length) {
                        return Chapter(title: self.title, path: self.path + ".gz", content: data)
                    }
                }
            }
            return self
        }
    }
    
    class BuilderChapters {
        
        var result = [[FB2Section]]()
        var accum = [FB2Section]()
        
        final func collectSection(section: FB2Section)  {
            
            accum.append(section)
            
            if section.sections.isEmpty {
                
                result.append(accum)
                accum.removeAll()
                
            } else {
                
                for subsection in section.sections {
                    self.collectSection(subsection)
                }
            }
        }
        
        final func finishCollect() {
            
            if !accum.isEmpty {
                result.append(accum)
                accum.removeAll()
            }
        }
        
        static func collectSections(sections: [FB2Section]) -> [[FB2Section]] {
            
            let builder = BuilderChapters()
            for section in sections {
                builder.collectSection(section)
                builder.finishCollect()
            }
            return builder.result
        }
    }

    static func convertPackage(package: FB2Package, outPath: String, opt: Options = Options()) throws -> Bool {
        
        guard let writer = KyBookFmtWriter(path:outPath) else {
            return false
        }
        
        defer {
            writer.closeWriter()
        }
        
        let manifest = self.manifestFromPackage(package)
        try writer.writeManifest(manifest)
                
        var (chapters, notesList, tocMap) = self.buildChapters(package, opt: opt)
        
        var index = [String]()
        var guide = [[String : String]]()
        
        if let coverpages = self.buildCoverpages(package) {
            index.appendContentsOf(coverpages)
        }
        
        var titlePage : Chapter? = nil
        
        if var content = self.buildTitlePageContent(manifest, package: package, opt: opt) {
            
            var path = "titlepage." + opt.chapterPathExt
            
            if (opt.gzipChapter && content.length > 256) {
                if let data = KxGzipArchive.gzipData(content) {
                    if (data.length < content.length) {
                        content = data
                        path += ".gz"
                    }
                }
            }
            
            let title = manifest.title ?? "Title Page"
            titlePage = Chapter(title:title, path:path, content:content)
            index.append(path)
        }
        
        if (opt.gzipChapter) {
            
            chapters = chapters.map{ $0.gzipContent() }
            notesList = notesList.map{ $0.gzipContent() }
        }
        
        for chapter in chapters {
            index.append(chapter.path)
        }
        
        for notes in notesList {
            guide.append([ "path" : notes.path, "title" : notes.title, "kind" : "notes" ])
        }

        var toc = self.buildToc(package, tocMap: tocMap)
        if opt.flattenToc {
            toc = self.flattenToc(toc)
        }
        
        try writer.writeIndex(index)
        try writer.writeToc(toc)
        
        if !guide.isEmpty {
            try writer.writeGuide(guide)
        }
        
        if let titlePage = titlePage {
            try writer.writeData(titlePage.content, path: titlePage.path)
        }
        
        for chapter in chapters {
            try writer.writeData(chapter.content, path: chapter.path)
        }
        
        for notes in notesList {
            try writer.writeData(notes.content, path: notes.path)
        }
        
        for binary in package.binaries {
        
            if let data = binary.data {
                try writer.writeData(data, path:binary.id)
            }
        }
        
        return true        
    }
    
    static func manifestFromPackage(package: FB2Package) -> KyBookFmtManifest {
    
        let manifest = KyBookFmtManifest()
        
        let titleInfo = package.desc.titleInfo
        let srcTitleInfo = package.desc.srcTitleInfo
        let publishInfo = package.desc.publishInfo
        let documentInfo = package.desc.documentInfo
        
        manifest.version = 1
        manifest.kind = .TextBook
        
        manifest.title = titleInfo.title.trimmedText ?? srcTitleInfo.title.trimmedText ?? publishInfo.bookName.trimmedText
        
        let authors = titleInfo.authors.isEmpty ? srcTitleInfo.authors : titleInfo.authors
        manifest.authors = authors.flatMap{ $0.fullName }
        
        let translators = titleInfo.translators.isEmpty ? srcTitleInfo.translators : titleInfo.translators
        manifest.translators = translators.flatMap{ $0.fullName }
        
        let genres = titleInfo.genres.isEmpty ? srcTitleInfo.genres : titleInfo.genres
        manifest.subjects = genres.flatMap{ $0.text } // TODO: lookup for name of genres
        
        if let s = documentInfo.id.trimmedText {
            manifest.ids = [s]
        }
        
        let sequences = titleInfo.sequences.isEmpty ? srcTitleInfo.sequences : titleInfo.sequences
        if let sequence = sequences.first {
            
            manifest.sequence = sequence.name
            if let number = sequence.number {
                manifest.sequenceNo = UInt(number)
            }
        }
        
        manifest.isbn = publishInfo.isbn.trimmedText
        manifest.link = documentInfo.srcUrl.trimmedText ?? documentInfo.srcOcr.trimmedText
        manifest.publisher = publishInfo.publisher.trimmedText
        manifest.date = publishInfo.year.trimmedText ?? titleInfo.date.trimmedText ?? srcTitleInfo.date.trimmedText
        manifest.language = titleInfo.srcLang.trimmedText
        manifest.keywords = titleInfo.keywords.trimmedText ?? srcTitleInfo.keywords.trimmedText
        manifest.annotation = titleInfo.annotation?.asString() ?? srcTitleInfo.annotation?.asString()
        
        manifest.cover = (titleInfo.coverpage?.allImagesHref() ?? srcTitleInfo.coverpage?.allImagesHref())?.first
        // TODO: thumbnail;
        
        if let creator = documentInfo.author.fullName {
            manifest.creator = creator
        }
        manifest.timestamp = documentInfo.date.trimmedText
        
        return manifest
    }
    
    static func buildChapters(package: FB2Package, opt: Options) -> ([Chapter], [Chapter], [String : String]) {
        
        var chapters = [Chapter]()
        var notes = [Chapter]()
        var tocMap = [String : String]()
        
        var bodyNo = 1
        var notesNo = 1
        
        for body in package.bodies {
            
            if body.name == "notes" || body.name == "comments" {
                
                let title = body.title?.asString() ?? "Notes \(notesNo)"
                let path = "notes_\(notesNo)." + opt.chapterPathExt
                
                if let chapter = self.buildChapter(body, title:title, path:path, opt:opt) {
                    notes.append(chapter)
                }
                
                notesNo += 1
                
            } else {
                
                if let data = self.buildChapterExtenso(body, opt: opt)?.dataUsingEncoding(NSUTF8StringEncoding) {
                    
                    let name = body.name ?? "Book \(bodyNo)"
                    let title = body.title?.asString() ?? name
                    let path = "book_\(bodyNo)." + opt.chapterPathExt
                    
                    let chapter = Chapter(title: title, path: path, content: data)
                    chapters.append(chapter)
                    
                    if let id = body.id {
                        tocMap[id] = path
                    }
                }
                
                var chapterNo = 1;
                
                for sections in BuilderChapters.collectSections(body.sections) {
                    
                    if let data = self.buildChapterContent(sections, isNote: false, opt: opt) {
                      
                        if let first = sections.first {
                            
                            //let chapterNo = first.orderNo
                            let title = first.title?.asString() ?? "Chapter \(chapterNo)"
                            let path = "chapter_\(bodyNo)_\(chapterNo)." + opt.chapterPathExt
                            let chapter = Chapter(title: title, path: path, content: data)
                            chapters.append(chapter)
                                                        
                            for section in sections {
                                if let id = section.id {
                                    tocMap[id] = path
                                }
                            }
                        }
                    }
                    
                    chapterNo += 1
                }
                                
                bodyNo += 1
            }
        }
        
        return (chapters, notes, tocMap)
    }
    
    static func buildChapter(body: FB2Body, title: String, path: String, opt: Options) -> Chapter? {
    
        let sections = self.collectSection(body);
        if let data = self.buildChapterContent(sections, isNote: body.name == "notes", opt: opt) {
            return Chapter(title: title, path: path, content: data)
        }
        return nil
    }
    
    static func collectSection(section: FB2Section) -> [FB2Section] {
    
        var result = [section]
        for section in section.sections {
            let sections = self.collectSection(section)
            result.appendContentsOf(sections)
        }
        return result
    }
    
    static func buildChapterContent(sections: [FB2Section], isNote : Bool, opt: Options) -> NSData? {
        
        var buffer = ""
        
        for section in sections {
            
            if !buffer.isEmpty {
                buffer += "\n\n"
            }
            
            var text : String? = nil
            if (opt.chapterFormat == .Text) {
                text = FB2PlainText.mkString(section)
            } else if (opt.chapterFormat == .Koobmark) {
                text = FB2Koobmark.mkString(section, isNote: isNote)
            }
            if let text = text {
                buffer += text
            }
        }
        
        if buffer.isEmpty {
            return nil
        }
        
        return buffer.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    static func buildChapterExtenso(section: FB2Section, opt: Options) -> String? {
    
        // abrégé, extenso, summary
        if (opt.chapterFormat == .Text) {
            return FB2PlainText.mkStringExtenso(section)
        } else if (opt.chapterFormat == .Koobmark) {
            return FB2Koobmark.mkStringExtenso(section)
        }
        return nil
    }
    
    static func buildCoverpages(package: FB2Package) -> [String]? {
    
        var covers = [String]()
        
        if let tree = package.desc.titleInfo.coverpage?.tree {
            for p in tree {
                if let image = p as? FB2Image {
                    if nil != package.findBinary(image.href) {
                        covers.append(image.href)
                    }
                }
            }
        }
        
        return covers.isEmpty ? nil : covers
    }
    
    static func buildTitlePageContent(manifest: KyBookFmtManifest, package: FB2Package,  opt: Options) -> NSData? {
        
        var text : String? = nil
        
        if (opt.chapterFormat == .Text) {
            text = FB2PlainText.mkStringTitlePage(manifest)
        } else if (opt.chapterFormat == .Koobmark) {
            text = FB2Koobmark.mkStringTitlePage(manifest, package: package)
        }
        
        if let text = text {
            return text.dataUsingEncoding(NSUTF8StringEncoding)
        }
        return nil
    }
    
    static func buildToc(package: FB2Package, tocMap: [String:String]) -> ListOfTocItems {
        
        var toc = ListOfTocItems()
        
        let bodies = package.bodies.filter{ $0.name != "notes" }
        
        if bodies.count > 1 {
            
            for body in bodies {
                if let item = self.buildTocItem(body, tocMap:tocMap) {
                    toc.append(item)
                }
            }
            
        } else if let first = bodies.first  {
            
            for section in first.sections {
                if let item = self.buildTocItem(section, tocMap:tocMap) {
                    toc.append(item)
                }
            }
        }
        
        return toc
    }
    
    static func buildTocItem(section: FB2Section, tocMap: [String:String]) -> [String : AnyObject]? {
    
        var children = [[String : AnyObject]]()
        
        for subsection in section.sections {
            if let item = self.buildTocItem(subsection, tocMap: tocMap) {
                children.append(item)
            }
        }
        
        let title = section.title?.asString()
        
        var path : String?
        if let id = section.id {
            if let sectionPath = tocMap[id] {
                path = sectionPath + "#" + id
            }
        }
        
        if !children.isEmpty ||
            (title != nil && path != nil)
        {
            var item = [String : AnyObject]()
            
            item["title"] = title ?? "-"
            
            if let path = path {
                item["path"] = path
            }
            
            if !children.isEmpty {
                item["children"] = children
            }
            
            return item
        }
        
        return nil
    }
    
    static func flattenToc(toc: ListOfTocItems, level: Int = 0) -> ListOfTocItems {
        
        var result = [[String : AnyObject]]()
        
        for item in toc {
        
            var resItem = item
            
            if level > 0 {
                resItem["level"] = level
            }
            
            if let children = resItem["children"] {
                
                resItem["children"] = nil
                result.append(resItem)
                
                if let subitems = children as? ListOfTocItems {
                
                    let flattenSubItems = self.flattenToc(subitems, level:level+1)
                    result.appendContentsOf(flattenSubItems)
                }
                
            } else {
            
                result.append(resItem)
            }
        }
        
        return result
    }
}

extension FB2NodeWithTree {

    func asString() -> String? {
    
        var buffer = ""
        
        for p in self.tree {
        
            if p is FB2NodeEmptyLine {
                
                buffer += "\n"
                
            } else if let node = p as? FB2NodeWithTree {
                
                if let s = node.asString() {
                
                    if !buffer.isEmpty &&
                       (node.kind == .Annotation ||
                        node.kind == .Epigraph ||
                        node.kind == .Cite ||
                        node.kind == .Code ||
                        node.kind == .Para ||
                        node.kind == .Poem ||
                        node.kind == .Stanza ||
                        node.kind == .PoemRow ||
                        node.kind == .Subtitle ||
                        node.kind == .Title ||
                        node.kind == .Tr ||
                        node.kind == .TextAuthor)
                    {
                        buffer += "\n"
                    }
                    
                    buffer += s
                }
                
            } else if let s = p as? String {
                
                buffer += FB2Utils.trimWhitespaces(s)
            }
        }
        
        if (buffer.isEmpty) {
            return nil
        }
        
        return buffer.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

    func allImagesHref() -> [String]? {
    
        var result = [String]()
        
        for p in self.tree {
            
            if let image = p as? FB2Image {
                
                result.append(image.href)
                
            } else if let node = p as? FB2NodeWithTree {
                
                if let images = node.allImagesHref() {
                    
                    result.appendContentsOf(images)
                }
            }
        }
        
        return result.isEmpty ? nil : result
    }
}
