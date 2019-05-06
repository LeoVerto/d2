import SwiftDiscord
import D2Permissions
import D2Utils

/**
 * Matches a subcommand.
 * 
 * 1. group: subcommand name
 * 2. group: subcommand args
 */
fileprivate let subcommandPattern = try! Regex(from: "(\\S+)(?:\\s+(.+))?")
fileprivate let learnPattern = try! Regex(from: "(\\S+)\\s*(\\S+)")

public class PerceptronCommand: StringCommand {
	public let description = "Creates and trains a single-layered perceptron"
	public let helpText = """
		Syntax: [subcommand] [args]
		
		Subcommand patterns:
		- reset [dimensions, 2 if not specified]?
		- learn [expected output value] [learning rate]
		- compute [input value 1] [input value 2], ...
		"""
	public let sourceFile: String = #file
	public let requiredPermissionLevel = PermissionLevel.vip
	
	private let defaultInputCount: Int
	private let renderer = PerceptronRenderer()
	private var model: SingleLayerPerceptron
	private var subcommands: [String: (String, CommandOutput) throws -> Void] = [:]
	
	public init(defaultInputCount: Int = 2) {
		self.defaultInputCount = defaultInputCount
		model = SingleLayerPerceptron(inputCount: defaultInputCount)
		subcommands = [
			"reset": { [unowned self] in self.reset(args: $0, output: $1) },
			"learn": { [unowned self] in try self.learn(args: $0, output: $1) },
			"compute": { [unowned self] in try self.compute(args: $0, output: $1) }
		]
	}
	
	public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
		if let parsedSubcommand = subcommandPattern.firstGroups(in: input) {
			let cmdName = parsedSubcommand[1]
			let cmdArgs = parsedSubcommand[2]
			
			if let subcommand = subcommands[cmdName] {
				do {
					try subcommand(cmdArgs, output)
				} catch MLError.sizeMismatch(let msg) {
					output.append("Size mismatch: \(msg)")
				} catch MLError.illegalState(let msg) {
					output.append("Illegal state: \(msg)")
				} catch MLError.invalidFormat(let msg) {
					output.append("Invalid format: \(msg)")
				} catch {
					output.append("An error occurred: \(error)")
				}
			} else {
				output.append("Unknown subcommand: `\(cmdName)`. Try one of these: `\(subcommands.keys)`")
			}
		} else {
			output.append(helpText)
		}
	}
	
	private func reset(args: String, output: CommandOutput) {
		let dimensions = Int(args) ?? defaultInputCount
		model = SingleLayerPerceptron(inputCount: dimensions)
		output.append("Created a new \(dimensions)-dimensional perceptron")
	}
	
	private func learn(args: String, output: CommandOutput) throws {
		if let parsedArgs = learnPattern.firstGroups(in: args) {
			guard let expected = Double(parsedArgs[1]) else { throw MLError.invalidFormat("Not a number: \(parsedArgs[1])") }
			guard let learningRate = Double(parsedArgs[2]) else { throw MLError.invalidFormat("Not a number: \(parsedArgs[2])") }
			
			try model.learn(expected: expected, rate: learningRate)
			try outputModel(to: output)
		} else {
			output.append("Unrecognized syntax, try: learn [expected output value] [learning rate]")
		}
	}
	
	private func compute(args: String, output: CommandOutput) throws {
		let inputs = args.split(separator: " ").compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
		guard !inputs.isEmpty else { throw MLError.invalidFormat("Please specify space-separated input values") }
		
		try model.compute(inputs)
		try outputModel(to: output)
	}
	
	private func outputModel(to output: CommandOutput) throws {
		output.append(DiscordMessage(
			content: model.formula,
			files: try renderer.render(model: model).map { [
				DiscordFileUpload(data: try $0.pngEncoded(), filename: "perceptron.png", mimeType: "image/png")
			] } ?? []
		))
	}
}
