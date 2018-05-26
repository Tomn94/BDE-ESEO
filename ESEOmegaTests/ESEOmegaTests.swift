//
//  APITests.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 26/05/2018.
//  Copyright © 2018 Thomas Naudet

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
//

import XCTest

class ESEOmegaTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAPIUserLogin() {
        
        let expectation = XCTestExpectation(description: "Try to connect to Portail BDE (with wrong credentials)")
        
        /* Feel free to add a test with correct credentials,
           but create a mock account for this purpose, otherwise you'll have to write your password below */
        API.request(.userLogin, get: ["email"    : "thomas.naudet@reseau.eseo.fr",
                                      "password" : "clubCheval"],
                    completed: { data in
                        
                        // Check we have data
                        do {
                            let _/*result*/ = try JSONDecoder().decode(LoginResult.self, from: data)
                            // Test this and other fields XCTAssertTrue(result.success)
                        } catch {
                            // Check it was the wrong password
                            let error = API.handleFailure(data: data)
                            XCTAssertEqual(error.code, LoginResult.wrongPasswordErrorCode,
                                           "Error number should be wrong password one")
                        }
                        
                        expectation.fulfill()
                        
        }, failure: { error, data in
            XCTFail("Unable to connect to API: \n\terror:\n"
                    + (error?.localizedDescription ?? "?")
                    + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 20) // Outlook may take some time to validate account
    }
    
    func testAPINews() {
        
    }
    
    func testAPIOrders() {
        
    }
    
    func testAPIIngenews() {
        
    }
    
    func testAPIRooms() {
        
    }
    
    func testAPIFamily() {
        
    }
    
    func testAPIStickers() {
        
        let expectation = XCTestExpectation(description: "Try to get iMessage stickers")
        
        API.request(.stickers, completed: { data in
            
            do {
                let result = try JSONDecoder().decode(StickersResult.self, from: data)
                XCTAssertTrue(result.success)
                XCTAssertGreaterThan(result.stickers.count, 0)
                
                for sticker in result.stickers {
                    XCTAssertGreaterThanOrEqual(sticker.id, 0)
                    XCTAssertNotEqual(sticker.name, "")
                    XCTAssertNotEqual(sticker.img.absoluteString, "")
                    
                    let data = try? Data(contentsOf: sticker.img) // Data(contentsOf: url) is blocking
                    XCTAssert(data != nil)
                }
                
            } catch {
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            expectation.fulfill()

        }, failure: { error, data in
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 20) // Multiple stickers to fetch
    }
    
}
