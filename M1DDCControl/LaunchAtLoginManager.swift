import Foundation
import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var errorMessage: String = ""

    init() {
        refresh()
    }

    func refresh() {
        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
        default:
            isEnabled = false
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            errorMessage = ""
            refresh()
        } catch {
            errorMessage = error.localizedDescription
            refresh()
        }
    }
}
