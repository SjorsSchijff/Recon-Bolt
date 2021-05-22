import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI
import VisualEffects
import HandyOperators

struct MatchDetailsContainer: View {
	@EnvironmentObject private var loadManager: LoadManager
	@Environment(\.playerID) private var playerID
	
	let matchID: Match.ID
	
	@State var matchDetails: MatchDetails?
	
	var body: some View {
		Group {
			if let details = matchDetails {
				MatchDetailsView(matchDetails: details, playerID: playerID)
			} else {
				ProgressView()
			}
		}
		.loadErrorTitle("Could not load match details!")
		.onAppear {
			if matchDetails == nil {
				loadManager.load {
					$0.getMatchDetails(matchID: matchID)
				} onSuccess: { matchDetails = $0 }
			}
		}
		.navigationTitle("Match Details")
		.in {
			#if os(iOS)
			$0.navigationBarTitleDisplayMode(.inline)
			#endif
		}
	}
}

private extension CoordinateSpace {
	static let scrollView = Self.named("scrollView")
}

struct MatchDetailsView: View {
	let matchDetails: MatchDetails
	let myself: Player?
	
	init(matchDetails: MatchDetails, playerID: Player.ID?) {
		self.matchDetails = matchDetails
		
		let candidates = matchDetails.players.filter { $0.id == playerID }
		assert(candidates.count <= 1)
		myself = candidates.first
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				hero
					.edgesIgnoringSafeArea(.horizontal)
				
				ScoreboardView(players: matchDetails.players, myself: myself)
			}
		}
		.coordinateSpace(name: CoordinateSpace.scrollView)
	}
	
	private var hero: some View {
		ZStack {
			let mapID = matchDetails.matchInfo.mapID
			MapImage.splash(mapID)
				.aspectRatio(contentMode: .fill)
				.frame(height: 150)
				.clipped()
				.overlay(MapImage.Label(mapID: mapID).padding(6))
			
			#if os(macOS)
			let blur = VisualEffectBlur(material: .toolTip, blendingMode: .withinWindow, state: .followsWindowActiveState)
			#else
			let blur = VisualEffectBlur(blurStyle: .systemThinMaterialDark)
			#endif
			
			VStack {
				scoreSummary(for: matchDetails.teams)
					.font(.largeTitle.weight(.heavy))
				
				Text(matchDetails.matchInfo.queueID.name)
					.font(.largeTitle.weight(.semibold).smallCaps())
					.opacity(0.8)
					.blendMode(.overlay)
			}
			.padding(.horizontal, 6)
			.background(
				blur.roundedAndStroked(cornerRadius: 8)
			)
			.shadow(radius: 10)
			.colorScheme(.dark)
			
		}
	}
	
	@ViewBuilder
	private func scoreSummary(for teams: [Team]) -> some View {
		let _ = assert(!teams.isEmpty)
		let sorted = teams.sorted {
			$0.id == myself?.teamID // self first
				|| $1.id != myself?.teamID // self first
				&& $0.pointCount > $1.pointCount // sort decreasingly by score
		}
		
		if sorted.count >= 2 {
			HStack {
				Text(verbatim: "\(sorted[0].pointCount)")
					.foregroundColor(.valorantBlue)
				Text("–")
					.opacity(0.5)
				Text(verbatim: "\(sorted[1].pointCount)")
					.foregroundColor(.valorantRed)
				
				if sorted.count > 2 {
					Text("–")
						.opacity(0.5)
					Text(verbatim: "…")
						.foregroundColor(.valorantRed)
				}
			}
		} else {
			Text(verbatim: "\(sorted[0].pointCount) points")
		}
	}
	
	private func scoreText(for team: Team) -> some View {
		Text(verbatim: "\(team.pointCount)")
			.foregroundColor(team.id.color)
	}
}

struct MatchDetailsView_Previews: PreviewProvider {
	static let exampleMatchData = try! Data(
		contentsOf: Bundle.main
			.url(forResource: "example_match", withExtension: "json")!
	)
	static let exampleMatch = try! ValorantClient.responseDecoder
		.decode(MatchDetails.self, from: exampleMatchData)
	static let playerID = Player.ID(.init(uuidString: "3FA8598D-066E-5BDB-998C-74C015C5DBA5")!)
	
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			MatchDetailsView(matchDetails: exampleMatch, playerID: playerID)
				//.navigationBarTitleDisplayMode(.inline)
				.navigationTitle("Match Details")
				.withToolbar()
				.preferredColorScheme(scheme)
		}
		.environmentObject(AssetManager.forPreviews)
	}
}

extension EnvironmentValues {
	private enum PlayerIDKey: EnvironmentKey {
		static let defaultValue: Player.ID? = nil
	}
	
	var playerID: Player.ID? {
		get { self[PlayerIDKey.self] }
		set { self[PlayerIDKey.self] = newValue }
	}
}
