/**
 * The MIT License (MIT)
 *
 * Copyright (C) 2016 Yahoo Japan Corporation.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import XCTest
@testable import SwiftyXMLParser


class ParserTests: XCTestCase {
    fileprivate let packageRootPath = URL(fileURLWithPath: #file)
        .pathComponents
        .dropLast()
        .joined(separator: "/")
        .dropFirst()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    private func getPath(_ name: String) -> String {
        "\(packageRootPath)/\(name)"
    }
    
    func testSuccessParse() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("XMLDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }
        
        let xml = XML.Parser().parse(data)
        if  let _ = xml["ResultSet"].error {
            XCTFail("fail to parse")
        } else {
            XCTAssert(true, "success to parse")
        }


    }
    
    func testFailParse() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("BrokenXMLDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }
        
        let xml = XML.Parser().parse(data)
        if case .failure(XMLError.interruptedParseError) = xml {
            XCTAssert(true, "Parsed Failure because of the invalid character")
        } else {
            XCTAssert(false, "fail")
        }
    }
    
    func testTextParseWithMockData() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("SimpleDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }
        
        let xml = XML.Parser().parse(data)
        if let text = xml["Result", "Text"].text {
            XCTAssertEqual("Text", text, "Parsed Text")
        } else {
            XCTAssert(true, "fail to parse")
        }
    }
    
    func testWhitespaceParseWithMockData() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("SimpleDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }
            
        let xml = XML.Parser().parse(data)
        if let text = xml["Result", "Whitespace"].text {
            XCTAssertEqual(" ", text, "Parsed Single-Bite Whitespace")
        } else {
            XCTFail("fail")
        }
    }
    
    func testReturnParseWithMockData() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("SimpleDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }
        
        let xml = XML.Parser().parse(data)
        if let text = xml["Result", "OnlyReturn"].text {
            XCTAssertEqual("\n", text, "Parsed line break code")
        } else {
            XCTAssert(false, "need to have no line break code")
        }
    }
    
    func testWhitespaceAndReturnParseWithMockData() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("SimpleDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }
        
        let xml = XML.Parser().parse(data)
        if let text = xml["Result", "WhitespaceReturn"].text {
            XCTAssertEqual("\n    \n", text, "Parsed whitespace and line break code")
        } else {
            XCTAssert(false, "need to have no line break code")

        }
    }
    
    func testWhitespaceAndReturnParseWithMockDataAndTrimmingWhitespaceAndLineBreak() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("SimpleDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }

        let xml = XML.Parser(trimming: .whitespacesAndNewlines).parse(data)
        if let text = xml["Result", "WhitespaceReturn"].text {
            XCTAssertEqual("", text, "Parsed Success and trim them")
        } else {
            XCTAssert(false, "fail")
        }
    }

    func testIgnoreNamespaces() {
        let data = """
            <?xml version="1.0" encoding="UTF-8"?>
            <env:RootElement key="value">
                <ns1:ChildElement>childText1</ns1:ChildElement>
                <ns2:ChildElement>childText2</ns2:ChildElement>
            </env:RootElement>
        """.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)!

        let xml = XML.Parser().parse(data)
        XCTAssertEqual(xml["env:RootElement", "ns1:ChildElement"].text, "childText1", "can access element when including namespace")
        XCTAssertEqual(xml["RootElement", "ChildElement"].first.text, nil, "cannot find elements with namespaces")

        let xmlIgnoreNamespaces = XML.Parser(ignoreNamespaces: true).parse(data)
        XCTAssertEqual(xmlIgnoreNamespaces["RootElement", "ChildElement"].first.text, "childText1", "can find element when ignoring namespaces")
        XCTAssertEqual(xmlIgnoreNamespaces["RootElement", "ChildElement"].last.text, "childText2", "can find element when ignoring namespaces")
    }
    
    func testParseErrorToInvalidCharacter() {
        let str = "<xmlopening>@ß123\u{1c}</xmlopening>"
        let xml = XML.Parser().parse(str.data(using: .utf8)!)
        
        if case .failure(XMLError.interruptedParseError) = xml {
            XCTAssert(true, "Parsed Failure because of the invalid character")
        } else {
            XCTAssert(false, "fail")
        }
    }
    
    func testNotParseErrorToInvalidCharacter() {
        let str = "<xmlopening>@ß123\u{1c}</xmlopening>".addingPercentEncoding(withAllowedCharacters: CharacterSet.controlCharacters.inverted)!
        let xml = XML.Parser().parse(str.data(using: .utf8)!)
        XCTAssertEqual("@ß123\u{1c}", xml["xmlopening"].text?.removingPercentEncoding, "Parsed Success and trim them")
    }

    func testLineNumbers() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: getPath("SimpleDocument.xml"))) else {
            XCTFail("fail to parse")
            return
        }

        let xml = XML.Parser().parse(data)
        guard let whitespaceReturnElement = xml["Result"]["WhitespaceReturn"].element else {
            XCTFail("Element not found")
            return
        }
        XCTAssertEqual(whitespaceReturnElement.lineNumberStart, 4)
        XCTAssertEqual(whitespaceReturnElement.lineNumberEnd, 6)
    }
}
