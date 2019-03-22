import SwiftDiscord

class ShowPermissionsCommand: Command {
	let description = "Displays the configured permissions"
	let requiredPermissionLevel = PermissionLevel.admin
	private let permissionManager: PermissionManager
	
	init(permissionManager: PermissionManager) {
		self.permissionManager = permissionManager
	}
	
	func invoke(withMessage message: DiscordMessage, context: CommandContext, args: String) {
		message.channel?.send("```\n\(permissionManager.description)\n```")
	}
}
