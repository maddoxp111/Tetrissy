import SwiftUI
struct ModeSelectView: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradient(phase: $phase).ignoresSafeArea()
                VStack(spacing: 18) {
                    Text("TETRISSY").font(.system(size: 48, weight: .heavy, design: .rounded)).tracking(4).shadow(radius: 8)
                    ForEach(GameMode.allCases) { mode in
                        NavigationLink(mode.rawValue) { GameView(mode: mode) }
                            .buttonStyle(.borderedProminent).font(.title3.bold())
                    }.padding(.top, 10)
                    Text("Made for you by ChatGPT").font(.footnote).opacity(0.6).padding(.top, 30)
                }.padding()
            }.onAppear { withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { phase = 1 } }
        }
    }
}
struct GameView: View {
    @StateObject var vm: GameViewModel
    init(mode: GameMode) { _vm = StateObject(wrappedValue: GameViewModel(mode: mode)) }
    var body: some View {
        ZStack {
            AnimatedGradient(phase: .constant(0.5)).ignoresSafeArea()
            VStack { topBar; boardView; controls }.padding()
            if vm.showSparkles { SparklesView().transition(.opacity).allowsHitTesting(false) }
        }.navigationBarBackButtonHidden(true)
    }
    var topBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Score: \(vm.score)"); Text("Lines: \(vm.lines)")
                if vm.mode == .marathon { Text("Level: \(vm.level)") }
                if vm.mode == .sprint { Text("Target: 40") }
            }
            Spacer()
            Button(vm.isPaused ? "Resume" : "Pause") { vm.pauseResume() }.buttonStyle(.bordered)
        }.font(.headline)
    }
    var boardView: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height * 0.6)
            let cell = w / CGFloat(vm.cols)
            let boardHeight = cell * CGFloat(vm.rows)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.25))
                ForEach(0..<vm.rows, id: \.self) { y in
                    ForEach(0..<vm.cols, id: \.self) { x in
                        if let t = vm.board[y][x] {
                            BlockView(color: t.color).frame(width: cell-2, height: cell-2)
                                .position(x: CGFloat(x)*cell + cell/2, y: CGFloat(y)*cell + cell/2)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                if let c = vm.current {
                    ForEach(c.blocks, id: \.self) { p in
                        BlockView(color: c.type.color.opacity(0.95)).frame(width: cell-2, height: cell-2)
                            .position(x: CGFloat(p.x)*cell + cell/2, y: CGFloat(p.y)*cell + cell/2)
                            .shadow(radius: 3).animation(.spring(response: 0.25, dampingFraction: 0.8), value: c.origin.y)
                    }
                }
            }.frame(width: w, height: boardHeight)
            .overlay(
                VStack(alignment: .leading) {
                    HStack { Text("Next:"); HStack { ForEach(vm.nextQueue.prefix(3), id: \.self) { MiniPreview(type: $0) } } }
                    if let held = vm.held { HStack { Text("Hold:"); MiniPreview(type: held) } } else { Text("Hold: —") }
                }.padding(8).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8)).padding(), alignment: .topTrailing
            )
        }.frame(height: 480)
        .overlay(alignment: .center) {
            if vm.isGameOver || vm.sprintFinished {
                VStack(spacing: 12) {
                    Text(vm.sprintFinished ? "Sprint Complete!" : "Game Over").font(.largeTitle.bold())
                    Text("Score: \(vm.score)  •  Lines: \(vm.lines)")
                    Button("Play Again") {
                        let mode = vm.mode; let newVM = GameViewModel(mode: mode); _ = withAnimation { () }
                        vm.board = newVM.board; vm.current = newVM.current; vm.nextQueue = newVM.nextQueue
                        vm.held = nil; vm.canHold = true; vm.score = 0; vm.lines = 0; vm.level = 1
                        vm.isPaused = false; vm.isGameOver = false; vm.configureForMode(); vm.start()
                    }.buttonStyle(.borderedProminent)
                }.padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    var controls: some View {
        HStack(spacing: 18) {
            Button("◀︎") { vm.move(dx: -1) }.buttonStyle(.borderedProminent)
            Button("▶︎") { vm.move(dx: 1) }.buttonStyle(.borderedProminent)
            Button("⟳") { vm.rotate() }.buttonStyle(.bordered)
            Button("▼") { vm.softDrop() }.buttonStyle(.borderedProminent)
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in vm.hardDrop() })
            Button("HOLD") { vm.hold() }.buttonStyle(.bordered)
        }.font(.title2.bold()).padding(.top, 12)
    }
}
struct BlockView: View {
    var color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(LinearGradient(colors: [color.opacity(0.95), color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}
struct MiniPreview: View {
    var type: TetrominoType
    var body: some View {
        ZStack { RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.25)); Text(String(describing: type).prefix(1)).font(.headline.bold()) }
            .frame(width: 32, height: 32)
    }
}
struct AnimatedGradient: View {
    @Binding var phase: CGFloat
    var body: some View { AngularGradient(gradient: Gradient(colors: [.pink, .purple, .blue, .cyan, .mint, .pink]), center: .center, angle: .degrees(Double(phase)*360)) }
}
struct SparklesView: View {
    @State private var t: CGFloat = 0; let emojis = ["✨","🔥","💥","⚡️","⭐️"]
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<30, id: \.self) { _ in
                let x = CGFloat.random(in: 0...geo.size.width); let y = CGFloat.random(in: 0...geo.size.height * 0.7)
                Text(emojis.randomElement()!).position(x: x, y: y - t * 60).opacity(1 - Double(t)).scaleEffect(1 + t * 0.5)
            }.onAppear { withAnimation(.easeOut(duration: 0.8)) { t = 1 } }
        }
    }
}
