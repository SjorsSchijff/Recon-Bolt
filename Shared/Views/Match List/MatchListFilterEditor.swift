import SwiftUI
import ValorantAPI

struct MatchListFilterEditor: View {
	@Binding var filter: MatchListFilter
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationView {
			Form {
				Section {
					FilterSection(
						allowList: $filter.queues,
						toggleLabel: "Filter Queues",
						disclosureLabel: { "^[\($0) queues](inflect: true) selected" }
					)
				}
				
				Section {
					FilterSection(
						allowList: $filter.maps,
						toggleLabel: "Filter Maps",
						disclosureLabel: { "^[\($0) maps](inflect: true) selected" }
					)
				}
				
				Section {
					Toggle("Show Unfetched Matches", isOn: $filter.shouldShowUnfetched)
				} footer: {
					Text("""
						A match's queue is unknown until its details are fetched (by tapping it or performing the swipe action).
						Competitive matches after your placements can be identified without their details, however.
						""")
				}
			}
			.navigationTitle("Filter Match List")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button { dismiss() } label: {
					Text("Done").fontWeight(.semibold)
				}
			}
		}
	}
	
	private struct FilterSection<ID: FilterableID>: View {
		@Binding var allowList: MatchListFilter.AllowList<ID>
		
		var toggleLabel: LocalizedStringKey
		var disclosureLabel: (Int) -> LocalizedStringKey
		
		var body: some View {
			Toggle(toggleLabel, isOn: $allowList.isEnabled)
				.font(.headline)
				.padding(.vertical, 8)
			
			DisclosureGroup(disclosureLabel(allowList.allowed.count)) {
				ForEach(ID.knownIDs, id: \.self) { id in
					Button {
						allowList.toggle(id)
					} label: {
						HStack {
							let isAllowed = allowList.allowed.contains(id)
							
							Image(systemName: "checkmark.circle")
								.symbolVariant(isAllowed ? .fill : .none)
							
							id.label
								.foregroundColor(.primary)
								.opacity(isAllowed && allowList.isEnabled ? 1 : 0.5)
						}
					}
				}
			}
			.disabled(!allowList.isEnabled)
		}
	}
}

#if DEBUG
struct MatchListFilterEditor_Previews: PreviewProvider {
    static var previews: some View {
		HelperView()
    }
	
	struct HelperView: View {
		@State var filter = MatchListFilter(
			queues: .init(isEnabled: true, allowed: [.unrated, .competitive, .escalation]),
			maps: .init(isEnabled: true, allowed: [.haven, .bind])
		)
		
		var body: some View {
			MatchListFilterEditor(filter: $filter)
		}
	}
}
#endif
