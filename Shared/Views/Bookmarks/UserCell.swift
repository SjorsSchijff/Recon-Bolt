import SwiftUI
import ValorantAPI

struct UserCell: View {
	let userID: User.ID
	@Binding var isSelected: Bool
	@LocalData var user: User?
	@LocalData var identity: Player.Identity?
	@LocalData var summary: CareerSummary?
	
	@Environment(\.location) var locationOverride
	
	var body: some View {
		let artworkSize = 64.0
		
		TransparentNavigationLink(isActive: $isSelected) {
			MatchListView(userID: userID, user: user)
		} label: {
			HStack(spacing: 10) {
				if let identity {
					PlayerCardImage.small(identity.cardID)
						.frame(width: artworkSize, height: artworkSize)
						.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
				}
				
				VStack(alignment: .leading, spacing: 4) {
					if let user {
						Text(user.gameName)
							.fontWeight(.semibold)
						+ Text(" #\(user.tagLine)")
							.foregroundColor(.secondary)
					} else {
						Text("Unknown Player")
					}
					
					if let identity {
						Text("Level \(identity.accountLevel)")
					}
				}
				
				Spacer()
				
				RankInfoView(summary: summary, size: artworkSize)
			}
		}
		.padding(.vertical, 8)
		.withLocalData($user, id: userID)
		.withLocalData($identity, id: userID)
		.withLocalData($summary, id: userID, shouldAutoUpdate: true)
	}
}

#if DEBUG
struct UserCell_Previews: PreviewProvider {
	static var previews: some View {
		List {
			UserCell(
				userID: PreviewData.userID,
				isSelected: .constant(false)
			)
			
			UserCell(
				userID: PreviewData.userID,
				isSelected: .constant(false),
				user: PreviewData.user,
				identity: PreviewData.userIdentity,
				summary: PreviewData.summary
			)
			.lockingLocalData()
		}
		.withToolbar()
	}
}
#endif
