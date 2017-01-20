//
//  main.swift
//  dela-eRedovisning
//
//  Created by Erik Aderstedt on 2015-03-27.
//  Copyright (c) 2015 Aderstedt Software AB. All rights reserved.
//

import Foundation
import Quartz

// Get Safari to download PDFs:
// defaults write com.apple.Safari WebKitOmitPDFSupport -bool YES

func accountOnPage(_ page: PDFPage) -> String? {
    
    // Look for line with "Kontonr", and then get the next line that doesn't match "Utg".

    let s = page.string
    let accountnumber : NSRegularExpression? = try? NSRegularExpression(pattern: "^[0-9 ]+-[0-9]+ (SEK|EUR)$", options: [])
    let lines = s?.components(separatedBy: CharacterSet.newlines)
    
    for line in lines! {
        if let m = accountnumber?.matches(in: line, options: [], range: NSMakeRange(0, line.characters.count)), m.count > 0 {
            return line
        }
    }
    
    return nil
}

func numberOnPage(_ page: PDFPage) -> String? {
    
    let s = page.string
    let lines = s?.components(separatedBy: CharacterSet.newlines)
    let snumber : NSRegularExpression? = try? NSRegularExpression(pattern: "^Nummer ?([0-9]+)?", options: [])
    var getTheNextOne = false
    for line in lines! {
        if getTheNextOne {
            return line
        }
        let m = snumber?.matches(in: line, options: [], range: NSMakeRange(0, line.characters.count))
		if let r = m?.first {
            if r.rangeAt(1).length > 0 {
                let q = line as NSString
                return (q.substring(with: r.rangeAt(1)) as String)
            }
            getTheNextOne = true
        }
    }
    return nil
}

if CommandLine.arguments.count < 2 {
    print("dela-eRedovisning <filnamn> ...")
    exit(1)
}

let c = CommandLine.arguments.count
for argument in CommandLine.arguments[1..<c] {
    if let inputDoc = PDFDocument(url: URL(fileURLWithPath: argument)) {
        let pageCount = inputDoc.pageCount
        var outputDoc : PDFDocument? = nil
        var currentAccount : String = ""
        var currentNumber : String = ""
        
        for i in 0..<pageCount {
            let page = inputDoc.page(at: i)
            // We need both account and number to change document.
            if let anum = accountOnPage(page!) {
                if let dnum = numberOnPage(page!) {
                    if anum != currentAccount || dnum != currentNumber {
                        if let odoc = outputDoc {
                            odoc.write(toFile: "\(currentAccount) - \(currentNumber).pdf")
                            print("Writing \(currentAccount) - \(currentNumber).pdf")
                        }
                        outputDoc = PDFDocument()
                        currentAccount = anum
                        currentNumber = dnum
                    }
                }
            }
            if let odoc = outputDoc {
                odoc.insert(page!, at: odoc.pageCount)
            }
        }
        if let odoc = outputDoc {
            odoc.write(toFile: "\(currentAccount) - \(currentNumber).pdf")
            print("Writing \(currentAccount) - \(currentNumber).pdf")
        }
    }
}
