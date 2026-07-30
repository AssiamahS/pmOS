import Foundation
import SwiftUI

@MainActor
final class PMStore: ObservableObject {
    @AppStorage("serverURL") var serverURL = "http://100.97.199.99:8796"
    @AppStorage("apiKey") var apiKey = ""

    @Published var projects: [ProjectStatus] = []
    @Published var taskMap: [String: BoardTask] = [:]
    @Published var boardTasks: [BoardTask] = []
    @Published var overdue: [Deliverable] = []
    @Published var dueSoon: [Deliverable] = []
    @Published var lastError: String?
    @Published var isLoading = false
    @Published var lastSync: Date?

    var allOpenDeliverables: [Deliverable] {
        projects.flatMap(\.openDeliverables).sorted { $0.due < $1.due }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let status: StatusResponse = get("/status")
            async let late: OverdueResponse = get("/overdue")
            async let board: TaskboardResponse = get("/taskboard")
            let (s, l, b) = try await (status, late, board)
            projects = s.projects.sorted { $0.key < $1.key }
            taskMap = s.taskMap
            overdue = l.overdue
            dueSoon = l.soon
            boardTasks = b.tasks
            lastError = nil
            lastSync = Date()
        } catch {
            lastError = friendly(error)
        }
    }

    func needBy(project: String, title: String, due: Date, notes: String, createTask: Bool) async -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let body: [String: Any] = [
            "project": project, "title": title,
            "due": fmt.string(from: due),
            "notes": notes, "create_task": createTask,
        ]
        return await post("/needby", body: body)
    }

    func markDeliverableDone(_ d: Deliverable) async -> Bool {
        await post("/done", body: ["id": d.id])
    }

    func setDeliverableStatus(_ d: Deliverable, status: String) async -> Bool {
        await post("/update", body: ["id": d.id, "status": status])
    }

    func toggleTask(_ t: BoardTask) async -> Bool {
        await post("/task/update", body: ["id": t.id, "status": t.isDone ? "active" : "done"])
    }

    // MARK: - transport

    private func request(_ path: String) throws -> URLRequest {
        guard let url = URL(string: serverURL + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url, timeoutInterval: 8)
        if !apiKey.isEmpty { req.setValue(apiKey, forHTTPHeaderField: "X-PM-Key") }
        return req
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let (data, _) = try await URLSession.shared.data(for: request(path))
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post(_ path: String, body: [String: Any]) async -> Bool {
        do {
            var req = try request(path)
            req.httpMethod = "POST"
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                lastError = "Server rejected the change."
                return false
            }
            await refresh()
            return true
        } catch {
            lastError = friendly(error)
            return false
        }
    }

    private func friendly(_ error: Error) -> String {
        let e = error as NSError
        if e.domain == NSURLErrorDomain {
            return "Can't reach the Mac — check Tailscale and the server URL in Settings."
        }
        return e.localizedDescription
    }
}
