import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import D2Utils

public struct MapQuestGeocoder {
	public init() {}
	
	public func geocode(location: String, then: @escaping (Result<GeoCoordinates, Error>) -> Void) {
		let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
		guard let mapQuestKey = storedWebApiKeys?.mapQuest else {
			then(.failure(WebApiError.missingApiKey("No API key for MapQuest found")))
			return
		}
		
		guard let url = URL(string: "https://www.mapquestapi.com/geocoding/v1/address?key=\(mapQuestKey)&location=\(encodedLocation)") else {
			then(.failure(WebApiError.urlStringError("Error while constructing url from location '\(encodedLocation)'")))
			return
		}
		
		// Source: https://stackoverflow.com/questions/39939143/parse-json-response-with-swift-3
		
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		
		URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				if let unwrappedError = error {
					then(.failure(WebApiError.httpError(unwrappedError)))
				}
				return
			}
			do {
				let json = try JSONSerialization.jsonObject(with: data)
				let latLng = (json as? [String: Any])
					.flatMap { $0["results"] }
					.flatMap { $0 as? [Any] }
					.flatMap { $0.first }
					.flatMap { $0 as? [String: Any] }
					.flatMap { $0["locations"] }
					.flatMap { $0 as? [Any] }
					.flatMap { $0.first }
					.flatMap { $0 as? [String: Any] }
					.flatMap { $0["latLng"] }
					.flatMap { $0 as? [String: Double] }
				
				guard let location = latLng else {
					then(.failure(WebApiError.jsonParseError(json, "Could not locate results -> locations -> latLng")))
					return
				}
				guard let lat = location["lat"], let lng = location["lng"] else {
					then(.failure(WebApiError.jsonParseError(location, "No 'lat'/'lng' keys found")))
					return
				}
				then(.success(GeoCoordinates(latitude: lat, longitude: lng)))
			} catch {
				then(.failure(WebApiError.jsonIOError(error)))
			}
		}.resume()
	}
}
