#if canImport(XCTest)
import XCTest
@testable import projectDAM

final class ValidatorsTests: XCTestCase {

    func testValidateEmail() {
        // Valid emails
        XCTAssertTrue(Validators.isValidEmail("student@esprit.tn"), "esprit.tn domain should be valid")
        XCTAssertTrue(Validators.isValidEmail("teacher@esprim.tn"), "esprim.tn domain should be valid")
        
        // Invalid emails
        XCTAssertFalse(Validators.isValidEmail("invalid-email"), "Plain text should be invalid")
        XCTAssertFalse(Validators.isValidEmail("user@gmail.com"), "gmail.com should be invalid (restricted domains)")
        XCTAssertFalse(Validators.isValidEmail(""), "Empty email should be invalid")
        
        // Detailed error check
        if case .invalid(let msg) = Validators.validateEmail("") {
            XCTAssertEqual(msg, "Email is required")
        } else {
            XCTFail("Empty email should return invalid result")
        }
    }
    
    func testValidatePassword() {
        // Valid password (min 8 chars, 1 number, 1 letter)
        XCTAssertTrue(Validators.isValidPassword("SecurePass123"), "Password meeting all criteria should be valid")
        
        // Invalid passwords
        XCTAssertFalse(Validators.isValidPassword("short"), "Short password should be invalid")
        XCTAssertFalse(Validators.isValidPassword("NoNumbers"), "Password without numbers should be invalid")
        XCTAssertFalse(Validators.isValidPassword("12345678"), "Password without letters should be invalid")
        
        // Detailed error check
        if case .invalid(let msg) = Validators.validatePassword("short") {
            XCTAssertTrue(msg.contains("at least 8 characters"))
        }
    }
    
    func testValidateUsername() {
        XCTAssertTrue(Validators.isValidUsername("valid_user_1"), "Alphanumeric with underscore should be valid")
        XCTAssertFalse(Validators.isValidUsername("invalid user"), "Spaces should not be allowed")
        XCTAssertFalse(Validators.isValidUsername("user@name"), "Special characters should not be allowed")
        XCTAssertFalse(Validators.isValidUsername(""), "Empty username should be invalid")
    }
    
    func testValidateName() {
        XCTAssertTrue(Validators.isValidName("John Doe"), "Alphabetic name with spaces should be valid")
        XCTAssertFalse(Validators.isValidName("John123"), "Numbers in name should be invalid")
        XCTAssertFalse(Validators.isValidName(""), "Empty name should be invalid")
    }
}
#endif
