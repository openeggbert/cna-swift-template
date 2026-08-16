import CNA
import Foundation

let smokeTest = CommandLine.arguments.contains("--smoke-test")
let game = HelloGame(smokeTest: smokeTest)

do {
    try Run(game: game)
} catch {
    print("Error: \(error)")
    exit(1)
}
