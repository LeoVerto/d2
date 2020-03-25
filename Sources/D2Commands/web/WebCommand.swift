import D2MessageIO
import D2Permissions
import D2Utils
import Logging
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import SwiftSoup

fileprivate let log = Logger(label: "D2Commands.WebCommand")
fileprivate let urlPattern = try! Regex(from: "<?([^>]+)>?")

public class WebCommand: StringCommand {
	public let info = CommandInfo(
		category: .web,
		shortDescription: "Renders a webpage",
		longDescription: "Fetches and renders an arbitrary HTML page using an embed",
		requiredPermissionLevel: .admin
	)
	private let converter = DocumentToMarkdownConverter()
	
	public init() {}
	
	public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
		guard let url = urlPattern.firstGroups(in: input).flatMap({ URL(string: $0[1]) }) else {
			output.append(errorText: "Not a valid URL: `\(input)`")
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		URLSession.shared.dataTask(with: request) { data, response, error in
			guard error == nil else {
				output.append(errorText: "An HTTP error occurred: \(error!)")
				return
			}
			guard let data = data else {
				output.append(errorText: "No data returned")
				return
			}
			guard let html = String(data: data, encoding: .utf8) else {
				output.append(errorText: "Could not decode response as UTF-8")
				return
			}
			
			do {
				let document: Document = try SwiftSoup.parse(html)
				let formattedOutput = try document.body().map { try self.converter.convert($0, baseURL: url) } ?? "Empty body"
				let splitOutput: [String] = self.splitForEmbed(formattedOutput)
				
				output.append(Embed(
					title: try document.title().nilIfEmpty ?? "Web Result",
					description: splitOutput[safely: 0] ?? "Empty output",
					author: Embed.Author(
						name: url.host ?? input,
						iconUrl: self.findFavicon(in: document).flatMap { URL(string: $0, relativeTo: url) }
					),
					fields: splitOutput.dropFirst().enumerated().map { Embed.Field(name: "Page \($0.0 + 1)", value: $0.1) }
				))
			} catch {
				output.append(error, errorText: "An error occurred while parsing the HTML")
			}
		}.resume()
	}
	
	private func splitForEmbed(_ str: String) -> [String] {
		let descriptionLength = 2000
		let fieldLength = 900
		var result = [String(str.prefix(descriptionLength))]
		
		if str.count > descriptionLength {
			result += str.dropFirst(descriptionLength).split(by: fieldLength).prefix(4)
		}
		
		return result
	}
	
	private func findFavicon(in document: Document) -> String? {
		return (try? document.select("link[rel*=icon][href*=png]").first()?.attr("href"))
			.flatMap { $0 } // Flatten nested optional from try?
	}
}
