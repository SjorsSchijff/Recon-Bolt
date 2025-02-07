import Foundation
import HandyOperators
import ValorantAPI

struct WidgetLink: Codable {
	var account: User.ID?
	var destination: Destination?
	
	func makeURL() -> URL {
		let data = try! JSONEncoder().encode(self)
		return URL(string: "//widget#\(data.base64EncodedString())")!
	}
	
	enum Destination: Codable {
		case store
	}
}

extension WidgetLink {
	init?(from url: URL) throws {
		guard url.host == "widget" else { return nil }
		let fragment = try url.fragment ??? DecodingError.noFragment
		let data = try Data(base64Encoded: fragment) ??? DecodingError.notBase64(fragment)
		self = try JSONDecoder().decode(Self.self, from: data)
	}
	
	enum DecodingError: Error {
		case noFragment
		case notBase64(String)
	}
}
