import SwiftUI
import SwiftUIMissingPieces
import HandyOperators

extension View {
	func withLoadErrorAlerts() -> some View {
		modifier(LoadWrapper())
	}
}

extension View {
	func loadErrorAlertTitle(_ title: LocalizedStringKey) -> some View {
		preference(key: LoadErrorTitleKey.self, value: title)
	}
}

private struct LoadWrapper: ViewModifier {
	@State private var loadError: Error?
	@State private var errorTitle: LocalizedStringKey = ""
	
	func body(content: Content) -> some View {
		content
			.onPreferenceChange(LoadErrorTitleKey.self) {
				errorTitle = $0
			}
			.environment(\.loadWithErrorAlerts, runTask)
			.alert(errorTitle, for: $loadError)
	}
	
	func runTask(_ task: () async throws -> Void) async {
		do {
			try await task()
		} catch is CancellationError {
			// ignore cancellation
		} catch let urlError as URLError where urlError.code == .cancelled {
			// ignore this type of cancellation too
		} catch {
			guard !Task.isCancelled else { return }
			print("error running load task:")
			dump(error)
			loadError = .init(error)
		}
	}
}

extension View {
	func alert(_ title: LocalizedStringKey, for error: Binding<Error?>) -> some View {
		alert(
			title,
			isPresented: error.isSome(),
			presenting: error.wrappedValue
		) { error in
			Button("Copy Error Details") {
				UIPasteboard.general.string = error.localizedDescription
			}
			Button("OK", role: .cancel) {}
		} message: { error in
			Text(error.localizedDescription)
		}
	}
}

private struct LoadErrorTitleKey: PreferenceKey {
	static let defaultValue: LocalizedStringKey = "Error loading data!"
	
	static func reduce(value: inout LocalizedStringKey, nextValue: () -> LocalizedStringKey) {
		value = nextValue()
	}
}

extension EnvironmentValues {
	typealias LoadTask = () async throws -> Void
	
	/// Executes some remote loading operation, handling any errors by displaying a dismissable alert.
	var loadWithErrorAlerts: (@escaping LoadTask) async -> Void {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		static let defaultValue: (@escaping LoadTask) async -> Void = { _ in
			guard !isInSwiftUIPreview else { return }
			fatalError("no load function provided in environment!")
		}
	}
}

private struct PresentedError: Identifiable {
	let id = UUID()
	
	let error: Error
	
	init(_ error: Error) {
		self.error = error
	}
}
