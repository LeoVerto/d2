import D2Utils

public protocol MessageDelegate {
	func on(connect connected: Bool, client: MessageClient)

	func on(disconnectWithReason reason: String, client: MessageClient)

	func on(createChannel channelId: ChannelID, client: MessageClient)

	func on(deleteChannel channelId: ChannelID, client: MessageClient)

	func on(updateChannel channelId: ChannelID, client: MessageClient)

	func on(createGuild guild: Guild, client: MessageClient)

	func on(deleteGuild guild: Guild, client: MessageClient)

	func on(updateGuild guild: Guild, client: MessageClient)

	func on(addGuildMember member: Guild.Member, client: MessageClient)

	func on(removeGuildMember member: Guild.Member, client: MessageClient)

	func on(updateGuildMember member: Guild.Member, client: MessageClient)

	func on(updateMessage message: Message, client: MessageClient)

	func on(createMessage message: Message, client: MessageClient)

	func on(createRole role: Role, client: MessageClient)

	func on(deleteRole role: Role, client: MessageClient)

	func on(updateRole role: Role, client: MessageClient)

	func on(receivePresenceUpdate presence: Presence, client: MessageClient)

	func on(receiveReady data: [String: Any], client: MessageClient)

	func on(receiveVoiceStateUpdate state: VoiceState, client: MessageClient)

	func on(handleGuildMemberChunk chunk: LazyDictionary<UserID, Guild.Member>, client: MessageClient)

	func on(updateEmojis emojis: [EmojiID: Emoji], on guild: Guild, client: MessageClient)
}

public extension MessageDelegate {
	func on(connect connected: Bool, client: MessageClient) {}

	func on(disconnectWithReason reason: String, client: MessageClient) {}

	func on(createChannel channelId: ChannelID, client: MessageClient) {}

	func on(deleteChannel channelId: ChannelID, client: MessageClient) {}

	func on(updateChannel channelId: ChannelID, client: MessageClient) {}

	func on(createGuild guild: Guild, client: MessageClient) {}

	func on(deleteGuild guild: Guild, client: MessageClient) {}

	func on(updateGuild guild: Guild, client: MessageClient) {}

	func on(addGuildMember member: Guild.Member, client: MessageClient) {}

	func on(removeGuildMember member: Guild.Member, client: MessageClient) {}

	func on(updateGuildMember member: Guild.Member, client: MessageClient) {}

	func on(updateMessage message: Message, client: MessageClient) {}

	func on(createMessage message: Message, client: MessageClient) {}

	func on(createRole role: Role, client: MessageClient) {}

	func on(deleteRole role: Role, client: MessageClient) {}

	func on(updateRole role: Role, client: MessageClient) {}

	func on(receivePresenceUpdate presence: Presence, client: MessageClient) {}

	func on(receiveReady data: [String: Any], client: MessageClient) {}

	func on(receiveVoiceStateUpdate state: VoiceState, client: MessageClient) {}

	func on(handleGuildMemberChunk chunk: LazyDictionary<UserID, Guild.Member>, client: MessageClient) {}

	func on(updateEmojis emojis: [EmojiID: Emoji], on guild: Guild, client: MessageClient) {}
}
