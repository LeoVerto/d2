import Foundation
import SwiftDiscord
import D2Permissions
import D2NetAPIs

public class WikipediaCommand: StringCommand {
    public let info = CommandInfo(
        category: .dictionary,
        shortDescription: "Queries Wikipedia",
        longDescription: "Fetches a page summary from Wikipedia",
        requiredPermissionLevel: .basic
    )
    public let outputValueType: RichValueType = .embed
    
    public init() {}
    
    public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
        WikipediaPageQuery(pageName: input).perform {
            switch $0 {
                case .success(let page):
                    output.append(DiscordEmbed(
                        title: page.displayTitle ?? page.title ?? "No title",
                        description: (page.extract?.prefix(1000)).map { String($0) },
                        image: (page.thumbnail?.source).flatMap { URL(string: $0) }.map { DiscordEmbed.Image(url: $0) },
                        footer: page.description.map { DiscordEmbed.Footer(text: $0) }
                    ))
                case .failure(let error):
                    output.append(error, errorText: "An error occurred while querying the Wikipedia")
            }
        }
    }
}
