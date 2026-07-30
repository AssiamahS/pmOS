import Foundation

struct Deliverable: Codable, Identifiable, Hashable {
    let id: String
    var project: String
    var title: String
    var due: String
    var status: String
    var notes: String?
    var task_ids: [String]?
    var created: String?
    var done_date: String?
    var days_left: Double?

    var isDone: Bool { status == "done" }
    var isOverdue: Bool { !isDone && (days_left ?? 1) < 0 }

    var dueDisplay: String {
        let raw = String(due.prefix(16)).replacingOccurrences(of: "T", with: " ")
        guard let dl = days_left else { return raw }
        if isDone { return "done \(done_date ?? "")" }
        if dl < 0 { return "\(Int(abs(dl.rounded())))d overdue" }
        if dl < 1 { return "\(Int((dl * 24).rounded()))h left" }
        return "\(Int(dl.rounded()))d left"
    }

    var urgency: Urgency {
        if isDone { return .done }
        guard let dl = days_left else { return .calm }
        if dl < 0 { return .overdue }
        if dl <= 1 { return .critical }
        if dl <= 7 { return .soon }
        return .calm
    }
}

enum Urgency { case overdue, critical, soon, calm, done }

struct BoardTask: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var bucket: String?
    var status: String
    var notes: String?
    var deadline: String?
    var done_date: String?

    var isDone: Bool { status == "done" }

    // Malformed board writes have shipped tasks with a null title/status;
    // one such record must not blank the whole decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = (try? c.decode(String.self, forKey: .title)) ?? "(untitled)"
        bucket = try? c.decode(String.self, forKey: .bucket)
        status = (try? c.decode(String.self, forKey: .status)) ?? "active"
        notes = try? c.decode(String.self, forKey: .notes)
        deadline = try? c.decode(String.self, forKey: .deadline)
        done_date = try? c.decode(String.self, forKey: .done_date)
    }
}

struct ProjectMeta: Codable, Hashable {
    var path: String?
    var repo: String?
    var bucket: String?
    var notes: String?
}

struct ProjectStatus: Codable, Identifiable, Hashable {
    var key: String
    var meta: ProjectMeta
    var deliverables: [Deliverable]
    var id: String { key }

    var openDeliverables: [Deliverable] { deliverables.filter { !$0.isDone } }
    var doneDeliverables: [Deliverable] { deliverables.filter { $0.isDone } }
}

struct StatusResponse: Codable {
    var projects: [ProjectStatus]
    var taskMap: [String: BoardTask]
}

struct OverdueResponse: Codable {
    var overdue: [Deliverable]
    var soon: [Deliverable]
    var orphanTasks: [BoardTask]
}

struct TaskboardResponse: Codable {
    var tasks: [BoardTask]
}
