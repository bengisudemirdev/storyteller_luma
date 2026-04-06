import SwiftUI
import AVFoundation

struct StoryReaderView: View {
    let child: ChildModel?
    let storyTitle: String
    let storyContent: String
    let showSaveButton: Bool
    let story: StoryModel?
    let onSave: (() async -> Void)?

    @State private var currentPage = 0
    @State private var isDeleting = false
    @State private var showDeleteAlert = false
    @State private var isSpeaking = false
    @State private var isElevenLabsLoading = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var elevenLabsPlayer = ElevenLabsSequentialPlayer()
    @State private var elevenLabsTask: Task<Void, Never>?
    @EnvironmentObject private var appUIState: AppUIState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LumaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                TabView(selection: $currentPage) {
                    ForEach(Array(storyPages.enumerated()), id: \.offset) { index, pageText in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 24) {
                                if index == 0 {
                                    Text(storyTitle)
                                        .font(.system(.title, design: .serif))
                                        .fontWeight(.bold)
                                        .foregroundColor(LumaTheme.text)
                                }
                                Text(pageText)
                                    .font(.system(size: 20, weight: .regular, design: .serif))
                                    .lineSpacing(8)
                                    .foregroundColor(LumaTheme.text)
                            }
                            .padding(25)
                            .padding(.bottom, 80)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                pageIndicator
            }
        }
        .navigationBarHidden(true)
        .onAppear { appUIState.isTabBarVisible = false }
        .onDisappear { 
            appUIState.isTabBarVisible = true
            stopSpeaking()
        }
        .alert("Masalı silmek istiyor musun?", isPresented: $showDeleteAlert) {
            Button("Vazgeç", role: .cancel) { }
            Button("Sil", role: .destructive) {
                Task { await deleteStoryIfNeeded() }
            }
        } message: {
            Text("Bu işlem, bu masalı kayıtlı masallarından kalıcı olarak silecek.")
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(LumaTheme.lavender)
            }
            Spacer()
            Text(AppBrand.displayName)
                .font(.system(.headline, design: .serif))
                .italic()
                .foregroundColor(LumaTheme.text)
            Spacer()
            HStack(spacing: 12) {
                Button {
                    toggleSpeaking()
                } label: {
                    HStack(spacing: 6) {
                        if isElevenLabsLoading {
                            ProgressView()
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: isSpeaking ? "pause.circle.fill" : "speaker.wave.2.fill")
                        }
                        Text(isElevenLabsLoading ? "Hazırlanıyor" : (isSpeaking ? "Durdur" : "Seslendir"))
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(LumaTheme.softBlue.opacity(0.15))
                    .foregroundColor(LumaTheme.text)
                    .cornerRadius(12)
                }
                if let onSave = onSave {
                    Button {
                        Task { await onSave() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bookmark")
                            Text("Masalı Kaydet")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(LumaTheme.lavender.opacity(0.12))
                        .foregroundColor(LumaTheme.lavender)
                        .cornerRadius(12)
                    }
                }
                if story != nil {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .padding()
    }

    private var pageIndicator: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Sayfa \(currentPage + 1) / \(max(storyPages.count, 1))")
                    .font(.caption)
                    .foregroundColor(LumaTheme.secondaryText)
                Spacer()
            }
            if storyPages.count > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.caption2)
                        .foregroundColor(LumaTheme.lavender)
                    Text("Yan sayfalara geçmek için yana kaydırın")
                        .font(.caption2)
                        .foregroundColor(LumaTheme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
    }

    private var storyPages: [String] {
        // Çift satır sonuna göre paragrafları sayfalara böler,
        // çok kısa blokları birleştirmek için basit bir eşik uygular.
        let rawBlocks = storyContent
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !rawBlocks.isEmpty else { return [storyContent] }

        var pages: [String] = []
        var current = ""
        let targetLength = 450 // yaklaşık karakter sayısı

        for block in rawBlocks {
            if current.isEmpty {
                current = block
            } else if (current.count + block.count) < targetLength {
                current += "\n\n" + block
            } else {
                pages.append(current)
                current = block
            }
        }
        if !current.isEmpty {
            pages.append(current)
        }
        return pages
    }

    private func deleteStoryIfNeeded() async {
        guard let storyId = story?.id else { return }
        isDeleting = true
        do {
            try await StoryService.deleteStory(id: storyId)
            dismiss()
        } catch {
            AppLogger.error("stories.delete.failed", [
                "storyId": storyId.uuidString,
                "error": String(describing: type(of: error))
            ])
        }
        isDeleting = false
    }

    // MARK: - Speech

    private func toggleSpeaking() {
        guard !storyContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if isSpeaking || isElevenLabsLoading {
            stopSpeaking()
        } else if AppConfig.isElevenLabsNarrationConfigured {
            elevenLabsTask = Task { @MainActor in
                await startElevenLabsNarration()
            }
        } else {
            startSpeaking()
        }
    }

    private func startSpeaking() {
        stopSpeaking()
        let utterance = AVSpeechUtterance(string: storyContent)
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        utterance.rate = 0.47
        utterance.pitchMultiplier = 1.0
        speechSynthesizer.speak(utterance)
        isSpeaking = true
    }

    @MainActor
    private func startElevenLabsNarration() async {
        isElevenLabsLoading = true
        isSpeaking = false
        defer { isElevenLabsLoading = false }
        do {
            let (voiceId, modelId) = try await ElevenLabsNarrationService.resolveVoiceAndModel(
                apiKey: Secrets.elevenLabsAPIKey,
                agentId: Secrets.elevenLabsAgentId
            )
            let urls = try await ElevenLabsNarrationService.synthesizeToTempFiles(
                text: storyContent,
                apiKey: Secrets.elevenLabsAPIKey,
                voiceId: voiceId,
                modelId: modelId
            )
            try Task.checkCancellation()
            isSpeaking = true
            try await elevenLabsPlayer.play(urls: urls)
        } catch is CancellationError {
            // kullanıcı durdurdu
        } catch {
            AppLogger.error("elevenlabs.narration.failed", ["error": String(describing: error)])
        }
        isSpeaking = false
        elevenLabsPlayer.stop()
    }

    private func stopSpeaking() {
        elevenLabsTask?.cancel()
        elevenLabsTask = nil
        elevenLabsPlayer.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isElevenLabsLoading = false
    }
}
