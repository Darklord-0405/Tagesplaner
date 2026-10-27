import SwiftUI

struct PlanItem: Codable, Identifiable {
    enum Kind: String, Codable {
        case once, daily, weekly
    }

    var id: String = UUID().uuidString
    var title: String
    var time: String = ""          // "HH:mm" oder leer
    var kind: Kind
    var date: String = ""          // nur bei .once
    var from: String = ""          // Startdatum bei Wiederholungen
    var weekdays: [Int] = []       // nur bei .weekly, Mo = 0
    var created: Date = Date()
}

struct PlannerState: Codable {
    var items: [PlanItem] = []
    var done: [String: [String]] = [:]
}

final class PlannerStore: ObservableObject {
    @Published var planner: PlannerState {
        didSet { PlannerStore.save(planner) }
    }

    private static let key = "planner.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: PlannerStore.key),
           let saved = try? JSONDecoder().decode(PlannerState.self, from: data) {
            planner = saved
        } else {
            planner = PlannerState()
        }
    }

    private static func save(_ value: PlannerState) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func items(for day: String) -> [PlanItem] {
        planner.items
            .filter { item in
                switch item.kind {
                case .once:
                    return item.date == day
                case .daily:
                    return day >= item.from
                case .weekly:
                    return day >= item.from && item.weekdays.contains(DayKey.weekdayIndex(day))
                }
            }
            .sorted { a, b in
                let ta = a.time.isEmpty ? "99:99" : a.time
                let tb = b.time.isEmpty ? "99:99" : b.time
                if ta != tb { return ta < tb }
                return a.created < b.created
            }
    }

    func isDone(_ id: String, on day: String) -> Bool {
        planner.done[day]?.contains(id) ?? false
    }

    func toggleDone(_ id: String, on day: String) {
        var list = planner.done[day] ?? []
        if let i = list.firstIndex(of: id) {
            list.remove(at: i)
        } else {
            list.append(id)
        }
        planner.done[day] = list
    }

    func add(_ item: PlanItem) {
        planner.items.append(item)
    }

    func deleteItem(_ id: String) {
        planner.items.removeAll { $0.id == id }
    }

    func move(_ id: String, to day: String) {
        if let i = planner.items.firstIndex(where: { $0.id == id }) {
            planner.items[i].date = day
        }
    }
}
