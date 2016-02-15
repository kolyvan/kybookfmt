//
//  fb2plaintext.swift
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

class FB2PlainText {
    
    static func mkString(section: FB2Section) -> String? {
        
        var buffer = ""
        
        if let text = self.mkStringExtenso(section) {
            buffer += text
        }
        
        if let text = section.asString() {
            buffer += text
        }
        
        return buffer.isEmpty ? nil : buffer
    }
    
    static func mkStringExtenso(section: FB2Section) -> String? {
        
        var buffer = ""
        
        if let title = section.title?.asString() {
            
            buffer += title
            buffer += "\n\n"
        }
        
        if let annotation = section.annotation?.asString() {
            
            buffer += annotation
            buffer += "\n\n"
        }
        
        for epigraph in section.epigraphs {
            
            if let text = epigraph.asString() {
                
                buffer += text
                buffer += "\n"
            }
        }
        
        return buffer.isEmpty ? nil : buffer
    }
    
    static func mkStringTitlePage(manifest: KyBookFmtManifest) -> String? {
        
        var buffer = ""
        
        if let title = manifest.title {
            
            buffer += title
            buffer += "\n\n"
        }
        
        if let authors = manifest.authors {
            
            for author in authors {
                
                buffer += author
                buffer += "\n"
            }
            
            buffer += "\n"
        }
        
        if let sequence = manifest.sequence {
            
            buffer += sequence
            if manifest.sequenceNo > 0 {
                buffer += " \(manifest.sequenceNo)"
            }
            buffer += "\n\n"
        }
        
        if let publisher = manifest.publisher {
            
            buffer += publisher
            if let date = manifest.date {
                buffer += " "
                buffer += date
            }
            buffer += "\n\n"
        }
        
        if let annotation = manifest.annotation {
            buffer += annotation
            buffer += "\n\n"
        }
        
        return buffer.isEmpty ? nil : buffer
    }
}
