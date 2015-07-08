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
    let accountnumber : NSRegularExpression? = NSRegularExpression(pattern: "^[0-9 ]+-[0-9]+ (SEK|EUR)$", options: nil, error: nil)
    let lines = s.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    
    for line in lines {
        let m = accountnumber?.matchesInString(line, options: nil, range: NSMakeRange(0, count(line)))
        if m?.count > 0 {
            return line
        }
    }
    
    return nil
}

func numberOnPage(page: PDFPage) -> String? {
    
    let s = page.string()
    let lines = s.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    let snumber : NSRegularExpression? = NSRegularExpression(pattern: "^Nummer ?([0-9]+)?", options: nil, error: nil)
    var getTheNextOne = false
    for line in lines {
        if getTheNextOne {
            return line
        }
        let m = snumber?.matchesInString(line, options: nil, range: NSMakeRange(0, count(line)))
        if let r : NSTextCheckingResult = m?.first as? NSTextCheckingResult {
            if r.rangeAtIndex(1).length > 0 {
                let q = line as NSString
                return (q.substringWithRange(r.rangeAtIndex(1)) as String)
            }
            getTheNextOne = true
        }
    }
    return nil
}

if count(Process.arguments) < 2 {
    println("dela-eRedovisning <filnamn> ...")
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
                            println("Writing \(currentAccount) - \(currentNumber).pdf")
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
            println("Writing \(currentAccount) - \(currentNumber).pdf")
        }
    }
}