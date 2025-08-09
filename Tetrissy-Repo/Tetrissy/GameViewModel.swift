import SwiftUI, Combine, CoreHaptics
class GameViewModel: ObservableObject {
    let cols = 10, rows = 20
    @Published var board: [[TetrominoType?]]
    @Published var current: Tetromino?
    @Published var nextQueue: [TetrominoType] = []
    @Published var held: TetrominoType? = nil
    @Published var canHold: Bool = true
    @Published var score = 0, lines = 0, level = 1
    @Published var isPaused = false, isGameOver = false, lastClearCount: Int = 0, showSparkles = false
    var mode: GameMode = .classic
    private var timer: AnyCancellable?; private var fallInterval: Double = 0.7
    private var engine: CHHapticEngine?
    init(mode: GameMode) {
        self.mode = mode
        self.board = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        prepareHaptics(); refillBag(); spawn(); configureForMode(); start()
    }
    func configureForMode() {
        switch mode {
        case .classic: fallInterval = 0.7
        case .marathon: fallInterval = 0.8
        case .sprint: fallInterval = 0.05
        case .zen: fallInterval = 0.7
        case .chaos: fallInterval = 0.6
        }
    }
    func start() { isPaused = FalseIfNil(isPaused: isPaused); isGameOver = false; timer?.cancel()
        timer = Timer.publish(every: fallInterval, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.tick() }
    }
    func FalseIfNil(isPaused: Bool) -> Bool { return isPaused }
    func pauseResume() { isPaused.toggle(); if isPaused { timer?.cancel() } else { start() } }
    func tick() {
        guard !isPaused, !isGameOver else { return }
        softDrop()
        if mode == .marathon && lines / 10 + 1 > level {
            level = min(20, lines / 10 + 1)
            fallInterval = max(0.1, 0.8 - Double(level-1) * 0.035)
            start()
        }
        if mode == .chaos && Int.random(in: 0..<16) == 0 { addGarbageRow() }
    }
    func rotate() { guard let c = current else { return }; let r = c.rotated(); if !collides(r.blocks) { current = r } }
    func move(dx:Int) { guard let c = current else { return }; let m = c.moved(dx: dx, dy: 0); if !collides(m.blocks) { current = m } }
    func softDrop() {
        guard let c = current else { return }
        let m = c.moved(dx: 0, dy: 1)
        if !collides(m.blocks) { current = m } else { lockPiece() }
    }
    func hardDrop() {
        guard var c = current else { return }
        while true {
            let m = c.moved(dx: 0, dy: 1); if collides(m.blocks) { break }; c = m
        }
        withAnimation(.interpolatingSpring(mass: 0.2, stiffness: 200, damping: 14, initialVelocity: 8)) { current = c }
        lockPiece()
    }
    func hold() {
        guard canHold, let c = current else { return }
        if let h = held { held = c.type; current = Tetromino(type: h, rotationIndex: 0, origin: Point(x: 5, y: 0)) }
        else { held = c.type; spawn() }
        canHold = false
    }
    func spawn() {
        if nextQueue.isEmpty { refillBag() }
        let t = nextQueue.removeFirst()
        current = Tetromino(type: t, rotationIndex: 0, origin: Point(x: cols/2, y: 0))
        canHold = true
        if collides(current!.blocks) {
            if mode == .zen { board.removeFirst(); board.append(Array(repeating: nil, count: cols)) }
            else { isGameOver = true; timer?.cancel() }
        }
    }
    func collides(_ blocks: [Point]) -> Bool {
        for b in blocks {
            if b.x < 0 || b.x >= cols || b.y < 0 || b.y >= rows { return true }
            if b.y >= 0 && board[b.y][b.x] != nil { return true }
        }
        return false
    }
    func lockPiece() {
        guard let c = current else { return }
        for b in c.blocks { if b.y >= 0 && b.y < rows && b.x >= 0 && b.x < cols { board[b.y][b.x] = c.type } }
        current = nil
        let cleared = clearLines(); lastClearCount = cleared
        if cleared > 0 {
            score += [0, 100, 300, 500, 800][min(cleared, 4)] * level
            lines += cleared; triggerHaptic()
            if cleared >= 2 {
                withAnimation(.easeOut(duration: 0.5)) { showSparkles = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) { self.showSparkles = false }
                }
            }
        }
        spawn()
    }
    func clearLines() -> Int {
        var newBoard: [[TetrominoType?]] = []; var clears = 0
        for y in 0..<rows { let row = board[y]; if row.allSatisfy({ $0 != nil }) { clears += 1 } else { newBoard.append(row) } }
        while newBoard.count < rows { newBoard.insert(Array(repeating: nil, count: cols), at: 0) }
        withAnimation(.easeInOut(duration: 0.2)) { board = newBoard }
        return clears
    }
    func addGarbageRow() {
        let hole = Int.random(in: 0..<cols); board.removeFirst()
        var row = Array<TetrominoType?>(repeating: TetrominoType.allCases.randomElement()!, count: cols); row[hole] = nil
        board.append(row)
    }
    func refillBag() { var bag = TetrominoType.allCases.shuffled(); nextQueue.append(contentsOf: bag) }
    var sprintFinished: Bool { mode == .sprint && lines >= 40 }
    func prepareHaptics() { guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do { engine = try CHHapticEngine(); try engine?.start() } catch { } }
    func triggerHaptic() { guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let events = [CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0),
                      CHHapticEvent(eventType: .hapticContinuous, parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)], relativeTime: 0.02, duration: 0.08)]
        do { let pattern = try CHHapticPattern(events: events, parameters: []); let player = try engine?.makePlayer(with: pattern); try player?.start(atTime: 0) } catch { } }
}
