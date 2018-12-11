This is a work-in-progress marathon script for generating migrations for Vapor Fluent applications.

## What it does

Vapor applications that depend on traditional databases use migrations to evolve the database over time.

This script does 2 things:

- Adds a numbered file with the migration template syntax into your `App/Migrations` folder.
- Mantains a list of "auto migrations" to run as an extension on `MigrationConfig`.

This automates some of the tedium around creating fluent migrations.

## Installing the script

You'll need [marathon](https://github.com/johnsundell/marathon) installed first.

Run this to install the script on your system:

```
$ marathon install subdigital/vapor-add-migration
```

Then type this to run it:

```
$ marathon run AddMigration <type> <name>
```

### Example

Creating a **Model** migration:

```
$ maraton run AddMigration model Project
```

This will create `Source/App/Migrations/001_Project_model.swift` that contains a boilerplate template for a model migration:

```swift
import Vapor
import FluentPostgreSQL

extension Project : Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(self, on: conn) { builder in
            builder.uuidPrimaryKey()
            builder.field(for: \.title)
            builder.timestampFields()

        }
    }
}
```

Creating a **standalone** migration:

```
$ marathon run AddMigration migration AddProjectTitleIndex
```

This creates: `Source/App/Migrations/002_AddProjectTitleIndex.swift` with this template content:

```swift
import Vapor
import FluentPostgreSQL

struct EnableUUIDExtension : PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {

    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {

    }
}

```

Each time you run the script it generates a `_MigrationSupport.swift` file that allows you to easily run these migrations in order:

```swift
/* This file is generated. Do not edit. */
import Vapor
import FluentPostgreSQL

extension MigrationConfig {
    mutating func runAutoMigrations() {
        add(model: Project.self, database: .psql)
        add(migration: AddProjectTitleIndex.self, database: .psql)
    }
}
```

This file is generated and so should not ever be edited (though it should live in source control because Xcode needs to have a reference to this function).

In your Vapor `configure.swift`, where you'd normally add migrations:

```swift
    var migrations = MigrationConfig()

    // Possible to run any other migrations you've registered outside the command as well...
    // migrations.add(migration: EnableUUIDExtension.self, database: .psql)

    // this runs all the auto migrations in order...
    migrations.runAutoMigrations()

    // Then register the migrations with Vapor and you're done!
    services.register(migrations)

```

At this point you don't need to touch `configure.swift` _or_ the migration support file when adding a new migration. Just run the command, edit the generated swift file, and you're done.

Quick side note: Currently this does not touch your Xcode project file, so you'll have to run `vapor xcode` after creating new migrations.

## Assumptions

- This is currently mega-specific to my project and a bunch of assumptions have been hard coded (for now).
- The numbering system is 3 digits (for now). If you end up with more than 1000 migrations you'll run out of addressable space. We may move to a reverse-date based filename instead to ensure ordering without imposing limits.
- Postgres is assumed for now (pull requests welcome to allow this to work with other databases)
- This won't touch your Xcode project, so you'll have to run `vapor xcode` after running this script
- 

If you'd like to help make this more reusable, pull requests are welcome.

## License

This code is released under the MIT License.

