import SwiftUI

protocol AssetImageProvider {
	associatedtype Asset: AssetItem & Identifiable
	typealias ID = Asset.ID
	
	static var assetPath: KeyPath<AssetCollection, [ID: Asset]> { get }
}

struct AssetImageView<Provider: AssetImageProvider>: View {
	typealias ID = Provider.ID
	typealias Asset = Provider.Asset
	
	@Environment(\.assets) private var assets
	
	var id: ID
	var renderingMode: Image.TemplateRenderingMode?
	/// aspect ratio for the placeholder shown when the image is not loaded
	var aspectRatio: CGFloat?
	var shouldLoadImmediately = false
	var getImage: (Provider.Asset) -> AssetImage?
	
	var body: some View {
		let assetImage = assets?[keyPath: Provider.assetPath][id]
			.flatMap(getImage)
		
		if let assetImage {
			assetImage.view(
				renderingMode: renderingMode,
				aspectRatio: aspectRatio,
				shouldLoadImmediately: shouldLoadImmediately
			)
		} else if let fallback = UIImage(named: "\(id)".uppercased()) {
			Image(uiImage: fallback)
				.resizable()
				.scaledToFit()
		} else {
			Color.gray
				.aspectRatio(aspectRatio, contentMode: .fit)
		}
	}
}

extension AssetImageView {
	@_disfavoredOverload
	init(
		id: ID,
		renderingMode: Image.TemplateRenderingMode? = nil,
		aspectRatio: CGFloat? = nil,
		shouldLoadImmediately: Bool = false,
		getImage: @escaping (Provider.Asset) -> AssetImage
	) {
		self.init(
			id: id,
			renderingMode: renderingMode,
			aspectRatio: aspectRatio,
			shouldLoadImmediately: shouldLoadImmediately
		) { getImage($0) } // optional promotion
	}
}
