import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators

struct StoreEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = StorefrontInfo
	typealias Intent = ViewStoreIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> StorefrontInfo {
		let store = try await context.client.getStorefront()
		let offers = Dictionary(values: try await context.client.getStoreOffers())
		let resolvedOffers = try store.skinsPanelLayout.singleItemOffers.map { offerID in
			let offer = try offers[offerID] ??? UpdateError.unknownOffer
			let reward = try offer.rewards.first ??? UpdateError.malformedOffer
			return try context.assets.resolveSkin(.init(rawID: reward.itemID)) ??? UpdateError.unknownSkin
		}
		
		// TODO: make async, use concurrentMap. only possible if it preserves order.
		func fetchStuff(for resolved: ResolvedLevel) async -> StorefrontInfo.Skin {
			async let icon = resolved.displayIcon?.resolved()
			let tier: ContentTier? = resolved.skin.contentTierID.flatMap { x -> ContentTier? in context.assets.contentTiers[x] }
			async let tierIcon = tier?.displayIcon.resolved()
			return await StorefrontInfo.Skin(
				name: resolved.displayName,
				icon: icon,
				tierColor: tier?.color.wrappedValue,
				tierIcon: tierIcon
			)
		}
		
		return StorefrontInfo(
			nextRefresh: Date(timeIntervalSinceNow: store.skinsPanelLayout.remainingDuration + 1),
			skins: try await resolvedOffers.concurrentMap(fetchStuff(for:))
		)
	}
	
	enum UpdateError: Error, LocalizedError {
		case noAssets
		case unknownOffer
		case malformedOffer
		case unknownSkin
		
		var errorDescription: String? {
			switch self {
			case .noAssets:
				return "Missing Assets!"
			case .unknownOffer:
				return "Unknown Offer"
			case .malformedOffer:
				return "Malformed Offer"
			case .unknownSkin:
				return "Unknown Skin"
			}
		}
	}
}

extension AssetImage {
	func resolved() async -> Image? {
		await Managers.images.awaitImage(for: self).map(Image.init)
	}
}

extension Sequence {
	func concurrentMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
		try await withoutActuallyEscaping(transform) { transform in
			try await withThrowingTaskGroup(of: (Int, T).self) { group in
				var count = 0
				for (i, element) in self.enumerated() {
					count += 1
					group.addTask {
						(i, try await transform(element))
					}
				}
				
				// maintain order
				var transformed: [T?] = .init(repeating: nil, count: count)
				for try await (i, newElement) in group {
					transformed[i] = newElement
				}
				return transformed.map { $0! }
			}
		}
	}
}

typealias StoreEntry = FetchedTimelineEntry<StorefrontInfo, ViewStoreIntent>

extension ViewStoreIntent: SelfFetchingIntent {}

struct StorefrontInfo: FetchedTimelineValue {
	let nextRefresh: Date
	let skins: [Skin]
	
	struct Skin {
		var name: String
		var icon: Image?
		var tierColor: Color?
		var tierIcon: Image?
	}
}
