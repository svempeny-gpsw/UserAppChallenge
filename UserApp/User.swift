// User.swift

import Foundation

struct Geo: Decodable, Equatable, Hashable, Sendable {
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
        
        guard let latDouble = Double(latString),
                let lngDouble = Double(lngString) else {
            throw DecodingError.dataCorruptedError(forKey: .lat, in: container,
                                                   debugDescription: "Invalid coordinates")
        }
        
        self.lat = latDouble
        self.lng = lngDouble
    }
}

struct Address: Decodable, Equatable, Hashable, Sendable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo?

    private enum CodingKeys: String, CodingKey {
        case street, suite, city, zipcode, geo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        street = try container.decode(String.self, forKey: .street)
        suite = try container.decode(String.self, forKey: .suite)
        city = try container.decode(String.self, forKey: .city)
        zipcode = try container.decode(String.self, forKey: .zipcode)
        geo = try? container.decode(Geo.self, forKey: .geo)
    }
}

struct Company: Decodable, Equatable, Hashable, Sendable {
    let name: String
    let catchPhrase: String
    let bs: String
}

struct User: Decodable, Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String
    let website: String
    let address: Address
    let company: Company
}
