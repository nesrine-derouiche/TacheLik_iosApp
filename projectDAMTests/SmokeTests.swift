import XCTest
import UIKit
@testable import projectDAM

final class SmokeTests: XCTestCase {
    func testDynamicColorsResolve() {
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

        let lightGlass = UIColor.appNavBarGlassBackground.resolvedColor(with: lightTraits)
        let darkGlass = UIColor.appNavBarGlassBackground.resolvedColor(with: darkTraits)

        XCTAssertGreaterThan(lightGlass.cgColor.alpha, 0.0)
        XCTAssertGreaterThan(darkGlass.cgColor.alpha, 0.0)

        let reels = UIColor.reelsBackground
        XCTAssertEqual(reels.cgColor.alpha, 1.0)
    }
}
