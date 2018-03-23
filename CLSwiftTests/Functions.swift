//
//  Functions.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/23.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import XCTest
@testable import CLSwift

class Functions: XCTestCase {

    func testNaiveBayes() {
        let classifier = NaiveBayes()
        //teach it positive phrases
        classifier.learn(text: "amazing, awesome movie!! Yeah!!", category: "positive")
        classifier.learn(text: "Sweet, this is incredibly, amazing, perfect, great!!", category: "positive")
        //teach it a negative phrase
        classifier.learn(text: "terrible, shitty thing. Damn. Sucks!!", category: "negative")
        classifier.learn(text: "I dont really know what to make of this.", category: "neutral")
        //now test it to see that it correctly categorizes a new document
        XCTAssert(classifier.categorize(text: "awesome, cool, amazing!! Yay.") == "positive")
    }

    func testLanguage() {
        let classifier = NaiveBayes()
        classifier.learn(text: "Chinese Beijing Chinese", category: "chinese")
        classifier.learn(text: "Chinese Chinese Shanghai", category: "chinese")
        classifier.learn(text: "Chinese Macao", category: "chinese")
        classifier.learn(text: "Tokyo Japan Chinese", category: "japanese")

        XCTAssert(classifier.categorize(text: "Chinese Chinese Chinese Tokyo Japan") == "chinese")
    }

    func testCyrlic() {
        let classifier = NaiveBayes()
        classifier.learn(text: "Надежда за", category: "a")
        classifier.learn(text: "Надежда за обич еп.36 Тест", category: "b")
        classifier.learn(text: "Надежда за обич еп.36 Тест", category: "b")

        let aFreqCount = classifier.wordFrequencyCount["a"]
        XCTAssert(aFreqCount?["Надежда"] == 1)
        XCTAssert(aFreqCount?["за"] == 1)

        let  bFreqCount = classifier.wordFrequencyCount["b"]
        XCTAssert(bFreqCount?["Надежда"] == 2)
        XCTAssert(bFreqCount?["за"] == 2)
        XCTAssert(bFreqCount?["обич"] == 2)
        XCTAssert(bFreqCount?["еп"] == 2)
        XCTAssert(bFreqCount?["36"] == 2)
        XCTAssert(bFreqCount?["Тест"] == 2)
    }
}
