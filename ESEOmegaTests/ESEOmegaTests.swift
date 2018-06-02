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
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                    + (error?.localizedDescription ?? "?")
                    + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 20) // Outlook may take some time to validate account
    }
    
    func testAPINews() {
        
        let expectation = XCTestExpectation(description: "Try to get news article list")
        
        API.request(.news, get: ["maxInPage" : "10"],
                    completed: { data in
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = NewsArticle.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            do {
                let result = try decoder.decode(NewsResult.self, from: data)
                XCTAssertTrue(result.success)
                XCTAssertEqual(result.page, 1)
                XCTAssertEqual(result.news.count, 10)
                
                result.news.forEach { article in
                    XCTAssertNotEqual(article.title, "")
                    XCTAssertNotEqual(article.preview, "")
                }
                
            } catch {
                print(error)
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            expectation.fulfill()
            
        }, failure: { error, data in
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testAPIEvents() {
        // TODO
    }
    
    func testAPIClubs() {
        
        let expectation = XCTestExpectation(description: "Try to get clubs list")
        
        API.request(.clubs, get: ["maxInPage" : String(1000), "display" : String(1)],
                    completed: { data in
            
            do {
                let result = try JSONDecoder().decode(ClubsResult.self, from: data)
                XCTAssertTrue(result.success)
                XCTAssertGreaterThan(result.clubs.count, 1)
                
                result.clubs.forEach { club in
                    XCTAssertNotEqual(club.name, "")
                    XCTAssertNotEqual(club.subtitle, "")
                    XCTAssertNotEqual(club.description, "")
                    XCTAssertNotEqual(club.contacts, "")
                    
                    XCTAssertGreaterThanOrEqual(club.users.count, 0)
                    club.users.forEach { user in
                        XCTAssertNotEqual(user.user, "")
                        XCTAssertNotEqual(user.fullname, "")
                        XCTAssertNotEqual(user.role, "")
                    }
                }
                
            } catch {
                print(error)
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            expectation.fulfill()
            
        }, failure: { error, data in
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testAPISponsors() {
        // TODO
    }
    
    func testAPIOrders() {
        // TODO
        // TODO test images exist under "imgUrl" key
    }
    
    func testAppStoreVersion() {
        // TODO
    }
    
    func testLydia() {
        // TODO
    }
    
    func testAPIIngenews() {
        
        let expectation = XCTestExpectation(description: "Try to get document list")
        
        API.request(.ingenews, completed: { data in
                        
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = IngeNews.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            do {
                let result = try decoder.decode(IngeNewsResult.self, from: data)
                XCTAssertTrue(result.success)
                XCTAssertGreaterThan(result.files.count, 0)
                
                result.files.forEach { file in
                    XCTAssertNotEqual(file.name, "")
                    XCTAssertNotEqual(file.url.absoluteString, "")
                    XCTAssert(file.preview != nil)
                    XCTAssertNotEqual(file.preview!.absoluteString, "")
                }
                
                let imgData  = try? Data(contentsOf: result.files.first!.url)  // Data(contentsOf: url) is blocking
                let fileData = try? Data(contentsOf: result.files.first!.preview!)
                XCTAssert(imgData != nil)
                XCTAssert(fileData != nil)
                
            } catch {
                print(error)
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            expectation.fulfill()
                        
        }, failure: { error, data in
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 20)  // files and images to download
    }
    
    func testAPIRooms() {
        
        let expectation = XCTestExpectation(description: "Try to get room list")
        
        API.request(.rooms, completed: { data in
            
            do {
                let result = try JSONDecoder().decode(RoomsResult.self, from: data)
                XCTAssertTrue(result.success)
                XCTAssertGreaterThan(result.rooms.count, 1)
                
                result.rooms.forEach { room in
                    XCTAssertNotEqual(room.name, "")
                    XCTAssertNotEqual(room.building, "")
                    XCTAssertGreaterThan(room.floor, -5)
                    XCTAssertLessThan(room.floor, 10)
                }
                
            } catch {
                print(error)
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            expectation.fulfill()
            
        }, failure: { error, data in
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testAPIFamily() {
        
        let userExpectation   = XCTestExpectation(description: "Try to get a student search result")
        let familyExpectation = XCTestExpectation(description: "Try to get a family")
        
        let alex       = "Alexandre JULIEN"
        let alexFamily = 23
        API.request(.familySearch, get: ["name" : alex], completed: { data in
            
            do {
                let result = try JSONDecoder().decode(StudentSearchResult.self, from: data)
                XCTAssertTrue(result.success)
                XCTAssertEqual(result.users.count, 1)
                XCTAssertEqual(result.users.first!.familyID, alexFamily)
                XCTAssertNotEqual(result.users.first!.fullname, "")
                XCTAssertNotEqual(result.users.first!.promo, "")
                XCTAssertGreaterThanOrEqual(result.users.first!.rank, 0)
                
            } catch {
                print(error)
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            userExpectation.fulfill()
            
        }, failure: { error, data in
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            userExpectation.fulfill()
        }, noCache: true)
        
        API.request(.family, appendPath: String(alexFamily), completed: { data in
            
            do {
                let result = try JSONDecoder().decode(FamilyResult.self,from: data)
                XCTAssertTrue(result.success)
                XCTAssertGreaterThan(result.familyMembers.count, 1)
                XCTAssertTrue(result.familyMembers.contains { familyMember in
                    familyMember.fullname == String(alex)
                })
                
                result.familyMembers.forEach { familyMember in
                    XCTAssertEqual(familyMember.familyID, alexFamily)
                    XCTAssertNotEqual(familyMember.fullname, "")
                    XCTAssertNotEqual(familyMember.promo, "")
                    XCTAssertGreaterThanOrEqual(familyMember.rank, 0)
                    if (familyMember.fullname == alex) {
                        XCTAssert(familyMember.childIDs != nil)
                        XCTAssertGreaterThanOrEqual(familyMember.childIDs!.count, 2)
                    }
                }
                
            } catch {
                print(error)
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            familyExpectation.fulfill()
            
        }, failure: { error, data in
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            familyExpectation.fulfill()
        }, noCache: true)
        
        wait(for: [userExpectation, familyExpectation], timeout: 10)
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
                print(error)
                XCTFail("Unable to decode result:\n" + error.localizedDescription)
            }
            expectation.fulfill()

        }, failure: { error, data in
            print(error)
            XCTFail("Unable to connect to API: \n\terror:\n"
                + (error?.localizedDescription ?? "?")
                + "\n\tdata:\n" + (data == nil ? "?" : (String(data: data!, encoding: .utf8) ?? "?")))
            expectation.fulfill()
        }, noCache: true)
        
        wait(for: [expectation], timeout: 20) // Multiple stickers to fetch
    }
    
    func testPushSubscribe() {
        // TODO
    }
    
    func testPushUnsubscribe() {
        // TODO
    }
    
    func testAppAvailability() {
        // TODO
    }
    
}
