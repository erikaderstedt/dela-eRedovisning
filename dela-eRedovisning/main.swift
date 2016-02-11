//
//  main.swift
//  dela-eRedovisning
//
//  Created by Erik Aderstedt on 2015-03-27.
//  Copyright (c) 2015 Aderstedt Software AB. All rights reserved.
//

import Foundation
import Quartz

func accountOnPage(page: PDFPage) -> String? {
    
    // Look for line with "Kontonr", and then get the next line that doesn't match "Utg".

    let s = page.string()
    let accountnumber : NSRegularExpression? = try? NSRegularExpression(pattern: "^[0-9 ]+-[0-9]+ (SEK|EUR)$", options: [])
    let lines = s.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    
    for line in lines {
        let m = accountnumber?.matchesInString(line, options: [], range: NSMakeRange(0, line.characters.count))
        if m?.count > 0 {
            return line
        }
    }
    
    return nil
}

func numberOnPage(page: PDFPage) -> String? {
    
    let s = page.string()
    let lines = s.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    let snumber : NSRegularExpression? = try? NSRegularExpression(pattern: "^Nummer ?([0-9]+)?", options: [])
    var getTheNextOne = false
    for line in lines {
        if getTheNextOne {
            return line
        }
        let m = snumber?.matchesInString(line, options: [], range: NSMakeRange(0, line.characters.count))
		if let r = m?.first {
            if r.rangeAtIndex(1).length > 0 {
                let q = line as NSString
                return (q.substringWithRange(r.rangeAtIndex(1)) as String)
            }
            getTheNextOne = true
        }
    }
    return nil
}

if Process.arguments.count < 2 {
    print("dela-eRedovisning <filnamn> ...")
    exit(1)
}

let c = Process.arguments.count
for argument in Process.arguments[1..<c] {
    if let inputDoc = PDFDocument(URL: NSURL(fileURLWithPath: argument)) {
        let pageCount = inputDoc.pageCount()
        var outputDoc : PDFDocument? = nil
        var currentAccount : String = ""
        var currentNumber : String = ""
        
        for i in 0..<pageCount {
            let page = inputDoc.pageAtIndex(i)
            // We need both account and number to change document.
            if let anum = accountOnPage(page) {
                if let dnum = numberOnPage(page) {
                    if anum != currentAccount || dnum != currentNumber {
                        if let odoc = outputDoc {
                            odoc.writeToFile("\(currentAccount) - \(currentNumber).pdf")
                            print("Writing \(currentAccount) - \(currentNumber).pdf")
                        }
                        outputDoc = PDFDocument()
                        currentAccount = anum
                        currentNumber = dnum
                    }
                }
            }
            if let odoc = outputDoc {
                odoc.insertPage(page, atIndex: odoc.pageCount())
            }
        }
        if let odoc = outputDoc {
            odoc.writeToFile("\(currentAccount) - \(currentNumber).pdf")
            print("Writing \(currentAccount) - \(currentNumber).pdf")
        }
    }
}