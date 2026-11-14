import SwiftUI
import Combine
import WatchKit
import WatchConnectivity

struct WatchTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var isComplete: Bool
}

@MainActor
final class WatchStore: NSObject, ObservableObject {
    @Published var tasks: [WatchTask] = [
        WatchTask(id: UUID(uuidString: "2EA160A5-3E45-40E1-9F5A-5636656B5A01")!, title: "Review priorities", detail: "Sample task", isComplete: false),
        WatchTask(id: UUID(uuidString: "2EA160A5-3E45-40E1-9F5A-5636656B5A02")!, title: "Send project update", detail: "Sample task", isComplete: false)
    ]
    @Published var isConnected = false
    @Published var captureMessage: String?
    private var session: WCSession?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let bridge = WCSession.default
        bridge.delegate = self
        session = bridge
        bridge.activate()
    }

    func toggle(_ task: WatchTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isComplete.toggle()
        WKInterfaceDevice.current().play(.success)
        session?.transferUserInfo(["completeTask": task.id.uuidString])
    }

    func capture(_ text: String) {
        let note = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        guard let session, session.activationState == .activated else {
            captureMessage = "Connect to iPhone to send this."
            return
        }
        session.transferUserInfo(["quickNote": note])
        captureMessage = "Sent to iPhone"
        WKInterfaceDevice.current().play(.success)
    }

    fileprivate func receive(_ context: [String: Any]) {
        guard let data = context["tasks"] as? Data,
              let decoded = try? JSONDecoder().decode([WatchTask].self, from: data) else { return }
        tasks = decoded
        isConnected = true
    }
}

extension WatchStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isConnected = false
            self.receive(session.receivedApplicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor [weak self] in self?.receive(applicationContext) }
    }
}

@main
struct DuoFlowWatchApp: App {
    @StateObject private var store = WatchStore()
    var body: some Scene {
        WindowGroup { WatchRootView().environmentObject(store) }
    }
}

struct WatchRootView: View {
    var body: some View {
        TabView {
            WatchHomeView().tag(0)
            WatchTasksView().tag(1)
            QuickCaptureView().tag(2)
        }
        .tabViewStyle(.verticalPage)
        .tint(Color.watchPurple)
    }
}

struct WatchHomeView: View {
    @EnvironmentObject private var store: WatchStore
    private var nextTask: WatchTask? { store.tasks.first(where: { !$0.isComplete }) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Date.now.formatted(.dateTime.weekday(.wide))).font(.caption).foregroundStyle(.secondary)
                        Text(Date.now.formatted(.dateTime.hour().minute())).font(.system(size: 31, weight: .light, design: .rounded)).monospacedDigit()
                    }
                    Spacer()
                    Image(systemName: "sparkle").foregroundStyle(Color.watchPurple)
                }
                Divider()
                Label("NEXT UP", systemImage: "checkmark.circle").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                if let nextTask {
                    Button { store.toggle(nextTask) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(nextTask.title).font(.headline).lineLimit(2).foregroundStyle(.primary)
                            Text("Tap to complete").font(.caption2).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)
                } else {
                    Text("All clear for now.").font(.headline)
                }
                HStack(spacing: 5) {
                    Image(systemName: store.isConnected ? "iphone.gen3.radiowaves.left.and.right" : "iphone.slash")
                    Text(store.isConnected ? "Synced" : "Sample data")
                }.font(.caption2).foregroundStyle(.secondary).padding(.top, 4)
            }.padding(.horizontal, 4)
        }
    }
}

struct WatchTasksView: View {
    @EnvironmentObject private var store: WatchStore
    var body: some View {
        List {
            Section("Tasks") {
                ForEach(store.tasks) { task in
                    Button { store.toggle(task) } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isComplete ? Color.watchBlue : Color.watchPurple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).lineLimit(2).strikethrough(task.isComplete)
                                Text(task.detail).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }
        }.listStyle(.carousel)
    }
}

struct QuickCaptureView: View {
    @EnvironmentObject private var store: WatchStore
    @State private var draft = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick capture", systemImage: "waveform")
                .font(.headline).foregroundStyle(Color.watchPurple)
            TextField("Reminder or note", text: $draft)
                .submitLabel(.send)
                .onSubmit(save)
            Button(action: save) {
                Label("Send to iPhone", systemImage: "arrow.up.circle.fill")
            }.buttonStyle(.borderedProminent).tint(Color.watchPurple)
            if let message = store.captureMessage { Text(message).font(.caption2).foregroundStyle(.secondary) }
        }.padding(.horizontal, 4)
    }
    private func save() {
        store.capture(draft)
        draft = ""
    }
}

private extension Color {
    static let watchPurple = Color(red: 0.58, green: 0.46, blue: 1)
    static let watchBlue = Color(red: 0.47, green: 0.66, blue: 1)
}
