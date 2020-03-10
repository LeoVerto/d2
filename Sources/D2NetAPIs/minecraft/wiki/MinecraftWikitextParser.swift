import Logging
import D2Utils

fileprivate let log = Logger(label: "MinecraftWikitextParser")
fileprivate let tokenPattern = try! Regex(from: "\\s*(?:([\\w\\s\\.\\,\\<\\>*!\"'%&\\(\\)\\/]+)|(=+|\\[+|\\]+|\\{+|\\}+|\\|+))\\s*")

/// A basic recursive-descent parser for a subset of wikitext.
public struct MinecraftWikitextParser {
    fileprivate enum Token: CustomStringConvertible {
        case text(String)
        case symbol(String)
        
        var description: String {
            switch self {
                case .text(let s): return s
                case .symbol(let s): return "s\(s)"
            }
        }
    }

    public init() {}
    
    public func parse(raw: String) throws -> MinecraftWikitextDocument {
        let tokens = tokenize(raw: raw)
        log.trace("Tokens: \(tokens)")
        return try parseWikitext(from: TokenIterator(tokens))
    }
    
    private func tokenize(raw: String) -> [Token] {
        tokenPattern.allGroups(in: raw).map {
            if let text = $0[1].nilIfEmpty {
                return .text(text)
            } else {
                return .symbol($0[2])
            }
        }
    }

    private func parseWikitext(from tokens: TokenIterator<Token>) throws -> MinecraftWikitextDocument {
        log.trace("Parsing wikitext")
        var sections = [MinecraftWikitextDocument.Section]()
        while let section = try parseSection(from: tokens) {
            sections.append(section)
        }
        return MinecraftWikitextDocument(sections: sections)
    }
    
    private func parseSection(from tokens: TokenIterator<Token>) throws -> MinecraftWikitextDocument.Section? {
        log.trace("Parsing section")
        let title = try parseTitle(from: tokens)
        let nodes = try parseNodes(from: tokens)
        guard title != nil || !nodes.isEmpty else { return nil }
        return .init(title: title, content: nodes)
    }
    
    private func parseNodes(from tokens: TokenIterator<Token>) throws -> [MinecraftWikitextDocument.Section.Node] {
        log.trace("Parsing nodes")
        var nodes = [MinecraftWikitextDocument.Section.Node]()
        while let node = try parseNode(from: tokens) {
            nodes.append(node)
        }
        return nodes
    }
    
    private func parseNode(from tokens: TokenIterator<Token>) throws -> MinecraftWikitextDocument.Section.Node? {
        log.trace("Parsing node")
        guard let token = tokens.peek() else { return nil }
        switch token {
            case .text(_): return try parseText(from: tokens)
            case .symbol("[["): return try parseLink(from: tokens)
            case .symbol("{{"): return try parseTemplate(from: tokens)
            default: return nil
        }
    }
    
    private func parseLink(from tokens: TokenIterator<Token>) throws -> MinecraftWikitextDocument.Section.Node {
        log.trace("Parsing link")
        guard case .symbol("[[")? = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected opening [[") } 
        guard case let .text(link)? = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected link") }
        guard case .symbol("]]")? = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected closing ]] (after link: \(link))") }
        return .link(link)
    }
    
    private func parseTemplate(from tokens: TokenIterator<Token>) throws -> MinecraftWikitextDocument.Section.Node {
        log.trace("Parsing template")
        guard case .symbol("{{")? = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected opening {{") } 
        guard case let .text(name)? = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected template title") }
        var params = [MinecraftWikitextDocument.Section.Node.TemplateParameter]()
        while case .symbol("|")? = tokens.peek() {
            tokens.next()
            params.append(try parseTemplateParameter(from: tokens))
        }
        guard case .symbol("}}") = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected closing }} (after params: \(params))") }
        return .template(name, params)
    }
    
    private func parseTemplateParameter(from tokens: TokenIterator<Token>) throws -> MinecraftWikitextDocument.Section.Node.TemplateParameter {
        log.trace("Parsing template parameter")
        if let key = parseTemplateParameterKey(from: tokens) {
            return .keyValue(key, try parseNodes(from: tokens))
        } else {
            return .value(try parseNodes(from: tokens))
        }
    }
    
    private func parseTemplateParameterKey(from tokens: TokenIterator<Token>) -> String? {
        log.trace("Parsing template parameter key")
        guard case let .text(key)? = tokens.peek() else { return nil }
        guard case .symbol("=")? = tokens.peek(2) else { return nil }
        tokens.next()
        tokens.next()
        return key
    }
    
    private func parseText(from tokens: TokenIterator<Token>) throws -> MinecraftWikitextDocument.Section.Node {
        log.trace("Parsing text")
        guard case let .text(text)? = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected text") }
        return .text(text)
    }
    
    private func parseTitle(from tokens: TokenIterator<Token>) throws -> String? {
        log.trace("Parsing title")
        guard case let .symbol(opening)? = tokens.peek(), opening.starts(with: "=") else { return nil }
        tokens.next()
        guard case let .text(title)? = tokens.next() else { throw MinecraftWikitextParseError.noMoreTokens("Expected title") }
        guard case let .symbol(closing) = tokens.next(), opening == closing else { throw MinecraftWikitextParseError.unexpectedToken("Closing =s do not match opening =s (\(opening))") }
        return title
    }
}
