import Foundation
import GraphViz
import Graphics
import D2MessageIO
import Utils

public class MessageDatabaseVisualizeCommand: StringCommand {
    public private(set) var info = CommandInfo(
        category: .misc,
        shortDescription: "Visualizes a statistic using the message database",
        requiredPermissionLevel: .vip
    )
    private let subcommands: [String: (CommandOutput, GuildID) -> Void]

    public init(messageDB: MessageDatabase) {
        subcommands = [
            "membersInChannels": { output, guildId in
                do {
                    var graph = Graph(directed: false)
                    var userNodes = [String: Node]()
                    var channelNodes = [String: Node]()
                    let results = try messageDB.queryMessagesPerMemberInChannels(on: guildId)
                    let maxCount = min(500, results.map(\.count).max() ?? 1)

                    graph.springConstant = 4
                    graph.maximumNumberOfLayoutIterations = 2_000

                    for (channelName, userName, count) in results where count > min(200, maxCount / 2) {
                        let userNode = userNodes[userName] ?? {
                            var node = Node(userName)
                            node.fillColor = .named(.gold)
                            graph.append(node)
                            return node
                        }()
                        let channelNode = channelNodes[channelName] ?? {
                            var node = Node(channelName)
                            node.fillColor = .named(.cyan)
                            graph.append(node)
                            return node
                        }()

                        userNodes[userName] = userNode
                        channelNodes[channelName] = channelNode

                        var edge = Edge(from: userNode, to: channelNode)
                        edge.exteriorLabel = String(count)
                        edge.weight = Double(count)
                        let shade = count == 0 ? 0 : UInt8(min((255 * count) / maxCount, 255))
                        let color = GraphViz.Color.rgb(red: 255 - shade, green: 255 - shade, blue: 255 - shade)
                        edge.strokeColor = color
                        edge.textColor = color
                        edge.strokeWidth = max(1, (2 * Double(count) / Double(maxCount)))
                        graph.append(edge)
                    }

                    graph.render(using: .fdp, to: .png) {
                        do {
                            let data = try $0.get()
                            try output.append(Image(fromPng: data))
                        } catch {
                            output.append(error, errorText: "Could not render people-in-channels graph.")
                        }
                    }
                } catch {
                    output.append(error, errorText: "Could not query people-in-channels statistic.")
                }
            }
        ]
        info.helpText = """
            Syntax: [subcommand]

            Available subcommands: \(subcommands.keys.joined(separator: ", "))
            """
    }

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        guard let guildId = context.guild?.id else {
            output.append(errorText: "Not on a guild!")
            return
        }

        guard let subcommand = subcommands[input] else {
            output.append(errorText: "Unrecognized subcommand `\(input)`. Try one of these: \(subcommands.map { "`\($0)`" }.joined(separator: ", "))")
            return
        }

        subcommand(output, guildId)
    }
}
