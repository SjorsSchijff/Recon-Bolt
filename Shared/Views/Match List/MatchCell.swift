import SwiftUI
import SwiftUIMissingPieces
import HandyOperators
import ValorantAPI

struct MatchCell: View {
	let match: CompetitiveUpdate
	let userID: User.ID
	let filter: MatchListFilter
	
	@LocalData var matchDetails: MatchDetails?
	
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		HStack {
			matchInfo
		}
		.padding(.vertical, 8)
		.swipeActions(edge: .leading) {
			if matchDetails == nil {
				AsyncButton {
					await load {
						try await $0.fetchMatchDetails(for: match.id)
					}
				} label: {
					Label("Fetch Details", systemImage: "info.circle.fill")
						.labelStyle(.iconOnly)
				}
				.tint(.blue)
			}
		}
		.id(match.id)
		.withLocalData($matchDetails, id: match.id)
	}
	
	@ScaledMetric private var mapCapsuleHeight = 30
	
	@ViewBuilder
	private var matchInfo: some View {
		let matchesFilter = filter.accepts(match, details: matchDetails)
		
		VStack {
			TransparentNavigationLink {
				MatchDetailsContainer(matchID: match.id, userID: userID)
			} label: {
				HStack {
					match.startTime.relativeText()
					if !matchesFilter {
						Spacer()
						Text(matchDetails?.matchInfo.queueName ?? "Unfetched")
					}
				}
			}
			.font(.caption)
			.disabled(match.mapID == nil)
			
			if matchesFilter {
				if let mapID = match.mapID {
					HStack {
						ZStack {
							if let matchDetails {
								HStack {
									GameModeImage(id: matchDetails.matchInfo.modeID)
										.foregroundColor(.white)
									
									Text(matchDetails.matchInfo.queueName)
										.padding(.top, -2) // small caps are shorter
								}
							} else {
								MapImage.LabelText(mapID: mapID)
									.fixedSize()
									.padding(.top, -2) // small caps are shorter
							}
						}
						.font(.callout.bold().smallCaps())
						.foregroundColor(.white.opacity(0.8))
						.shadow(color: .black, radius: 2, y: 1)
						.padding(4)
						.padding(.horizontal, 2)
						
						Spacer()
						
						let myself = matchDetails?.players.firstElement(withID: userID)
						if let myself {
							AgentImage.killfeedPortrait(myself.agentID!)
								.scaleEffect(x: -1)
								.shadow(color: .black, radius: 4, x: 0, y: 0)
						}
					}
					.frame(height: mapCapsuleHeight)
					.background {
						MapImage.wideImage(mapID)
							.scaledToFill()
							.frame(maxWidth: .infinity)
							.clipped()
					}
					.mask(Capsule())
					
					detailsInfo
						.font(.caption)
						.frame(maxWidth: .infinity)
				} else {
					Text("Lobby Dodged")
						.font(.body.weight(.medium))
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity)
						.frame(height: mapCapsuleHeight)
						.background(Color.tertiaryGroupedBackground, in: Capsule())
				}
			}
		}
		
		if match.isRanked, matchesFilter {
			changeInfo
		}
	}
	
	@ViewBuilder
	private var detailsInfo: some View {
		if let matchDetails {
			let myself = matchDetails.players.firstElement(withID: userID)
			
			VStack {
				ScoreSummaryView(
					teams: matchDetails.teams,
					ownTeamID: myself?.teamID
				)
				.font(.body.weight(.semibold))
				
				if let myself {
					KDASummaryView(player: myself)
						.foregroundStyle(.secondary, .tertiary)
				}
			}
			.transition(.slide)
		}
	}
	
	private var changeInfo: some View {
		HStack {
			VStack(alignment: .trailing) {
				Group {
					if match.performanceBonus != 0 {
						Text("WP: +\(match.performanceBonus)")
							.foregroundColor(.green)
					}
					if match.afkPenalty != 0 {
						Text("AFK: \(match.afkPenalty)")
							.foregroundColor(.red)
					}
				}
				.font(.caption)
				
				let eloChange = match.ratingEarned
				Text(eloChange > 0 ? "+\(eloChange)" : eloChange < 0 ? "\(eloChange)" : "=")
					.foregroundColor(changeColor)
				
				Text("\(match.tierProgressAfterUpdate)")
					.foregroundColor(.gray)
			}
			.frame(minWidth: 50, alignment: .trailing)
			
			ChangeRing(match: match)
				.frame(height: 64)
				.accentColor(changeColor)
		}
		.font(.callout.monospacedDigit())
	}
	
	private var changeColor: Color {
		match.ratingEarned > 0 ? .green : match.ratingEarned < 0 ? .red : .gray
	}
}

private struct ChangeRing: View {
	let match: CompetitiveUpdate
	
