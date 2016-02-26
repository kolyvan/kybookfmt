//
//  fb2utils.swift
//  https://github.com/kolyvan/kybookfmt
//
//  Created by Konstantin Bukreev on 09.02.16.
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

struct FB2Utils {

    static let whitespacesCharacterSet : NSCharacterSet = {
        
        let charset = NSMutableCharacterSet.whitespaceAndNewlineCharacterSet()
        charset.removeCharactersInRange(NSRange(location:0xa0, length:1)) // No-Break Space
        return charset.copy() as! NSCharacterSet
    }()
    
    static func trimWhitespaces(text: String) -> String {
        
        if text.isEmpty {
            return text
        }
        
        let newlines = NSCharacterSet.newlineCharacterSet()
        let whites = self.whitespacesCharacterSet
                
        var needTrim = false
        
        let scanner = NSScanner(string: text)
        scanner.charactersToBeSkipped = nil
        
        scanner.scanUpToCharactersFromSet(newlines, intoString:nil)
        if scanner.scanCharactersFromSet(newlines, intoString:nil) {
            
            needTrim = true;
            
        } else {
            
            scanner.scanLocation = 0
            var scanLocation = 0
            
            while !scanner.atEnd {
                
                if scanner.scanCharactersFromSet(whites, intoString:nil) {
                    
                    if (scanner.scanLocation - scanLocation) > 1 {
                        needTrim = true
                        break
                    }
                }
                
                if scanner.scanUpToCharactersFromSet(whites, intoString:nil) {
                    scanLocation = scanner.scanLocation
                }
            }
        }
        
        if !needTrim {
            return text;
        }

        var buffer = ""
        
        scanner.scanLocation = 0
        while !scanner.atEnd {
            
            if scanner.scanCharactersFromSet(whites, intoString:nil) {
                buffer += " "
            }
            if let s = scanner.scanUpToCharactersFromSet(whites) {
                buffer += s
            }
        }

        return buffer
    }
}
