import SwiftDiscord

fileprivate let confirmationString = "delete"

public class ClearCommand: StringCommand {
    public let info = CommandInfo(
        category: .misc,
        shortDescription: "Clears messages",
        longDescription: "Removes the last n messages",
        requiredPermissionLevel: .admin,
        subscribesToNextMessages: true
    )
    private let minDeletableCount: Int
    private let maxDeletableCount: Int
    private var messagesToBeDeleted: [ChannelID: [DiscordMessage]] = [:]
    
    public init(minDeletableCount: Int = 1, maxDeletableCount: Int = 80) {
        self.minDeletableCount = minDeletableCount
        self.maxDeletableCount = maxDeletableCount
    }
    
    public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
        guard let client = context.client else {
            output.append("No DiscordClient available")
            return
        }
        guard let channel = context.channel else {
            output.append("No channel available")
            return
        }
        guard let n = Int(input), n >= minDeletableCount, n <= maxDeletableCount else {
            output.append("Please enter a number (of messages to be deleted) between \(minDeletableCount) and \(maxDeletableCount)!")
            return
        }
        
        client.getMessages(for: channel.id, limit: n) { messages, _ in
            self.messagesToBeDeleted[channel.id] = messages
            let grouped = Dictionary(grouping: messages, by: { $0.author.username })

            output.append(DiscordEmbed(
                title: ":warning: You are about to DELETE \(messages.count) \("message".plural(ifOne: messages.count))",
                description: """
                    \(grouped.map { "\($0.1.count) \("message".plural(ifOne: $0.1.count)) by \($0.0)" }.joined(separator: "\n").nilIfEmpty ?? "_none_")
                    
                    Are you sure? Enter `\(confirmationString)` to confirm (any other message will cancel).
                    """
            ))
        }
    }
    
    public func onSubscriptionMessage(withContent content: String, output: CommandOutput, context: CommandContext) -> SubscriptionAction {
        if let client = context.client, let channel = context.channel, let messages = messagesToBeDeleted[channel.id] {
            messagesToBeDeleted[channel.id] = nil
            if content == confirmationString {
                if messages.count == 1 {
                    client.deleteMessage(messages[0].id, on: channel.id) { success, _ in
                        if success {
                            output.append(":wastebasket: Deleted message")
                        } else {
                            output.append(errorText: "Could not delete message")
                        }
                    }
                } else {
                    client.bulkDeleteMessages(messages.map { $0.id }, on: channel.id) { success, _ in
                        if success {
                            output.append(":wastebasket: Deleted \(messages.count) messages")
                        } else {
                            output.append(errorText: "Could not delete messages")
                        }
                    }
                }
            } else {
                output.append(":x: Cancelling deletion")
            }
        }
        return .cancelSubscription
    }
    
    public func onSuccessfullySent(message: DiscordMessage) {
        if let channel = message.channel, messagesToBeDeleted[channel.id] != nil {
            let isConfirmationMessage = !message.embeds.isEmpty
            if isConfirmationMessage {
                messagesToBeDeleted[channel.id]!.append(message)
            }
        }
    }
}
