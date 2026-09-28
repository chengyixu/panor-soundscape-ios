import SwiftUI

struct CreateThemeView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: any ModerationRepository
    @State private var title = ""
    @State private var description = ""
    @State private var kind: ListeningTheme.Kind = .topic
    @State private var starts = Date()
    @State private var ends = Date()
    @State private var includesEnd = false
    @State private var saving = false
    @State private var error: AppError?

    var body: some View {
        NavigationStack {
            Form {
                TextField(loc(.themeName), text: $title)
                TextField(loc(.themeDescription), text: $description, axis: .vertical).lineLimit(3...5)
                Picker(loc(.themeTitle), selection: $kind) {
                    Text(loc(.themeTopic)).tag(ListeningTheme.Kind.topic)
                    Text(loc(.themeEvent)).tag(ListeningTheme.Kind.event)
                }
                if kind == .event {
                    DatePicker(loc(.themeStarts), selection: $starts, displayedComponents: .date)
                    Toggle(loc(.themeHasEnd), isOn: $includesEnd)
                    if includesEnd { DatePicker(loc(.themeEnds), selection: $ends, in: starts..., displayedComponents: .date) }
                }
                if let error { Text(error.userMessage).font(.footnote) }
                Button(loc(.themeCreate)) { Task { await save() } }
                    .disabled(saving || title.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                if saving { ProgressView() }
            }
            .navigationTitle(loc(.themeCreate))
            .toolbar { Button(loc(.generalDone)) { dismiss() }.disabled(saving) }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        do {
            _ = try await repository.createTheme(ListeningThemeDraft(title: title, description: description, kind: kind,
                startsOn: kind == .event ? formatter.string(from: starts) : nil,
                endsOn: kind == .event && includesEnd ? formatter.string(from: max(starts, ends)) : nil))
            dismiss()
        } catch { self.error = (error as? AppError) ?? .transport(String(describing: type(of: error))) }
    }
}
