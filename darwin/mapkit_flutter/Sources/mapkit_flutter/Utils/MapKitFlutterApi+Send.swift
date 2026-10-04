extension MapKitFlutterApi {
    /// Fire-and-forget host -> Dart event. Main-actor tasks start in creation order.
    @MainActor
    func send(_ event: @escaping @MainActor (MapKitFlutterApi) async throws -> Void) {
        Task { @MainActor in try? await event(self) }
    }
}
