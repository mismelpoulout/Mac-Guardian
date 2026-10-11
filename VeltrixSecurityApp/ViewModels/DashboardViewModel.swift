import Foundation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var overview: SystemOverview?
    private(set) var errorMessageKey: String?
    private(set) var isLoading = false

    private let provider = SystemOverviewProvider()

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            overview = try await Task.detached(priority: .utility) { [provider] in
                try provider.load()
            }.value
            errorMessageKey = nil
        } catch let error as MacGuardianError {
            errorMessageKey = error.userMessageKey
        } catch {
            errorMessageKey = "error.systemInformationUnavailable"
        }
    }
}
