//
//  NativeBayes.swift
//  CLSwift
//
//  Created by modao on 2018/3/23.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

public class NaiveBayes {
    /// initialize our vocabulary
    private(set) var vocalbulary = Set<String>()
    /// number of documents we have learned from
    private(set) var totalDocuments = 0
    /// document frequency table for each of our categories
    private(set) var docCount = [String: Int]()
    /// for each category, how many words total were mapped to it
    private(set) var wordCount = [String: Int]()
    /// word frequency table for each category
    private(set) var wordFrequencyCount = [String: [String: Int]]()
    //hashmap of our category names
    private(set) var categories = Set<String>()

    var tokenizer: NSRegularExpression

    init(token: NSRegularExpression = .defaultTokenizer) {
        self.tokenizer = token
    }

    func learn(text: String, category: String)  {
        //update our count of how many documents mapped to this category
        if categories.contains(category), let value = docCount[category] {
            docCount[category] = value + 1
        } else {
            docCount[category] = 1
            wordFrequencyCount[category] = [String:Int]()
            categories.insert(category)
        }
        totalDocuments += 1
        // get a frequency count for each token in the text
        let frequencyTable = tokenizer.tokens(text).frequencyTable
        frequencyTable.forEach { (key, value) in
            vocalbulary.insert(key)
            if let frequency = wordFrequencyCount[category]?[key] {
                wordFrequencyCount[category]![key] = frequency + 1
            } else {
                wordFrequencyCount[category]![key] = 1
            }
            if let value = wordCount[category] {
                wordCount[category] = value + 1
            } else {
                wordCount[category] = 1
            }
        }
    }

    func categorize(text: String) -> String? {
        var maxProbability: Double = -.infinity
        var chosenCategory: String?
        let frequencyTable = tokenizer.tokens(text).frequencyTable
        categories.forEach { category in
            //start by calculating the overall probability of this category
            let categoryProbability = Double(docCount[category] ?? 0) / Double(totalDocuments)
            //take the log to avoid underflow
            var logProbability = log(categoryProbability)
            //now determine P( w | c ) for each word `w` in the text
            frequencyTable.forEach({ (token, frequencyInText) in
                let tokenProbability = self.tokenProbability(token: token, category: category)
                //determine the log of the P( w | c ) for this word
                logProbability += Double(frequencyInText)*log(tokenProbability)
            })
            if logProbability > maxProbability {
                maxProbability = logProbability
                chosenCategory = category
            }
        }
        return chosenCategory
    }

    func tokenProbability(token: String, category: String) -> Double {
        //how many times this word has occurred in documents mapped to this category
        let wordFrequencyCount: Int = self.wordFrequencyCount[category]?[token] ?? 0
        //what is the count of all words that have ever been mapped to this category
        let wordCount = self.wordCount[category] ?? 0
        //use laplace Add-1 Smoothing equation
        return Double(wordFrequencyCount + 1)/Double(wordCount + vocalbulary.count)
    }
}

extension NSRegularExpression {
    static var defaultTokenizer: NSRegularExpression {
        //remove punctuation from text - remove anything that isn't a word char or a space
        return try! NSRegularExpression(pattern: "[^(a-zA-ZA-Яa-я0-9_)+\\s]", options: .caseInsensitive)
    }

    func split(_ text: String) -> [String] {
        let matches = self.matches(in: text, range: NSMakeRange(0, text.count))
        return matches.map { (text as NSString).substring(with: $0.range) }
    }

    func tokens(_ text: String) -> [String] {
        let pure = self.stringByReplacingMatches(in: text, range: NSMakeRange(0, text.count), withTemplate: " ")
        return pure.components(separatedBy: " ")
    }
}

extension Collection where Element == String {
    var frequencyTable: [String: Int] {
        var table = [String: Int]()
        forEach { token in
            if let value = table[token] {
                table[token] = value + 1
            } else {
                table[token] = 1
            }
        }
        return table
    }
}
