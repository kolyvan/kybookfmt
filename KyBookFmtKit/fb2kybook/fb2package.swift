//
//  FB2Loader.swift
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


enum FB2NodeKind : Int {
    
    case None = 0, Annotation, Cite, Code, Coverpage, Date, EmptyLine, Emphasis, Epigraph, Para, Poem, PoemRow, Section, Stanza, Strikethrough, Strong, Style, Subtitle, Sub, Sup, Table, Td, Th, Tr, Title, TextAuthor, Link, Image
    
    static func fromString(name : String) -> FB2NodeKind? {
        switch (name) {
        case "annotation" : return .Annotation
        case "cite" : return .Cite
        case "code" : return .Code
        case "coverpage" : return .Coverpage
        case "date" : return .Date
        case "empty-line" : return .EmptyLine
        case "emphasis" : return .Emphasis
        case "epigraph" : return .Epigraph
        case "p" : return .Para
        case "poem" : return .Poem
        case "v" : return .PoemRow
        case "section" : return .Section
        case "stanza" : return .Stanza
        case "strikethrough" : return .Strikethrough
        case "strong" : return .Strong
        case "style" : return .Style
        case "subtitle" : return .Subtitle
        case "sub" : return .Sub
        case "sup" : return .Sup
        case "table" : return .Table
        case "td" : return .Td
        case "th" : return .Th
        case "tr" : return .Tr
        case "title" : return .Title
        case "text-author" : return .TextAuthor
        case "a" : return .Link
        case "image" : return .Image
        default: return nil
        }
    }
    
    var isBlockNode : Bool {
        
        switch(self) {
        case .Annotation, .Cite, .Code, .Epigraph, .Para, .Poem, .PoemRow, .Section, .Stanza, .Subtitle, .Table, .Tr, .Td, .Th, .Title:
            return true
        default:
            return false
        }
    }
}

class FB2Node //: CustomStringConvertible
{
    
    let kind : FB2NodeKind
    let id   : String?
    
    init(kind: FB2NodeKind, id: String?) {
        
        self.kind = kind
        self.id = id
    }
    
    //var description : String {
    //    let className = _stdlib_getDemangledTypeName(self)
    //    return "<\(className) \(kind)>"
    //}
}

class FB2NodeEmptyLine : FB2Node {
    
    init() {
        super.init(kind: .EmptyLine, id: nil)
    }
}

class FB2NodeWithTree : FB2Node  {
    
    var tree = [Any]()
}

class FB2Text : FB2NodeWithTree {
}

class FB2Style : FB2Text {
    
    let name : String?
    init(id: String?, name: String?) {
        self.name = name
        super.init(kind: .Style, id: id)
    }
}

class FB2Link : FB2Text {

    let href : String
    let type : String?
    
    init(id: String?, href: String, type: String?) {
        
        self.href = href
        self.type = type
        
        super.init(kind: .Link, id:id)
    }
}

class FB2Image : FB2Node {
    
    let href  : String
    let title : String?
    
    init(id: String?, href: String, title: String?) {
        
        self.href = href
        self.title = title
        
        super.init(kind: .Image, id:id)
    }
}

class FB2Section : FB2NodeWithTree {
    
    var title       : FB2NodeWithTree?
    var epigraphs   = [FB2NodeWithTree]()
    var annotation  : FB2NodeWithTree?
    var sections    = [FB2Section]()
    let orderNo     : Int
    let level       : Int
    
    init(id: String?, orderNo: Int, level: Int) {
        
        self.orderNo = orderNo
        self.level = level
        super.init(kind: .Section, id: (id == nil) ? "section\(orderNo)" : id )
    }
    
    var image : FB2Image? {
        for p in self.tree {
            if let img = p as? FB2Image {
                return img;
            }
        }
        return nil
    }
}

class FB2Body : FB2Section {
    
    let name : String?
    let lang : String?
    
    init(id: String?, name: String?, lang: String?, orderNo: Int) {
        
        self.name = name
        self.lang = lang
        
        super.init(id:id , orderNo:orderNo, level:0)
    }
}

class FB2Binary {
    
    let id : String
    let contentType : String
    var data : NSData?

    init(id: String, contentType: String) {
    
        self.id = id
        self.contentType = contentType
    }
}

class FB2TextElement {
    
    var text : String?
    
    var trimmedText : String? {
        if let text = self.text {
            return FB2Utils.trimWhitespaces(text).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        return nil;
    }
}

class FB2Person {
    
    let firstName = FB2TextElement()
    let middleName = FB2TextElement()
    let lastName = FB2TextElement()
    let link = FB2TextElement()
    let id = FB2TextElement()
    let nickname = FB2TextElement()
    let email = FB2TextElement()
    
    var fullName: String? {
        
        var buffer = ""
        
        if let s = firstName.trimmedText {
            buffer += s
        }
        
        if let s = middleName.trimmedText {
            if !buffer.isEmpty {
                buffer += " "
            }
            buffer += s
        }
        
        if let s = lastName.trimmedText {
            if !buffer.isEmpty {
                buffer += " "
            }
            buffer += s
        }
        
        if buffer.isEmpty {
            if let s = nickname.trimmedText {
                return s
            }
        }
        
        return buffer.isEmpty ? nil : buffer
    }
}

class FB2Sequence {
    
    let name : String
    var number : Int?
    
    init(name: String, number: Int?) {
        self.name = name
        self.number = number
    }
}

class FB2TitleInfo {
    
    let title = FB2TextElement()    
    var authors = [FB2Person]()
    var translators = [FB2Person]()
    var genres = [FB2TextElement]()
    var annotation : FB2Text?
    var keywords = FB2TextElement()
    var date = FB2TextElement()
    var coverpage : FB2NodeWithTree?
    var lang = FB2TextElement()
    var srcLang = FB2TextElement()
    var sequences = [FB2Sequence]()
}

class FB2PublishInfo {
    
    var bookName = FB2TextElement()
    var publisher = FB2TextElement()
    var city = FB2TextElement()
    var year = FB2TextElement()
    var isbn = FB2TextElement()
    var sequences = [FB2Sequence]()
}

class FB2DocumentInfo {

    var id = FB2TextElement()
    var date = FB2TextElement()
    var srcUrl = FB2TextElement()
    var srcOcr = FB2TextElement()
    var programUsed = FB2TextElement()
    var version = FB2TextElement()
    var author = FB2Person()
}

class FB2Description {

    let titleInfo = FB2TitleInfo()
    let srcTitleInfo = FB2TitleInfo()
    let publishInfo = FB2PublishInfo()
    let documentInfo = FB2DocumentInfo();
}

class FB2Package {

    let desc = FB2Description()
    var bodies = [FB2Body]()
    var binaries = [FB2Binary]()
    var stylesheet = FB2TextElement()
    
    func findBinary(href: String) -> FB2Binary? {
        return binaries.filter { $0.id == href && $0.data != nil }.first        
    }
}
