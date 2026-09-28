import XCTest
@testable import Soundscape

final class MarbleAvatarTests: XCTestCase {
    func testRecipeIsStableAndNotLimitedToTheOldThirtyTwoSymbols() {
        XCTAssertEqual(MarbleAvatarRecipe(seed: "creator-42"), MarbleAvatarRecipe(seed: "creator-42"))
        let recipes = Set((0..<128).map { MarbleAvatarRecipe(seed: "creator-\($0)") })
        XCTAssertGreaterThan(recipes.count, 100)
    }

    func testGeometryAndPaletteStayInBoundedDesignSystem() {
        for index in 0..<200 {
            let recipe = MarbleAvatarRecipe(seed: "\(index)声音")
            XCTAssertTrue((0..<4).contains(recipe.palette))
            XCTAssertEqual(recipe.layers.count, 3)
            for layer in recipe.layers {
                XCTAssertTrue((0..<4).contains(layer.color))
                XCTAssertLessThanOrEqual(abs(layer.x), 8)
                XCTAssertLessThanOrEqual(abs(layer.y), 8)
                XCTAssertTrue((1.2...1.5).contains(layer.scale))
                XCTAssertLessThanOrEqual(abs(layer.rotation), 360)
            }
        }
    }
}
