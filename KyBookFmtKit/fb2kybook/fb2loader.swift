//
//  fb2loader.swift
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

import Foundation

enum FB2LoaderError : ErrorType {
    case BadRoot
}

final class FB2Loader : NSObject, NSXMLParserDelegate {
    
    private var error : FB2LoaderError?
    private var package : FB2Package?
    private var stack = [Any]()
    private var text = ""
    private var sectionNo = 0
    
    static func loadPackage(path : String) throws -> FB2Package?  {
        
        let xmlData = try NSData(contentsOfFile: path, options: NSDataReadingOptions(rawValue: 0))
        return try FB2Loader().loadPackage(xmlData)
    }
    
    private final func loadPackage(xmlData : NSData) throws -> FB2Package?  {
        
        let parser = NSXMLParser(data: xmlData)
        
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.shouldResolveExternalEntities = false
        parser.delegate = self
        
        if !parser.parse() {
            
            if let err = self.error {
                throw err
            } else if let err = parser.parserError {
                throw err
            }
        }
        
        return self.package
    }
    
    internal func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {

        self.flushText()
        
        let atts = FB2Loader.dropNamespace(attributeDict)
        let elname = elementName.lowercaseString
        var item : Any?
        
        if let parent = self.stack.last {
            
            let id = atts["id"]
            
            if let package = parent as? FB2Package {
                
                switch(elname) {

                case "description":
                    item = package.desc
                    
                case "body":
                    let body = FB2Body(id: id, name: atts["name"], lang: atts["lang"], orderNo:self.sectionNo++)
                    package.bodies.append(body)
                    item = body
                    
                case "binary":
                    if let id = id {
                        let binary = FB2Binary(id: id, contentType: atts["content-type"] ?? "")
                        package.binaries.append(binary)
                        item = binary
                    }
                    
                case "stylesheet":
                    item = package.stylesheet
                    
                default: break
                }
                
            } else if let desc = parent as? FB2Description {
                
                switch(elname) {
                case "title-info":      item = desc.titleInfo
                case "src-title-info":  item = desc.srcTitleInfo
                case "document-info":   item = desc.documentInfo
                case "publish-info":    item = desc.publishInfo
                default:                break;
                }
                
            } else if let titleInfo = parent as? FB2TitleInfo {
                
                switch(elname) {

                case "book-title":
                    item = titleInfo.title
                    
                case "author":
                    let person = FB2Person()
                    titleInfo.authors.append(person)
                    item = person
                    
                case "translator":
                    let person = FB2Person()
                    titleInfo.translators.append(person)
                    item = person
                    
                case "genre":
                    let genre = FB2TextElement()
                    titleInfo.genres.append(genre)
                    item = genre
                    
                case "annotation":
                    titleInfo.annotation = FB2Text(kind:FB2NodeKind.Annotation, id: id)
                    item = titleInfo.annotation;
                    
                case "keywords":
                    item = titleInfo.keywords

                case "date":
                    item = titleInfo.date
                    
                case "coverpage":
                    titleInfo.coverpage = FB2NodeWithTree(kind:FB2NodeKind.Coverpage, id: id)
                    item = titleInfo.coverpage;
                    
                case "lang":
                    item = titleInfo.lang
                    
                case "src-lang":
                    item = titleInfo.srcLang
                    
                case "sequence":
                    
                    if let name = atts["name"] {
                        
                        var number : Int = 0
                        if let s = atts["number"] {
                            number = Int(s) ?? 0
                        }
                        
                        let sequence = FB2Sequence(name:name, number:number)
                        titleInfo.sequences.append(sequence)
                        item = sequence                        
                    }
                    
                default: break;
                }
                
            } else if let publishInfo = parent as? FB2PublishInfo {
                
                switch(elname) {
                    
                case "book-name":   item = publishInfo.bookName
                case "publisher":   item = publishInfo.publisher
                case "city":        item = publishInfo.city
                case "year":        item = publishInfo.year
                case "isbn":        item = publishInfo.isbn
                    
                case "sequence":
                    
                    if let name = atts["name"] {
                        
                        var number : Int = 0
                        if let s = atts["number"] {
                            number = Int(s) ?? 0
                        }
                        
                        let sequence = FB2Sequence(name:name, number:number)
                        publishInfo.sequences.append(sequence)
                        item = sequence
                    }
                    
                default: break;
                }
                
            } else if let documentInfo = parent as? FB2DocumentInfo {
                
                switch(elname) {
                case "id":              item = documentInfo.id
                case "date":            item = documentInfo.date
                case "src-url":         item = documentInfo.srcUrl
                case "src-ocr":         item = documentInfo.srcOcr
                case "program-used":    item = documentInfo.programUsed
                case "version":         item = documentInfo.version
                case "author":          item = documentInfo.author
                default:                break;
                }
                
            } else if let section = parent as? FB2Section {
                
                switch(elname) {
                                        
                case "title":
                    section.title = FB2NodeWithTree(kind:FB2NodeKind.Title, id: id)
                    item = section.title
                    
                case "epigraph":
                    let epigraph = FB2NodeWithTree(kind:FB2NodeKind.Epigraph, id: id)
                    section.epigraphs.append(epigraph)
                    item = epigraph
                    
                case "annotation":
                    section.annotation = FB2NodeWithTree(kind:FB2NodeKind.Annotation, id: id)
                    item = section.annotation
                    
                case "section":
                    let subsection = FB2Section(id:id, orderNo:self.sectionNo++, level:section.level+1)
                    section.sections.append(subsection)
                    item = subsection
                    
                default:
                    let node = FB2Loader.mkNode(elname, id:id, atts:atts)
                    if let child = node {
                        section.tree.append(child)
                        item = child
                    }
                }
                
            } else if let node = parent as? FB2NodeWithTree {
                
                if let child = FB2Loader.mkNode(elname, id:id, atts:atts) {
                    node.tree.append(child)
                    item = child
                }
                
            } else if let person = parent as? FB2Person {
                    
                switch (elname) {
                case "first-name":  item = person.firstName
                case "middle-name": item = person.middleName
                case "last-name":   item = person.lastName
                case "id":          item = person.id
                case "home-page":   item = person.link
                case "nickname":    item = person.nickname
                case "email":       item = person.email
                default:            break;
                }
            }
            
            if (item == nil) {
                print("skip at \(parser.lineNumber): \(parent)/\(elname) ")
            }
            
        } else if (elname == "fictionbook") {
            
            self.package = FB2Package();
            item = self.package
            
        } else {
            
            self.error = FB2LoaderError.BadRoot
            parser.abortParsing()
            return;
        }
        
        let node = item ?? elname
        self.stack.append(node)
    }
    
