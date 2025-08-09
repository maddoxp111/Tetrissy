import SwiftUI
struct Point: Hashable { var x: Int; var y: Int }
enum TetrominoType: CaseIterable {
    case I, O, T, S, Z, J, L
    var color: Color {
        switch self {
        case .I: return .cyan
        case .O: return .yellow
        case .T: return .purple
        case .S: return .green
        case .Z: return .red
        case .J: return .blue
        case .L: return .orange
        }
    }
    var rotations: [[Point]] {
        switch self {
        case .I:
            return [
                [Point(x: -2,y:0), Point(x:-1,y:0), Point(x:0,y:0), Point(x:1,y:0)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:0,y:1), Point(x:0,y:2)],
                [Point(x:-2,y:1), Point(x:-1,y:1), Point(x:0,y:1), Point(x:1,y:1)],
                [Point(x:-1,y:-1), Point(x:-1,y:0), Point(x:-1,y:1), Point(x:-1,y:2)]
            ]
        case .O:
            return [[Point(x:0,y:0), Point(x:1,y:0), Point(x:0,y:1), Point(x:1,y:1)]].repeatElement(count:4)
        case .T:
            return [
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:1,y:0), Point(x:0,y:1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:0,y:1), Point(x:1,y:0)],
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:1,y:0), Point(x:0,y:-1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:0,y:1), Point(x:-1,y:0)]
            ]
        case .S:
            return [
                [Point(x:0,y:0), Point(x:1,y:0), Point(x:-1,y:1), Point(x:0,y:1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:1,y:0), Point(x:1,y:1)],
                [Point(x:0,y:0), Point(x:1,y:0), Point(x:-1,y:1), Point(x:0,y:1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:1,y:0), Point(x:1,y:1)]
            ]
        case .Z:
            return [
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:0,y:1), Point(x:1,y:1)],
                [Point(x:1,y:-1), Point(x:0,y:0), Point(x:1,y:0), Point(x:0,y:1)],
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:0,y:1), Point(x:1,y:1)],
                [Point(x:1,y:-1), Point(x:0,y:0), Point(x:1,y:0), Point(x:0,y:1)]
            ]
        case .J:
            return [
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:1,y:0), Point(x:-1,y:1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:0,y:1), Point(x:1,y:-1)],
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:1,y:0), Point(x:1,y:-1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:0,y:1), Point(x:-1,y:1)]
            ]
        case .L:
            return [
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:1,y:0), Point(x:1,y:1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:0,y:1), Point(x:1,y:1)],
                [Point(x:-1,y:0), Point(x:0,y:0), Point(x:1,y:0), Point(x:-1,y:-1)],
                [Point(x:0,y:-1), Point(x:0,y:0), Point(x:0,y:1), Point(x:-1,y:-1)]
            ]
        }
    }
}
extension Array {
    fileprivate static func repeatElement<T>(count: Int, builder: () -> T) -> [T] { (0..<count).map { _ in builder() } }
}
struct Tetromino {
    var type: TetrominoType
    var rotationIndex: Int = 0
    var origin: Point = Point(x: 5, y: 0)
    var blocks: [Point] { type.rotations[rotationIndex % 4].map { Point(x: $0.x + origin.x, y: $0.y + origin.y) } }
    func rotated() -> Tetromino { var t = self; t.rotationIndex = (t.rotationIndex + 1) % 4; return t }
    func moved(dx: Int, dy: Int) -> Tetromino { var t = self; t.origin = Point(x: origin.x + dx, y: origin.y + dy); return t }
}
enum GameMode: String, CaseIterable, Identifiable {
    case classic = "Classic", marathon = "Marathon", sprint = "Sprint 40", zen = "Zen", chaos = "Chaos"
    var id: String { rawValue }
}
