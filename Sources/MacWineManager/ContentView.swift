import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("wineExecutablePath") private var wineExecutablePath = ""
    @State private var steamInstalled = false
    @State private var statusMessage = ""
    @State private var errorMessage: String?

    private var wineURL: URL? {
        guard !wineExecutablePath.isEmpty else { return nil }
        return URL(fileURLWithPath: wineExecutablePath)
    }

    var body: some View {
        VStack(spacing: 0) {
            enginePicker
                .padding()

            Divider()

            VStack(spacing: 16) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)

                Text("Steam for Windows")
                    .font(.title2.bold())

                Text("التركيز الحالي: ألعاب أوفلاين لا تستخدم أنظمة Anti-Cheat.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack {
                    if steamInstalled {
                        Button("تشغيل Steam", action: launchSteam)
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("تثبيت Steam من ملف التثبيت…", action: installSteam)
                            .buttonStyle(.borderedProminent)
                    }

                    Button("تحديث الحالة", action: refreshSteamStatus)
                }
                .disabled(wineURL == nil)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()

            Divider()

            HStack {
                Text("يلزم الإنترنت لتسجيل الدخول وتنزيل الألعاب؛ اللعب دون اتصال يعتمد على دعم اللعبة وSteam.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                Button("فتح صفحة تنزيل Steam…", action: openSteamDownloadPage)
            }
            .padding()
        }
        .navigationTitle("مدير Steam للألعاب")
        .onAppear(perform: refreshSteamStatus)
        .alert(
            "حدث خطأ",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("حسنًا", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var enginePicker: some View {
        HStack(spacing: 12) {
            Image(systemName: "gearshape.2")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 3) {
                Text("محرك Wine")
                    .font(.headline)
                Text(wineExecutablePath.isEmpty ? "لم يتم تحديد مسار Wine" : wineExecutablePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("اختيار Wine…", action: chooseWine)
        }
    }

    private func installSteam() {
        guard let wineURL else {
            showError("حدد مسار Wine أولًا.")
            return
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "exe") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "تثبيت"

        guard panel.runModal() == .OK, let installerURL = panel.url else { return }

        do {
            try WineLauncher.launch(
                installerURL,
                using: wineURL,
                prefixURL: try steamPrefixURL(),
                logName: "Steam-install.log"
            )
            statusMessage = "بدأ مثبّت Steam. بعد اكتمال التثبيت، اضغط «تحديث الحالة»."
        } catch {
            showError("تعذر تشغيل مثبّت Steam: \(error.localizedDescription)")
        }
    }

    private func launchSteam() {
        guard let wineURL else {
            showError("حدد مسار Wine أولًا.")
            return
        }

        do {
            let executableURL = try steamExecutableURL()
            try WineLauncher.launch(
                executableURL,
                using: wineURL,
                prefixURL: try steamPrefixURL(),
                logName: "Steam.log"
            )
        } catch {
            showError("تعذر تشغيل Steam: \(error.localizedDescription)")
        }
    }

    private func chooseWine() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "اختيار"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard FileManager.default.isExecutableFile(atPath: url.path) else {
            showError("الملف المحدد ليس ملفًا قابلًا للتشغيل.")
            return
        }

        wineExecutablePath = url.path
        refreshSteamStatus()
    }

    private func refreshSteamStatus() {
        do {
            steamInstalled = FileManager.default.fileExists(atPath: try steamExecutableURL().path)
        } catch {
            steamInstalled = false
            showError("تعذر تحديد مجلد Steam: \(error.localizedDescription)")
            return
        }

        if steamInstalled {
            statusMessage = "Steam مثبت. ستتم محاولة تشغيل ألعاب Windows من خلال محرك Wine المحدد."
        } else if wineURL == nil {
            statusMessage = "اختر محرك Wine مجانيًا ومتوافقًا مع Apple Silicon للبدء."
        } else {
            statusMessage = "اختر ملف SteamSetup.exe الرسمي لتثبيت Steam داخل Prefix مستقل."
        }
    }

    private func steamPrefixURL() throws -> URL {
        try AppDirectories.supportDirectory()
            .appendingPathComponent("Prefixes", isDirectory: true)
            .appendingPathComponent("Steam", isDirectory: true)
    }

    private func steamExecutableURL() throws -> URL {
        try steamPrefixURL()
            .appendingPathComponent("drive_c", isDirectory: true)
            .appendingPathComponent("Program Files (x86)", isDirectory: true)
            .appendingPathComponent("Steam", isDirectory: true)
            .appendingPathComponent("steam.exe")
    }

    private func openSteamDownloadPage() {
        guard let url = URL(string: "https://store.steampowered.com/about/") else { return }
        NSWorkspace.shared.open(url)
    }

    private func showError(_ message: String) {
        errorMessage = message
    }
}
