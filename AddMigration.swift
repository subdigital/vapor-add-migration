import Foundation
import Files

let args = CommandLine.arguments

guard args.count == 3 else {
    print("USAGE: marathon run AddMigration <command> <name>")
    exit(1)
}

let command = args[1]
let name = args[2]

let validCommands = ["migration", "model"]

guard validCommands.contains(command) else {
    print("Unrecognized command \(command). Valid commands are: \(validCommands)")
    exit(1)
}

// Folder.current
let folder = try Folder(path: "/Users/ben/Desktop/marathon/tracker")
let appFolder = try folder.subfolder(atPath: "Sources/App")

let migrationsFolder = try appFolder.createSubfolderIfNeeded(withName: "Migrations")



let migrationFiles = migrationsFolder.files

var maxNumber: Int = 0
for file in migrationFiles {
    let scanner = Scanner(string: file.nameExcludingExtension)
    var number: Int = 0
    if scanner.scanInt(&number) && number > maxNumber {
        maxNumber = number
    }
}

func modelMigrationTemplate(_ name: String) -> String {
    return """
    import Vapor
    import FluentPostgreSQL
    
    extension \(name) : Migration {
        static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
            return PostgreSQLDatabase.create(self, on: conn) { builder in
                builder.uuidPrimaryKey()
    
                builder.timestampFields()
    
            }
        }
    }
    
    """
}

func plainMigrationTemplate(_ name: String) -> String {
    return """
    import Vapor
    import FluentPostgreSQL
    
    struct \(name) : PostgreSQLMigration {
        static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    
        }
        
        static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    
        }
    }
    
    """
}

let migrationNumber = maxNumber + 1
let suffix = command == "model" ? "_model" : ""
let filename = String(format: "%03d_%@%@.swift", migrationNumber, name, suffix)

let template = (command == "model" ? modelMigrationTemplate : plainMigrationTemplate)(name)

try migrationsFolder.createFile(named: filename, contents: template)

struct MigrationDescriptor {
    let name: String
    let command: String
    
    func toMigrationSwift() -> String {
        return "add(\(command): \(name).self, database: .psql)"
    }
}

func migrationSupportSwiftFile(_ migrationDescriptors: [MigrationDescriptor]) -> String {
    let migrationList = migrationDescriptors
        .map { $0.toMigrationSwift() }
        .joined(separator: "\n        ")
    
    return """
    /* This file is generated. Do not edit. */
    import Vapor
    import FluentPostgreSQL
    
    extension MigrationConfig {
        mutating func runAutoMigrations() {
            \(migrationList)
        }
    }
    """
}

let migrationSupportFilename = "_MigrationSupport.swift"
let descriptors = migrationFiles
    .filter { $0.name != migrationSupportFilename }
    .map { file -> MigrationDescriptor in
    let parts = file.nameExcludingExtension.components(separatedBy: "_")
    let name = parts[1]
    let command = parts.count > 2 && parts[2] == "model" ? "model" : "migration"
    return MigrationDescriptor(name: name, command: command)
}

let supportFile = migrationSupportSwiftFile(descriptors)
try migrationsFolder.createFile(named: migrationSupportFilename, contents: supportFile)

print("Created \(filename) 🥳. Make sure to run vapor xcode to regenerate your project.")

