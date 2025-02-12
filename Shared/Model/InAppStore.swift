import StoreKit
import HandyOperators
import UserDefault

@MainActor
final class InAppStore: ObservableObject {
	@UserDefault("ownedProducts")
	private static var ownedProducts: Set<Product.ID> = []
	
	@Published
	private(set) var proVersion = ResolvableProduct(id: "ReconBolt.Pro")
	
	var ownsProVersion: Bool { owns(proVersion) }
	
	private var updateListenerTask: Task<Void, Never>? = nil
	
	@Published
	private var ownedProducts: Set<Product.ID> = InAppStore.ownedProducts {
		didSet { Self.ownedProducts = ownedProducts }
	}
	
	init() {
		updateListenerTask = listenForTransactions()
		
		Task {
			var owned: Set<Product.ID> = []
			for await existing in Transaction.currentEntitlements {
				guard let transaction = try? existing.payloadValue else { continue }
				print("found existing transaction for \(transaction.productID)")
				update(&owned, from: transaction)
			}
			ownedProducts = owned
		}
		Task { await fetchProducts() }
	}
	
	deinit {
		updateListenerTask?.cancel()
	}
	
	func fetchProducts() async {
		do {
			let products = try await Product.products(for: [proVersion.id])
			try proVersion.resolve(from: products)
		} catch {
			print("error fetching products!", error)
			dump(error)
		}
	}
	
	func owns(_ product: ResolvableProduct) -> Bool {
		ownedProducts.contains(product.id)
	}
	
	func purchase(_ product: Product) async throws {
		switch try await product.purchase() {
		case .success(let result):
			let transaction = try result.payloadValue
			update(from: transaction)
			await transaction.finish()
		case .pending:
			break // TODO: dialog?
		case .userCancelled:
			break
		@unknown default:
			break
		}
	}
	
	func updateStatus(of product: ResolvableProduct) async {
		let latest = await Transaction.latest(for: product.id)
		guard let transaction = try? latest?.payloadValue else { return }
		update(from: transaction)
	}
	
	private func listenForTransactions() -> Task<Void, Never> {
		.detached { [weak self] in
			for await result in Transaction.updates {
				do {
					print("received", result)
					let transaction = try result.payloadValue
					await self?.update(from: transaction)
					await transaction.finish()
				} catch {
					print("error processing listened transaction:", error)
				}
			}
		}
	}
	
	private func update(from transaction: Transaction) {
		update(&ownedProducts, from: transaction)
	}
	
	private func update(_ products: inout Set<Product.ID>, from transaction: Transaction) {
		if transaction.revocationDate == nil {
			products.insert(transaction.productID)
		} else {
			products.remove(transaction.productID)
		}
	}
}

struct ResolvableProduct {
	let id: Product.ID
	private(set) var resolved: Product?
	
	mutating func resolve<S>(from products: S) throws where S: Sequence, S.Element == Product {
		if let match = products.first(where: { $0.id == id }) {
			resolved = match
		} else {
			print("could not resolve product with id \(id)")
		}
	}
	
	enum ResolutionError: Error {
		case noProductWithID(Product.ID)
	}
}
