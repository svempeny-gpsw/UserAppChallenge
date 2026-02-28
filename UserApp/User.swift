// User.swift

import Foundation

struct Geo: Decodable, Equatable, Sendable {
    let lat: Double
    let lng: Double

    private enum CodingKeys: String, CodingKey {
        case lat
        case lng
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latString = try container.decode(String.self, forKey: .lat)
        let lngString = try container.decode(String.self, forKey: .lng)
        
        // Use guard to ensure we don't ingest "junk" data
        guard let latDouble = Double(latString),
                let lngDouble = Double(lngString) else {
            throw DecodingError.dataCorruptedError(forKey: .lat, in: container,
                                                   debugDescription: "Invalid coordinates")
        }
        
        self.lat = latDouble
        self.lng = lngDouble
    }
}

struct Address: Decodable, Equatable, Sendable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo?
}

struct Company: Decodable, Equatable, Sendable {
    let name: String
    let catchPhrase: String
    let bs: String
}

struct User: Decodable, Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String
    let website: String
    let address: Address
    let company: Company
}
