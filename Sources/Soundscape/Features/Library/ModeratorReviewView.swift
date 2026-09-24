import AVFoundation
import SwiftUI

/// The backend checks moderator membership again on every request; hiding this
/// view is convenience, never the authorization boundary.
struct ModeratorReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: any ModerationRepository
    @State private var pending: [Soundscape] = []
    @State private var reports: [ModerationReport] = []
    @State private var loading = false
    @State private var error: AppError?
    @State private var preview: AVAudioPlayer?
    @State private var coverPreview: UIImage?

    var body: some View {
        NavigationStack {
            List {
                Section(loc(.moderationPending)) {
                    if pending.isEmpty { Text(loc(.moderationEmpty)) }
                    ForEach(pending) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(item.displayTitle).font(.headline)
                            Text(item.authorDisplay).font(.subheadline)
                            Text(item.description).font(.footnote)
                            if item.coverURL != nil {
                                Button(loc(.moderationPreviewCover)) { Task { await showCover(item.id) } }
                                    .buttonStyle(.bordered)
                            }
                            HStack {
                                Button(loc(.moderationListen)) { Task { await listen(item) } }
                                Button(loc(.moderationApprove)) { Task { await decide(item, .approve) } }
                                Button(loc(.moderationReject), role: .destructive) { Task { await decide(item, .reject) } }
                            }
                            .buttonStyle(.bordered)
                        }
                        .accessibilityIdentifier("moderation-item-\(item.id)")
                    }
                }
                Section(loc(.moderationReports)) {
                    ForEach(reports) { report in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(report.title).font(.headline)
                            Text(report.reason)
                            Text(report.created_at).font(.caption)
                            if report.has_cover {
                                Button(loc(.moderationPreviewCover)) { Task { await showCover(report.soundscape_id) } }
                                    .buttonStyle(.bordered)
                            }
                            HStack {
                                Button(loc(.moderationListen)) { Task { await listenReported(report) } }
                                Button(loc(.moderationRemove), role: .destructive) {
                                    Task { await removeReported(report) }
                                }
                                Button(loc(.moderationResolve)) { Task { await resolve(report) } }
                                Button(loc(.moderationSuspend), role: .destructive) {
                                    Task { await suspend(report) }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .overlay { if loading { ProgressView() } }
            .navigationTitle(loc(.moderationQueue))
            .toolbar { Button(loc(.generalDone)) { preview?.stop(); dismiss() } }
            .task { await load() }
            .sheet(item: Binding(
                get: { coverPreview.map(CoverPreview.init) },
                set: { if $0 == nil { coverPreview = nil } }
            )) { preview in
                Image(uiImage: preview.image)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .accessibilityLabel(loc(.moderationPreviewCover))
            }
            .alert(loc(.errorGeneric), isPresented: Binding(
                get: { error != nil }, set: { if !$0 { error = nil } }
            )) { Button(loc(.generalOK)) { error = nil } } message: {
                Text(error?.userMessage ?? loc(.errorTryAgain))
            }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            async let newPending = repository.pending()
            async let newReports = repository.reports()
            pending = try await newPending
            reports = try await newReports
        } catch { show(error) }
    }

    private func listen(_ item: Soundscape) async {
        do {
            preview?.stop()
            let data = try await repository.previewAudio(soundscapeID: item.id)
            preview = try AVAudioPlayer(data: data)
            guard preview?.play() == true else { throw AppError.audioPlaybackUnavailable }
        } catch { show(error) }
    }

    private func listenReported(_ report: ModerationReport) async {
        do {
            preview?.stop()
            let data = try await repository.previewAudio(soundscapeID: report.soundscape_id)
            preview = try AVAudioPlayer(data: data)
            guard preview?.play() == true else { throw AppError.audioPlaybackUnavailable }
        } catch { show(error) }
    }

    private func showCover(_ id: Int) async {
        do {
            let data = try await repository.previewCover(soundscapeID: id)
            guard let image = UIImage(data: data) else { throw AppError.decoding }
            coverPreview = image
        } catch { show(error) }
    }

    private func decide(_ item: Soundscape, _ action: ModerationDecision) async {
        do { preview?.stop(); try await repository.decide(soundscapeID: item.id, action: action); await load() }
        catch { show(error) }
    }

    private func removeReported(_ report: ModerationReport) async {
        do { try await repository.decide(soundscapeID: report.soundscape_id, action: .remove); await load() }
        catch { show(error) }
    }

    private func suspend(_ report: ModerationReport) async {
        do { try await repository.suspendCreator(id: report.author_id); await load() }
        catch { show(error) }
    }

    private func resolve(_ report: ModerationReport) async {
        do { try await repository.resolveReport(id: report.id); await load() }
        catch { show(error) }
    }

    private func show(_ failure: Error) {
        error = (failure as? AppError) ?? .transport(String(describing: type(of: failure)))
    }
}

private struct CoverPreview: Identifiable {
    let id = UUID()
    let image: UIImage
}
