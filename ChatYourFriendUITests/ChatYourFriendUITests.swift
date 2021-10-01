//
//  ChatYourFriendUITests.swift
//  ChatYourFriendUITests
//
//  Created by Юлия Караневская on 1.10.21.
//

import XCTest

class ChatYourFriendUITests: XCTestCase {

    override func setUpWithError() throws {

        continueAfterFailure = false
        
    }

    override func tearDownWithError() throws {
        
    }

    func testExample() throws {
        
        //1. Open the ChatYourFriend application
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()

        //2. Log In using an email & password
        app.textFields["Enter e-mail address"].tap()
        app.textFields["Enter e-mail address"].typeText("bob@gmail.com")

        app.secureTextFields["Enter your password"].tap()
        app.secureTextFields["Enter your password"].typeText("password")

        app.buttons["Log in"].tap()

        //3. Open My Chats tab
        app.tabBars["Tab Bar"].buttons["My Chats"].tap()
        
        //4. Choose first friend to chat with
        app.tables/*@START_MENU_TOKEN@*/.cells.staticTexts["Neil Rain"]/*[[".cells.staticTexts[\"Neil Rain\"]",".staticTexts[\"Neil Rain\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()

        //5. Write "Hello" message and send it
        app.textViews.containing(.staticText, identifier:"Aa").element.tap()
        app.textViews.containing(.staticText, identifier:"Aa").element.typeText("Hello")
        app.buttons["Send"].tap()
        
        //6.    Verify the last message is "Hello"
        XCTAssertTrue(app.textViews.staticTexts["Hello"].exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}



