//
//  fb2koobmark.swift
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 12.02.16.
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

class FB2Koobmark {
    
    class Options {
        
        let level: Int
        
        init(level: Int) {
            self.level = level
        }
        
        convenience init() {
            self.init(level: 0)
        }
        
        var titleTag : String  {
            let lvl = min(4, level+1)
            return "t\(lvl)"
        }
        
        var subtitleTag : String  {
            let lvl = min(5, level+2)
            return "t\(lvl)"
        }
        
        func subLevel() -> Options {
            return Options(level: self.level + 1)
        }
    }

    internal static func mkString(node: FB2Node, opt:Options) -> String {
        
        var text = ""
        
        if node is FB2NodeEmptyLine {
            
            text = "\n{%emptyline}"
            
        } else if let p = node as? FB2Image {
            
            text = "{&" + p.href + "}"
            
        } else if let p = node as? FB2Link {
            
            let s = self.mkStringTree(p.tree, opt:opt)
            if !s.isEmpty {
                text = "{@" + p.href + " " + s + "}"
            }
            
        } else if let p = node as? FB2Style {
            
            let s = self.mkStringTree(p.tree, opt:opt)
            if !s.isEmpty {
                text = "{." + (p.name ?? "") + " " + s + "}"
            }
            
        } else if let p = node as? FB2NodeWithTree {
            
            let s = self.mkStringTree(p.tree, opt:opt)
            if !s.isEmpty {
                
                switch p.kind {
                case .Annotation:   text = "{%annotation " + s + "}"
                case .Cite:         text = "{q " + s + "}"
                case .Code:         text = "{;\n" + s + "\n}"
                case .Date:         text = "{.date " + s + "}"
                case .Emphasis:     text = "{i " + s + "}"
                case .Epigraph:     text = "{%epigraph " + s + "}"
                case .Para:         text = "{¶ " + s + "}"
                case .Poem:         text = "{%poem " + s + "}"
                case .PoemRow:      text = "{¶ " + s + "}"
                case .Stanza:       text = "{%stanza " + s + "}"
                case .Strikethrough:text = "{s " + s + "}"
                case .Strong:       text = "{b " + s + "}"
                case .Subtitle:     text = "{" + opt.subtitleTag + " " + s + "}"
                case .Sub:          text = "{, " + s + "}"
                case .Sup:          text = "{^ " + s + "}"
                case .Table:        text = "{= " + s + "}"
                case .Tr:           text = "{- " + s + "}"
                case .Td:           text = "{| " + s + "}"
                case .Th:           text = "{| " + s + "}"
                case .Title:        text = "{" + opt.titleTag + " " + s + "}"
                case .TextAuthor:   text = "{.author " + s + "}"
                default:            break
                }
            }
        }
        
        if !text.isEmpty {
            if let id = node.id {
                text = "{#" + id + " " + text + "}"
            }
        }
        
        return text
    }
    
    internal static func mkStringTree(tree:[Any], opt:Options) -> String {
        
        var buffer = ""
        
        for p in tree {
            
            if let s = p as? String {
                buffer += self.escapeText(FB2Utils.trimWhitespaces(s))
            } else if let n = p as? FB2Node {
                let s = self.mkString(n, opt:opt)
                if !s.isEmpty {
                    if n.kind.isBlockNode && !buffer.isEmpty && buffer.hasSuffix("}") {
                        buffer += "\n";
                    }
                    buffer += s
                }
            }
        }
        
        return buffer
    }
    
    static func mkString(section: FB2Section, isNote: Bool) -> String? {
        
        var buffer = ""
        
        if let s = self.mkStringExtenso(section) {
            buffer += s
        }
        
        let text = self.mkStringTree(section.tree, opt: Options(level: section.level+1));
        if !text.isEmpty {
            if !buffer.isEmpty {
                buffer += "\n";
            }
            buffer += "{%" + (isNote ? "note" : "main") + " " + text + "}"
        }
        
        if buffer.isEmpty {
            return nil
        }
        
        if let id = section.id {
            if isNote {
                buffer = "{#" + id + " " + buffer + "}"
            } else {
                buffer = "{#" + id + "}" + buffer
            }
        }
        
        return buffer + "\n"
    }
    
    static func mkStringExtenso(section: FB2Section) -> String? {
    
        let opt = Options(level: section.level+1)
        
        var buffer = ""
        
        if section.sections.count > 0 {
            if let image = section.image {
                buffer += self.mkString(image, opt: opt)
            }
        }
        
        if let title = section.title {
            let s = self.mkString(title, opt: opt)
            if !s.isEmpty {
                if !buffer.isEmpty {
                    buffer += "\n"
                }
                buffer += s
            }
        }
        
        if let annotation = section.annotation {
            let s = self.mkString(annotation, opt: opt.subLevel())
            if !s.isEmpty {
                if !buffer.isEmpty {
                    buffer += "\n"
                }
                buffer += s
            }
        }
        
        for epigraph in section.epigraphs {
            let s = self.mkString(epigraph, opt: opt.subLevel())
            if !s.isEmpty {
                if !buffer.isEmpty {
                    buffer += "\n"
                }
                buffer += s
            }
        }
        
        if buffer.isEmpty {
            return nil;
        }
        
        return "{h " + buffer + "}"
    }
    
    static func mkStringTitlePage(manifest: KyBookFmtManifest, package: FB2Package) -> String? {
    
        var buffer = ""
        
        if let title = manifest.title {
            
            buffer += "{t1 "
            buffer += title
            buffer += "}\n"
        }
        
        if let authors = manifest.authors {
            
            for author in authors {
                
                buffer += "{%author "
                buffer += author
                buffer += "}\n"
            }
        }
        
        if let sequence = manifest.sequence {
            
            buffer += "{%sequence "
            buffer += sequence
            if manifest.sequenceNo > 0 {
                buffer += " \(manifest.sequenceNo)"
            }
            buffer += "}\n"
        }
        
        if let publisher = manifest.publisher {
            
            buffer += "{%publisher "
            buffer += publisher
            if let date = manifest.date {
                buffer += " "
                buffer += date
            }
            buffer += "}\n"
        }
        
        if let annotation = package.desc.titleInfo.annotation {
            buffer += self.mkString(annotation, opt: Options(level:2))
        }

        if buffer.isEmpty {
            return nil;
        }
        
        return "{%titlepage " + buffer + "}\n"
    }

    static func escapeText(text: String) -> String {
        
        let charset = self.backslashEscapedCharacterSet
        let scanner = NSScanner(string: text)
        scanner.charactersToBeSkipped = nil
        
        scanner.scanUpToCharactersFromSet(charset, intoString:nil)
        if !scanner.scanCharactersFromSet(charset, intoString:nil) {
            return text
        }
        
        var buffer = ""
        
        scanner.scanLocation = 0
        while !scanner.atEnd {
            
            if let s = scanner.scanCharactersFromSet(charset) {
                
                for ch in s.characters {
                    
                    buffer += "\\"
                    buffer += String(ch)
                }
            }
            
            if let s = scanner.scanUpToCharactersFromSet(charset) {
                buffer += s
            }
        }
        
        return buffer
    }
    
    static let backslashEscapedCharacterSet = NSCharacterSet(charactersInString:"{}")
}
