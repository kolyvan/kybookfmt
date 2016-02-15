//
//  fb2markdown.swift
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

// FIXME: INCOMPLETE

import Foundation

class FB2MarkdownOpt {
    
    let level: Int
    var processWhitespaces = true
    
    init(level: Int) {
        self.level = level
    }
    convenience init() {
        self.init(level: 0)
    }
    
    var titlePrefix : String  {
        return String(min(5, level+1), Character("#"))
    }
    var subtitlePrefix : String  {
        return String(min(6, level+2), Character("#"))
    }
}


class FB2Markdown {

    static func markdown(node: FB2Node, opt:FB2MarkdownOpt) -> String {
        
        if node is FB2NodeEmptyLine {
            
            return "\n"
            
        } else if let p = node as? FB2Image {
            
            return "![](\(p.href)) "
            
        } else if let p = node as? FB2Link {
        
            let s = self.markdown(p, opt:opt)
            if !s.isEmpty {
                return "[\(s)](\(p.href)) "
            }
            
        } else if let p = node as? FB2Style {
            
            let s = self.markdown(p, opt:opt)
            return s; // TODO: style.name ?
            
        } else if let p = node as? FB2Text {

            if p.kind == .Code {
                opt.processWhitespaces = false
            }
            
            let s = self.markdown(p, opt:opt)
            
            if p.kind == .Code {
                opt.processWhitespaces = true
            }
            
            if !s.isEmpty {
                
                switch p.kind {
                case .Annotation:   return "\n" + s + "\n"
                case .Cite:         return "\n" + self.mkBlock(s, indent:"> ")  + "\n"
                case .Code:         return self.codeFence + s + self.codeFence
                case .Date:         return self.emphasis + s + self.emphasis
                case .Emphasis:     return self.emphasis + s + self.emphasis
                case .Epigraph:     return "\n" + self.emphasis + s + self.emphasis + "\n"
                case .Para:         return "\n" + s + "\n"
                case .PoemRow:      return "\n" + s
                case .Stanza:       return "\n" + s  + "\n"
                case .Strikethrough:return "~~" + s + "~~"
                case .Strong:       return self.strong + s + self.strong
                case .Subtitle:     return opt.subtitlePrefix + " " + s + "\n"
                case .Sub:          return "<sub>" + s + "</sub>"
                case .Sup:          return "<sup>" + s + "</sup>"
                case .Td:           return s
                case .Th:           return s
                case .Title:        return opt.titlePrefix + " " + s + "\n"
                case .TextAuthor:   return self.strong + s + self.strong
                default:            return s
                }
            }
            
        } else if let p = node as? FB2NodeWithTree {
            
            let s = self.markdown(p, opt:opt)
            if !s.isEmpty {
                
                switch p.kind {
                case .Poem:     return "\n" + s + "\n"
                case .Table:    return "\n" + s + "\n"
                case .Tr:       return "\n" + s
                default:        return s
                }
            }
        }
        
        return ""
    }
    
    static func markdown(node:FB2NodeWithTree, opt:FB2MarkdownOpt) -> String {
    
        var buffer = ""
        
        for p in node.tree {
        
            if let s = p as? String {
                
                if (opt.processWhitespaces) {
                    
                    buffer += self.escapeText(FB2Utils.trimWhitespaces(s))
                                        
                } else {
                
                    buffer += s
                }
                
            } else if let n = p as? FB2Node {
                
                buffer += self.markdown(n, opt:opt)
            }
        }
    
        return buffer
    }
    
    static func mkBlock(text: String, indent: String) -> String {
        
        var buffer = ""
        
        text.enumerateLines { (line, stop) -> () in
            
            buffer += indent
            buffer += line
            buffer += "\n"
        }
        
        return buffer
    }
    
    static func mkSpan(text: String, mark: String) -> String {
        
        var buffer = ""
        buffer += mark
        buffer += text
        buffer += mark
        return buffer
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
    
    static let backslashEscapedCharacterSet = NSCharacterSet(charactersInString:"\\`*_{}[]()#+-.!")
    
    static let codeFence  = "\n```\n"
    static let emphasis = "*"
    static let strong = "**"
}