	var body: some View {
		ZStack {
			let before = CGFloat(match.eloBeforeUpdate) / 100
			let after = CGFloat(match.eloAfterUpdate) / 100
			let lower = min(before, after)
			let higher = max(before, after)
			let zeroPoint = lower.rounded(.down)
			
			CircularProgressView {
				CircularProgressLayer(
					end: after - zeroPoint,
					color: .gray
				)
				CircularProgressLayer(
					start: lower - zeroPoint,
					end: higher - zeroPoint,
					shouldKnockOutSurroundings: true,
					color: .accentColor
				)
			} base: { Color.gray.opacity(0.2) }
			
			CompetitiveTierImage(tier: match.tierAfterUpdate, time: match.startTime)
				.padding(8)
			
			movementIndicator
				.background(Circle().fill(Color.white).blendMode(.destinationOut))
				.alignmentGuide(.top) { $0[VerticalAlignment.center] }
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		}
		.compositingGroup()
		.padding(2)
		.aspectRatio(contentMode: .fit)
	}
	
	@ViewBuilder
	private var movementIndicator: some View {
		Group {
			if match.tierAfterUpdate > match.tierBeforeUpdate {
				// promotion
				Image(systemName: "chevron.up.circle.fill")
					.foregroundColor(.green)
			} else if match.tierAfterUpdate < match.tierBeforeUpdate {
				// demotion
				Image(systemName: "chevron.down.circle.fill")
					.foregroundColor(.red)
			}
		}
		.font(.system(size: 12))
	}
}

extension Date {
	private static let startDateFormatter = DateFormatter() <- {
		$0.dateStyle = .short
	}
	private static let startTimeFormatter = DateFormatter() <- {
		$0.timeStyle = .short
	}
	private static let relativeStartTimeFormatter = DateComponentsFormatter() <- {
		// DateComponentsFormatter gives us more control than RelativeDateTimeFormatter
		$0.unitsStyle = .abbreviated
		$0.maximumUnitCount = 2
		$0.allowedUnits = [.day, .hour, .minute]
	}
	
	/// uses relative formatting for times less than a day ago
	func relativeText() -> some View {
		HStack {
			let relativeCutoff = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
			if self > relativeCutoff {
				let formatter = Self.relativeStartTimeFormatter
				Text("\(formatter.string(from: self, to: .now)!) ago")
					.foregroundStyle(.secondary)
			} else {
				Text(self, formatter: Self.startDateFormatter)
				Text(self, formatter: Self.startTimeFormatter)
					.foregroundStyle(.secondary)
			}
		}
	}
}

#if DEBUG
struct MatchCell_Previews: PreviewProvider {
	static let demotion = CompetitiveUpdate.example(tierChange: (6, 5), tierProgressChange: (10, 80), index: 0)
		<- { $0.afkPenalty = -7 }
	static let decrease = CompetitiveUpdate.example(tierChange: (8, 8), tierProgressChange: (60, 40), index: 1)
	static let unchanged = CompetitiveUpdate.example(tierChange: (12, 12), tierProgressChange: (50, 50), index: 2)
	static let increase = CompetitiveUpdate.example(tierChange: (8, 8), tierProgressChange: (40, 60), index: 3)
	static let promotion = CompetitiveUpdate.example(tierChange: (20, 21), tierProgressChange: (80, 10), index: 4) <- {
		$0.afkPenalty = -3
		$0.performanceBonus = 11
	}
	
	static let unranked = CompetitiveUpdate.example(tierChange: (0, 0), tierProgressChange: (0, 0), index: 5)
	
	static let jump = CompetitiveUpdate.example(tierChange: (11, 13), tierProgressChange: (90, 30), index: 6)
		<- { $0.performanceBonus = 14 }
	
	static let withinImmortal = CompetitiveUpdate.example(tierChange: (21, 21), tierProgressChange: (290, 310))
	static let promotionToRadiant = CompetitiveUpdate.example(tierChange: (21, 24), tierProgressChange: (379, 400), ratingEarned: 21)
	
	static let dodge = CompetitiveUpdate(
		id: .init(),
		mapID: nil,
		startTime: .init(timeIntervalSinceNow: -234567),
		tierBeforeUpdate: 15,
		tierAfterUpdate: 15,
		tierProgressBeforeUpdate: 44,
		tierProgressAfterUpdate: 41,
		ratingEarned: -3
	)
	
	static let allExamples = [
		demotion, decrease, unchanged, increase, promotion,
		dodge, unranked, jump, withinImmortal, promotionToRadiant,
	]
	
	static var previews: some View {
		List {
			MatchCell(
				match: allExamples.first! <- { $0.id = PreviewData.singleMatch.id },
				userID: PreviewData.userID,
				filter: .init(),
				matchDetails: PreviewData.singleMatch
			)
			
			ForEach(allExamples.dropFirst()) {
				MatchCell(match: $0, userID: PreviewData.userID, filter: .init())
			}
		}
		.withToolbar(allowLargeTitles: false) // otherwise NavigationLink grays out accent colors
	}
}
#endif
