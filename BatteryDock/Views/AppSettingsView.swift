import AppKit
import Carbon.HIToolbox
import SwiftUI

struct AppSettingsView: View {
    @ObservedObject var preferences: AppPreferences

    let onCopyDiagnostic: () -> Void
    let onBack: () -> Void

    @State private var isRecording = false
    @State private var eventMonitor: Any?
    @State private var validationMessage: String?

    private var copy: AppCopy {
        AppCopy(language: preferences.language)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    shortcutSection
                    generalSection
                    notificationSection
                    displaySection
                    privacySection
                    actionsSection
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 390, height: 560)
        .background(.regularMaterial)
        .onDisappear {
            stopRecording()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(copy.back)

            VStack(alignment: .leading, spacing: 1) {
                Text("BatteryDock")
                    .font(.headline)

                Text(copy.settings)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var shortcutSection: some View {
        SettingsSection(title: copy.shortcut) {
            Button(action: startRecording) {
                HStack(spacing: 10) {
                    Text(isRecording ? recordPrompt : preferences.shortcut.displayText)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospaced()
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: isRecording ? "record.circle" : "keyboard.badge.ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isRecording ? .red : .secondary)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isRecording ? Color.accentColor : .secondary.opacity(0.18))
                )
            }
            .buttonStyle(.plain)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var generalSection: some View {
        SettingsSection(title: copy.general) {
            SettingsRow(title: copy.launchAtLogin, systemImage: "power") {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { preferences.launchAtLoginEnabled },
                        set: { preferences.setLaunchAtLoginEnabled($0) }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }

            SettingsDivider()

            SettingsRow(title: copy.refreshSetting, systemImage: "arrow.clockwise") {
                Picker("", selection: $preferences.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(copy.refreshIntervalLabel(interval)).tag(interval)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 140)
            }

            SettingsDivider()

            SettingsRow(title: copy.languageSetting, systemImage: "globe") {
                Picker("", selection: $preferences.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(copy.languageLabel(language)).tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 140)
            }
        }
    }

    private var notificationSection: some View {
        SettingsSection(title: copy.notifications) {
            SettingsRow(title: copy.lowBatteryAlerts, systemImage: "bell") {
                Toggle("", isOn: $preferences.lowBatteryNotificationsEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            SettingsDivider()

            SettingsRow(title: copy.threshold, systemImage: "battery.25") {
                Picker("", selection: $preferences.lowBatteryThreshold) {
                    Text("10%").tag(10)
                    Text("20%").tag(20)
                    Text("30%").tag(30)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 156)
                .disabled(!preferences.lowBatteryNotificationsEnabled)
            }
        }
    }

    private var displaySection: some View {
        SettingsSection(title: copy.menuBar) {
            SettingsRow(title: copy.menuBar, systemImage: "menubar.rectangle") {
                Picker("", selection: $preferences.menuBarDisplayMode) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(copy.menuBarModeLabel(mode)).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 156)
            }
        }
    }

    private var privacySection: some View {
        SettingsSection(title: copy.privacy) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)

                Text(copy.privacyNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
        }
    }

    private var actionsSection: some View {
        SettingsSection(title: copy.support) {
            HStack(spacing: 8) {
                Button(action: onCopyDiagnostic) {
                    Label(copy.copyDiagnostic, systemImage: "doc.on.doc")
                }
                .controlSize(.small)

                Button(action: preferences.resetDefaults) {
                    Label(copy.reset, systemImage: "arrow.counterclockwise")
                }
                .controlSize(.small)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let statusMessage = preferences.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var recordPrompt: String {
        copy.recordPrompt
    }

    private var invalidShortcutText: String {
        copy.invalidShortcut
    }

    private func startRecording() {
        guard eventMonitor == nil else {
            return
        }

        validationMessage = nil
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyDown(event)
            return nil
        }
    }

    private func stopRecording() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }

        isRecording = false
    }

    private func handleKeyDown(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            validationMessage = nil
            stopRecording()
            return
        }

        guard
            let shortcut = KeyboardShortcut(event: event),
            shortcut.isRegisterableGlobalHotKey
        else {
            validationMessage = invalidShortcutText
            NSSound.beep()
            return
        }

        preferences.setShortcut(shortcut)
        validationMessage = nil
        stopRecording()
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.secondary.opacity(0.12))
            )
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.callout)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 168, alignment: .leading)

            Spacer(minLength: 8)

            content
                .frame(minWidth: 132, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 34)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 30)
            .padding(.vertical, 7)
    }
}
