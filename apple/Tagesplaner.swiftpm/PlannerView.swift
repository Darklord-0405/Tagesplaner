import SwiftUI

/// Oberflächen-Zustand als ObservableObject (statt @State), damit sich die App
/// auch mit reinen Kommandozeilen-Werkzeugen ohne Xcode-Makro-Plugins bauen lässt.
final class PlannerUI: ObservableObject {
    @Published var selected = DayKey.add(DayKey.today, days: 1)
    @Published var title = ""
    @Published var hasTime = false
    @Published var time = Date()
    @Published var kind: PlanItem.Kind = .once
    @Published var weekdays: Set<Int> = [DayKey.weekdayIndex(DayKey.add(DayKey.today, days: 1))]
    @Published var armed: String? = nil
    @Published var message = ""
}

// MARK: - Kleine Bausteine

/// Fortschrittsring für den Kopfbereich.
struct RingView: View {
    let value: Double
    let text: String

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.25), lineWidth: 11)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(value, 0), 1)))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(text)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .frame(width: 96, height: 96)
        .animation(.easeOut(duration: 0.35), value: value)
    }
}

/// Großer runder Abhak-Kreis.
struct CheckCircle: View {
    let on: Bool
    var size: CGFloat = 34

    var body: some View {
        Circle()
            .fill(on ? Theme.accent : Color.clear)
            .overlay(Circle().stroke(on ? Theme.accent : Theme.mute.opacity(0.6), lineWidth: 2.5))
            .overlay {
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.46, weight: .heavy))
                        .foregroundStyle(Theme.onAccent)
                }
            }
            .frame(width: size, height: size)
    }
}

struct PlannerView: View {
    @EnvironmentObject var store: PlannerStore
    @StateObject private var ui = PlannerUI()

    private var items: [PlanItem] { store.items(for: ui.selected) }

    private var overdue: [PlanItem] {
        guard ui.selected >= DayKey.today else { return [] }
        return store.planner.items.filter {
            $0.kind == .once && $0.date < DayKey.today && !store.isDone($0.id, on: $0.date)
        }
    }

    private var routines: [PlanItem] {
        store.planner.items.filter { $0.kind != .once }
    }

