//
//  NatriumConfigSwiftHelper.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 20/10/2017.
//

import Foundation
import Yaml
import Francium

class SwiftVariablesParser: Parser {

    let natrium: Natrium
    var isRequired: Bool {
        return true
    }

    var isOptional: Bool {
        return false
    }

    var yamlKey: String {
        return "variables"
    }

    required init(natrium: Natrium) {
        self.natrium = natrium
    }

    private let preservedVariableNames = [ "environment", "configuration" ]

    private var template: String {
        return """
        import Foundation

        /// Natrium.Config.swift
        /// Autogenerated by natrium
        ///
        /// - see: https://github.com/e-sites/Natrium

        class Natrium {

            enum Environment: String {
        {%environments%}
            }

            enum Configuration: String {
        {%configurations%}
            }

            class Config {
                static let environment: Natrium.Environment = {%environment%}
                static let configuration: Natrium.Configuration = {%configuration%}
        {%customvariables%}
            }
        }

        """
    }

    func parse(_ yaml: [NatriumKey: Yaml]) { // swiftlint:disable:this function_body_length
        let environments = natrium.environments.map {
            return "        case \($0.lowercased()) = \"\($0)\""
        }.joined(separator: "\n")

        let configurations = natrium.configurations.map {
            return "        case \($0.lowercased()) = \"\($0)\""
        }.joined(separator: "\n")

        let customVariables = yaml.map { key, value in
            if preservedVariableNames.contains(key.string) {
                Logger.fatalError("\(key.string) is a reserved variable name")
            }
            let type: String
            var stringValue = value.stringValue
            switch value {
            case .int:
                type = "Int"
            case .double:
                type = "Double"
            case .bool:
                type = "Bool"
            case .null:
                type = "String?"
            default:
                type = "String"
                if value.stringValue == "#error" {
                    stringValue = "\"\" #error(\"\(key.string) value is not set\")"
                } else {
                    stringValue = "\"\(value.stringValue)\""
                }
            }
            return "        static let \(key.string): \(type) = \(stringValue)"
        }.joined(separator: "\n")

        var contents = template
        let array: [(String, String)] = [
            ("environments", environments),
            ("environment", ".\(natrium.environment.lowercased())"),
            ("configurations", configurations),
            ("configuration", ".\(natrium.configuration.lowercased())"),
            ("customvariables", customVariables)
        ]

        for object in array {
            contents = contents.replacingOccurrences(of: "{%\(object.0)%}", with: object.1)
        }

        let currentDirectory = FileManager.default.currentDirectoryPath
        let filePath = "\(currentDirectory)/Natrium.swift"
        do {
            let file = File(path: filePath)
            if file.isExisting {
                file.chmod(0o7777)
            }
            try file.write(string: contents)
        } catch { }
    }
}
