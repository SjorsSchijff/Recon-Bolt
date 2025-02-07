import SwiftUI
import ValorantAPI

struct AgentSelectView: View {
	let userID: User.ID
	let inventory: Inventory
	@State var pregameInfo: LivePregameInfo
	@State var hasEnded = false
	
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				hero
				
				VStack {
					VStack {
						ForEach(pregameInfo.team.players) { player in
							PlayerView(player: player, userID: userID)
						}
					}
					.padding()
					
					Divider()
					
					HStack {
						lockInIndicators(
							count: pregameInfo.team.players.count,
							lockCount: pregameInfo.team.players.filter(\.isLockedIn).count,
							shouldReverse: false
						)
						.foregroundColor(.valorantBlue)
						
						Spacer()
						
						lockInIndicators(
							count: pregameInfo.enemyTeamSize,
							lockCount: pregameInfo.enemyTeamLockCount,
							shouldReverse: true
						)
						.foregroundColor(.valorantRed)
					}
					.padding()
					
					Divider()
					
					AgentPickerView(pregameInfo: $pregameInfo, userID: userID, inventory: inventory)
				}
			}
		}
		.disabled(hasEnded)
		.overlay(alignment: .top) {
			infoBox
				.padding()
		}
		.navigationTitle("Agent Select")
		.navigationBarTitleDisplayMode(.inline)
		.task {
			while !Task.isCancelled, !hasEnded {
				await refresh()
				await Task.sleep(seconds: 1, tolerance: 0.1)
			}
		}
	}
	
	func refresh() async {
		await load {
			do {
				pregameInfo = try await $0.getLivePregameInfo(pregameInfo.id)
			} catch
				APIError.badResponseCode(404, _, _),
				APIError.resourceNotFound
			{
				hasEnded = true
			}
		}
	}
	
	@ViewBuilder
	private func lockInIndicators(count: Int, lockCount: Int, shouldReverse: Bool) -> some View {
		HStack {
			let indices = Array(0..<count)
			ForEach(shouldReverse ? indices.reversed() : indices, id: \.self) { index in
				if index < lockCount {
					Image(systemName: "lock")
				} else {
					Image(systemName: "lock.open")
						.foregroundStyle(.secondary)
				}
			}
		}
		.symbolVariant(.fill)
	}
	
	@ViewBuilder
	private var hero: some View {
		MapImage.splash(pregameInfo.mapID)
			.aspectRatio(contentMode: .fill)
			.frame(height: 150)
			.clipped()
			// TODO: this doesn't do anything—probably a bug?
			//.ignoresSafeArea()
			.overlay(MapImage.Label(mapID: pregameInfo.mapID).padding(6))
	}
	
	@ViewBuilder
	private var infoBox: some View {
		VStack(spacing: 10) {
			if let queueID = pregameInfo.queueID {
				Text(queueID.name)
					.fontWeight(.medium)
					.foregroundStyle(.secondary)
			}
			
			Group {
				if pregameInfo.state == .provisioned {
					Text("Game Started")
				} else {
					let remainingSeconds = Int(pregameInfo.timeRemainingInPhase.rounded())
					Label("\(remainingSeconds)", systemImage: "timer")
						.monospacedDigit()
				}
			}
			.font(.title2.weight(.bold))
			.foregroundStyle(.primary)
			
			Text("\(pregameInfo.team.id.rawID) Team")
				.foregroundColor(pregameInfo.team.id.color)
		}
		.padding()
		.background(Material.thin)
		.cornerRadius(8)
		.shadow(radius: 10)
	}
	
	struct PlayerView: View {
		let player: LivePregameInfo.PlayerInfo
		let userID: User.ID
		
		@LocalData var playerUser: User?
		@LocalData var summary: CareerSummary?
		@Environment(\.assets) private var assets
		
		private let iconSize = 48.0
		
		var body: some View {
			let relativeColor = player.id == userID ? Color.valorantSelf : .valorantBlue
			
			HStack {
				icon
				
				VStack(alignment: .leading, spacing: 4) {
					if !player.identity.isIncognito, let playerUser {
						HStack {
							Text(playerUser.gameName)
							Text("#\(playerUser.tagLine)")
								.fontWeight(.light)
								.foregroundColor(.secondary)
						}
					}
					
					if player.isLockedIn {
						let agentName = assets?.agents[player.agentID!]?.displayName
						Text(agentName ?? "Unknown Agent!")
							.fontWeight(.semibold)
					} else {
						Text("Picking…")
							.foregroundColor(.secondary)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				
				if player.id != userID {
					NavigationLink {
						MatchListView(userID: player.id, user: playerUser)
							.environment(\.isIncognito, player.identity.isIncognito)
					} label: {
						Image(systemName: "person.crop.circle.fill")
							.padding(.horizontal, 4)
					}
				}
				
				RankInfoView(summary: summary, size: iconSize)
			}
			.accentColor(relativeColor)
			.withLocalData($playerUser, id: player.id)
			.withLocalData($summary, id: player.id, shouldAutoUpdate: true)
		}
		
		@ViewBuilder
		var icon: some View {
			let isLockedIn = player.isLockedIn
			
			agentImage
				.frame(width: iconSize, height: iconSize)
				.mask(Circle())
				.background {
					Circle()
						.fill(.accentColor)
						.opacity(isLockedIn ? 0.5 : 0.25)
						.padding(1)
				}
				.padding(3)
				.background {
					Circle()
						.strokeBorder(.accentColor, lineWidth: isLockedIn ? 2 : 1)
						.opacity(isLockedIn ? 1 : 0.75)
						.padding(isLockedIn ? 0 : 1)
				}
		}
		
		@ViewBuilder
		var agentImage: some View {
			if let agentID = player.agentID {
				AgentImage.icon(agentID)
					.dynamicallyStroked(radius: 1.5, color: .white)
			} else {
				Image(systemName: "questionmark")
					.font(.system(size: iconSize / 2, weight: .bold))
					.foregroundColor(.white)
					.opacity(0.25)
					.blendMode(.plusLighter)
			}
		}
	}
}

#if DEBUG
struct AgentSelectView_Previews: PreviewProvider {
	static var previews: some View {
		AgentSelectView(
			userID: PreviewData.userID,
			inventory: PreviewData.inventory,
			pregameInfo: PreviewData.pregameInfo
		)
		.navigationTitle("Agent Select")
		.withToolbar(allowLargeTitles: false)
	}
}
#endif