    private var dayTitle: String {
        switch ui.selected {
        case DayKey.today: return "Heute"
        case DayKey.add(DayKey.today, days: 1): return "Morgen"
        case DayKey.add(DayKey.today, days: -1): return "Gestern"
        default: return label(ui.selected, "EEEE")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tagesplaner")
                        .font(.system(size: 44, weight: .heavy))
                        .tracking(-1)
                        .foregroundStyle(Theme.ink)
                    Text("Plane deinen Tag mit Routinen und einzelnen Aufgaben.")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.mute)
                }
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 380), spacing: 20, alignment: .top)],
                    spacing: 20
                ) {
                    VStack(spacing: 16) {
                        hero
                        overdueSection
                        taskList
                    }
                    VStack(spacing: 20) {
                        addCard
                        routinesCard
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .tint(Theme.accent)
    }

    // MARK: Kopfbereich

    private func heroChip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(on ? Theme.accent : Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.white.opacity(on ? 1 : 0.2), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func heroArrow(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.2), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var hero: some View {
        let list = items
        let doneCount = list.filter { store.isDone($0.id, on: ui.selected) }.count
        let ratio = list.isEmpty ? 0.0 : Double(doneCount) / Double(list.count)
        let ringText = list.isEmpty ? "–" : "\(Int((ratio * 100).rounded())) %"
        let status = list.isEmpty ? "Noch nichts geplant" : "\(doneCount) von \(list.count) erledigt"

        return VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 10) {
                heroChip("Heute", on: ui.selected == DayKey.today) { ui.selected = DayKey.today }
                heroChip("Morgen", on: ui.selected == DayKey.add(DayKey.today, days: 1)) {
                    ui.selected = DayKey.add(DayKey.today, days: 1)
                }
                Spacer()
                heroArrow("chevron.left") { ui.selected = DayKey.add(ui.selected, days: -1) }
                heroArrow("chevron.right") { ui.selected = DayKey.add(ui.selected, days: 1) }
            }
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dayTitle)
                        .font(.system(size: 44, weight: .heavy))
                        .tracking(-1)
                        .foregroundStyle(Color.white)
                    Text(label(ui.selected, "EEEE, d. MMMM"))
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                    Text(status)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                Spacer(minLength: 0)
                RingView(value: ratio, text: ringText)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Theme.heroA, Theme.heroB],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: Theme.heroB.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    // MARK: Aufgaben

    private func meta(_ i: PlanItem) -> String? {
        var parts: [String] = []
        if !i.time.isEmpty { parts.append(i.time) }
        switch i.kind {
        case .once: break
        case .daily: parts.append("täglich")
        case .weekly: parts.append("jeden " + i.weekdays.map { weekdayNames[$0] }.joined(separator: ", "))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func requestDelete(_ i: PlanItem) {
        if i.kind == .once {
            store.deleteItem(i.id)
            return
        }
        if ui.armed == i.id {
            store.deleteItem(i.id)
            ui.armed = nil
        } else {
            ui.armed = i.id
            let id = i.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if ui.armed == id { ui.armed = nil }
            }
        }
    }

    private func deleteButton(_ i: PlanItem) -> some View {
        let armed = ui.armed == i.id
        return Button { requestDelete(i) } label: {
            Group {
                if armed {
                    Text("Serie löschen?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.hot)
                } else {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.mute)
                }
            }
            .padding(10)
        }
        .buttonStyle(.plain)
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.empty, in: Capsule())
    }

    private func softCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
            .shadow(color: Theme.shadow.opacity(0.07), radius: 10, x: 0, y: 4)
    }

    private var taskList: some View {
        let list = items
        return VStack(spacing: 12) {
            if list.isEmpty {
                softCard {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 34))
                            .foregroundStyle(Theme.accent)
                        Text("Noch nichts geplant")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Füge rechts eine Aufgabe oder Routine hinzu.")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.mute)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
            ForEach(list) { i in
                row(i)
            }
        }
    }

    private func row(_ i: PlanItem) -> some View {
        let done = store.isDone(i.id, on: ui.selected)
        return softCard {
            HStack(spacing: 8) {
                Button { store.toggleDone(i.id, on: ui.selected) } label: {
                    HStack(spacing: 16) {
                        CheckCircle(on: done)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(i.title)
                                .font(.system(size: 22, weight: .semibold))
                                .strikethrough(done)
                                .foregroundStyle(done ? Theme.mute : Theme.ink)
                            if let m = meta(i) {
                                badge(m)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                deleteButton(i)
            }
        }
        .opacity(done ? 0.7 : 1)
    }

    @ViewBuilder
    private var overdueSection: some View {
        if !overdue.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Noch offen aus früheren Tagen")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.hot)
                ForEach(overdue) { i in
                    softCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(i.title)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("vom " + label(i.date, "d. MMM"))
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.mute)
                            }
                            Spacer()
                            chip("Hierher", on: false) { store.move(i.id, to: ui.selected) }
                        }
                    }
                }
            }
        }
    }

    // MARK: Formular

    private func chip(_ title: String, on: Bool, wide: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(on ? Theme.onAccent : Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: wide ? .infinity : nil)
                .background(on ? Theme.accent : Theme.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(on ? Theme.accent : Theme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var addCard: some View {
        softCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Neue Aufgabe")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.ink)

                TextField("Was steht an?", text: $ui.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.ink)
                    .padding(14)
                    .background(Theme.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.line, lineWidth: 1)
                    )
                    .onSubmit(addItem)

                HStack(spacing: 10) {
                    chip(ui.hasTime ? "Uhrzeit an" : "Uhrzeit", on: ui.hasTime) { ui.hasTime.toggle() }
                    if ui.hasTime {
                        DatePicker("Zeit", selection: $ui.time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    chip("Einmalig", on: ui.kind == .once, wide: true) { ui.kind = .once }
                    chip("Täglich", on: ui.kind == .daily, wide: true) { ui.kind = .daily }
                    chip("Wöchentlich", on: ui.kind == .weekly, wide: true) { ui.kind = .weekly }
                }

                if ui.kind == .weekly {
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { i in
                            chip(weekdayNames[i], on: ui.weekdays.contains(i), wide: true) {
                                if ui.weekdays.contains(i) {
                                    ui.weekdays.remove(i)
                                } else {
                                    ui.weekdays.insert(i)
                                }
                            }
                        }
                    }
                }

                Button(action: addItem) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                        Text("Hinzufügen")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Theme.heroA, Theme.heroB],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                if !ui.message.isEmpty {
                    Text(ui.message)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.mute)
                }
            }
        }
    }

    private func addItem() {
        let t = ui.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var timeString = ""
        if ui.hasTime {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "HH:mm"
            timeString = f.string(from: ui.time)
        }
        let day = ui.selected
        let days = ui.weekdays.isEmpty ? [DayKey.weekdayIndex(day)] : ui.weekdays.sorted()
        store.add(PlanItem(
            title: t,
            time: timeString,
            kind: ui.kind,
            date: ui.kind == .once ? day : "",
            from: day,
            weekdays: ui.kind == .weekly ? days : []
        ))
        switch ui.kind {
        case .once:
            ui.message = "Hinzugefügt für " + dayTitle + "."
        case .daily:
            ui.message = "Wiederholt sich täglich ab " + label(day, "d. MMM") + "."
        case .weekly:
            ui.message = "Wiederholt sich jeden " + days.map { weekdayNames[$0] }.joined(separator: ", ")
                + " ab " + label(day, "d. MMM") + "."
        }
        ui.title = ""
        ui.hasTime = false
    }

    // MARK: Wiederkehrende Aufgaben

    private var routinesCard: some View {
        softCard {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 0) {
                    if routines.isEmpty {
                        Text("Noch keine Routinen.")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.mute)
                            .padding(.top, 10)
                    }
                    ForEach(Array(routines.enumerated()), id: \.element.id) { idx, i in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(i.title)
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                if let m = meta(i) {
                                    badge(m)
                                }
                            }
                            Spacer()
                            deleteButton(i)
                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .top) {
                            if idx > 0 { Theme.line.frame(height: 1) }
                        }
                    }
                }
            } label: {
                Text("Wiederkehrende Aufgaben (\(routines.count))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}