    internal func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    
        let text = self.flushText()
        
        if let last = self.stack.last {
            
            if let text = text {
                
                if let binary = last as? FB2Binary {
                    
                    binary.data = NSData(base64EncodedString: text, options: .IgnoreUnknownCharacters)
                    
                } else if let textElement = last as? FB2TextElement {
                    
                    textElement.text = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                }
            }
            
            self.stack .removeLast()
        }
    }
    
    internal func parser(parser: NSXMLParser, foundCharacters string: String) {
       
        self.text += string
    }
    
    private final func flushText() -> String? {
        
        if (self.text.isEmpty) {
            return nil;
        }
        
        let text = self.text;
        self.text = "";
        
        if let last = self.stack.last {
            if let textNode = last as? FB2Text {
                textNode.tree.append(text)
                return nil;
            }
        }
        
        return text;
    }
    
    private static func mkNode(name: String, id: String?, atts: [String : String]) -> FB2Node? {
    
        guard let kind = FB2NodeKind.fromString(name) else {
            return nil;
        }
        
        switch(kind) {
            
        case .Annotation, .Cite, .Code, .Date, .Emphasis, .Epigraph, .Para, .PoemRow, .Stanza, .Strikethrough, .Strong, .Subtitle, .Sub, .Sup, .Td, .Th, .Title, .TextAuthor:

            return FB2Text(kind: kind, id: id)
            
        case .Poem, .Table, .Tr:
            
            return FB2NodeWithTree(kind: kind, id: id)
            
        case .Style:
            
            return FB2Style(id:id, name:atts["name"])
            
        case .EmptyLine:
            
            return FB2NodeEmptyLine()
            
        case .Link:
            
            if let s = atts["href"] {
                //let href = s.hasPrefix("#") ? s.substringFromIndex(s.startIndex.successor()) : s
                return FB2Link(id:id, href: s, type:atts["type"])
            }
            
        case .Image :
            
            if let s = atts["href"] {
                let href = s.hasPrefix("#") ? s.substringFromIndex(s.startIndex.successor()) : s
                return FB2Image(id:id, href: href, title:atts["title"])
            }
            
        default: break
        }
        
        return nil
    }
    
    private static func dropNamespace(atts : [String : String]) -> [String : String] {
        
        var tmp = atts
        
        for (k, v) in atts {
        
            if let r = k.rangeOfString(":") {
                
                tmp[k] = nil
                let kk = k.substringFromIndex(r.startIndex.successor())
                if (!kk.isEmpty) {
                    tmp[kk] = v
                }
            }
        }
        
        return tmp
    }
}
