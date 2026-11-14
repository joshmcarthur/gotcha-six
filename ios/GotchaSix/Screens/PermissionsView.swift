import CoreBluetooth
import SwiftUI
import UIKit
import UserNotifications

struct PermissionsView: View {
    @EnvironmentObject private var onboarding: OnboardingStore
    @StateObject private var permissions = PermissionsController()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("Permissions")
                .font(.largeTitle.weight(.bold))
            Text("Bluetooth finds your Gotcha Six. Notifications deliver approaching alerts when the phone is locked.")
                .font(.body)
                .foregroundStyle(.secondary)

            if permissions.needsSettings {
                Text("Bluetooth or notifications are off. Open Settings to enable them, or continue for now.")
                    .font(.callout)
                Button("Open Settings") {
                    permissions.openSettings()
                }
            }

            Spacer()
            Button(permissions.needsSettings ? "Continue anyway" : "Continue") {
                Task {
                    await permissions.requestAll()
                    onboarding.continueFromPermissions()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            permissions.refresh()
        }
    }
}

@MainActor
final class PermissionsController: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var needsSettings = false

    private var central: CBCentralManager?

    func refresh() {
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main, options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
            ])
        } else {
            evaluate(bt: central?.authorization, notif: nil)
        }
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.evaluate(bt: self?.central?.authorization, notif: settings.authorizationStatus)
            }
        }
    }

    func requestAll() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main, options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
            ])
        }
        // Instantiating CBCentralManager triggers the Bluetooth permission prompt when needed.
        refresh()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.evaluate(bt: central.authorization, notif: settings.authorizationStatus)
            }
        }
    }

    private func evaluate(bt: CBManagerAuthorization?, notif: UNAuthorizationStatus?) {
        let btDenied = bt == .denied
        let notifDenied = notif == .denied
        needsSettings = btDenied || notifDenied
    }
}
