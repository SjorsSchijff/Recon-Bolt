import SwiftUI

struct AboutScreen: View {
	var body: some View {
		List {
			VStack(alignment: .leading, spacing: 8) {
				Text("Hi! I'm Julian Dunskus, and I made this app.")
				Text("Recon Bolt started development in early 2021, back when it wasn't yet possible to see your RR gains and losses in the game, but the API offered those numbers.")
				Text("As you can guess, the scope expanded massively over time to what you're using now. I hope you're enjoying it!")
				Text("If you've encountered a bug or have some feedback, I'm always happy to hear it on the Discord Server or GitHub :)")
			}
			
			Section("Links") {
				ListLink("Discord Server", destination: "https://discord.gg/bwENMNRqNa")
				ListLink("GitHub Repo", destination: "https://github.com/juliand665/Recon-Bolt")
				ListLink("Official Website", destination: "https://dapprgames.com/recon-bolt")
				ListLink("Twitter @juliand665", destination: "https://twitter.com/juliand665")
			}
			
			Section("Third-Party Libraries & APIs Used") {
				VStack(alignment: .leading, spacing: 8) {
					Link("keychain-swift", destination: URL(string: "https://github.com/evgenyneu/keychain-swift")!)
					Text("This is what keeps your credentials safe on your device.")
				}
				
				VStack(alignment: .leading, spacing: 8) {
					Link("Valorant-API.com", destination: URL(string: "https://valorant-api.com")!)
					Text("An invaluable API hosting all the assets (images, data, etc.) used throughout Valorant. This is where almost every image in the app comes from.")
				}
			}
		}
		.navigationTitle("About")
	}
}

struct ListLink: View {
	var label: LocalizedStringKey
	var icon: String?
	var destination: URL
	
	init(_ label: LocalizedStringKey, icon: String? = nil, destination: String) {
		self.label = label
		self.destination = .init(string: destination)!
		self.icon = icon
	}
	
	var body: some View {
		Link(destination: destination) {
			NavigationLink {} label: {
				Label(label, systemImage: icon ?? "link")
			}
			.tint(.primary)
		}
	}
}

#if DEBUG
struct AboutScreen_Previews: PreviewProvider {
    static var previews: some View {
        AboutScreen()
			.withToolbar()
    }
}
#endif
