import SwiftUI
import SwiftUIMissingPieces
import Combine
import ValorantAPI

struct LoginSheet: View {
	@Binding var client: ValorantClient?
	
	@EnvironmentObject private var loadManager: LoadManager
	@EnvironmentObject private var credentials: CredentialsStorage
	
	var body: some View {
		ZStack {
			ProgressView("logging in…")
				.opacity(loadManager.isLoading ? 1 : 0)
			VStack(spacing: 12) {
				Text("Log in with your Riot account")
					.font(.title2)
					.multilineTextAlignment(.center)
					.lineLimit(2)
					.fixedSize(horizontal: false, vertical: true) // without this the line limit doesn't seem to work
				VStack {
					Picker("Region: \(credentials.region.name)", selection: $credentials.region) {
						ForEach(Region.allCases, id: \.rawValue) { region in
							Text(verbatim: region.name).tag(region)
						}
					}
					.pickerStyle(MenuPickerStyle())
					
					TextField("Username", text: $credentials.username)
					SecureField("Password", text: $credentials.password) { logIn() }
				}
				.frame(maxWidth: 180)
				
				#if os(iOS)
				Button(action: logIn, label: {
					Text("Log In")
						.bold()
				})
				#endif
			}
			.frame(idealWidth: 180)
			.textFieldStyle(PrettyTextFieldStyle())
			.opacity(loadManager.isLoading ? 0.25 : 1)
		}
		.withoutSheetBottomPadding()
		.padding()
		.toolbar {
			ToolbarItemGroup(placement: .confirmationAction) {
				Button("Log In", action: logIn)
			}
		}
		.loadErrorTitle("Could not log in!")
	}
	
	func logIn() {
		loadManager.runTask(
			ValorantClient.authenticated(
				username: credentials.username,
				password: credentials.password,
				region: credentials.region
			)
		) { client = $0 }
	}
}

struct LoginSheet_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			LoginSheet(client: .constant(nil)).preferredColorScheme(.light)
			LoginSheet(client: .constant(nil)).preferredColorScheme(.dark)
		}.environmentObject(CredentialsStorage(keychain: MockKeychain()))
	}
}
