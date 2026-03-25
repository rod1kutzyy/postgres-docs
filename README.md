# PostgresDocs

`postgres_docs` is a Ruby gem that generates Markdown documentation for a PostgreSQL database schema, including a Mermaid ER diagram and per-table column details.

It is designed for teams that want schema docs that are easy to review in pull requests, render in GitHub/GitLab, and keep in sync with the actual database.

Internal flow:
1. Connect and read schema (`fetch_db`)
2. Build markdown (`generate_data`)
3. Save file (`write_to_file`)

## Features

- Extracts schema metadata directly from PostgreSQL (`public` schema)
- Supports regular and partitioned tables (`relkind` in `r`, `p`)
- Generates a Mermaid `erDiagram` block with foreign key relationships
- Produces table-by-table Markdown with:
  - column name
  - data type
  - nullability
  - default value
  - column comments
  - primary key markers
- Includes table comments in generated docs (when available)
- Can be used both as a CLI and as a Ruby library

## Requirements

- Ruby `>= 3.2.0`
- PostgreSQL instance reachable via DSN/connection string
- Gems:
  - `pg ~> 1.5`
  - `thor ~> 1.3`

## Installation

### From RubyGems

```bash
gem install postgres_docs
```

or in your `Gemfile`:

```ruby
gem "postgres_docs"
```

### From source

```bash
git clone https://github.com/rod1kutzyy/postgres-docs.git
cd postgres-docs
bundle install
```

## Running tests

Run the test suite with RSpec:

```bash
bundle exec rspec
```

Alternative via rake task:

```bash
bundle exec rake spec
```

## Quick Start (CLI)

Generate documentation to the default file (`database_docs.md`):

```bash
postgres_docs "postgres://user:password@localhost:5432/my_db"
```

Explicit command form:

```bash
postgres_docs generate "postgres://user:password@localhost:5432/my_db"
```

Custom output path:

```bash
postgres_docs generate "postgres://user:password@localhost:5432/my_db" -o docs/database.md
```

## CLI Reference

Executable: `postgres_docs`

### Command

```text
postgres_docs generate DSN [--output PATH]
```

### Arguments

- `DSN` (required): PostgreSQL connection string

### Options

- `-o`, `--output PATH` (optional): output file path
  - default: `database_docs.md`

### Behavior notes

- If the first argument is not a known command and is not an option, it is treated as the DSN for the `generate` command.
- CLI exits with non-zero status on failures (connection errors, generation errors, file write errors).

## DSN Examples

```text
postgres://postgres:secret@localhost:5432/app_db
postgres://readonly_user:password@db.internal:5432/analytics
postgresql://user:password@127.0.0.1:5432/demo_db
```

## Generated Document Structure

The generated Markdown contains:

1. Title and summary block with total table count
2. Mermaid ER diagram (`erDiagram`)
3. Table of contents with anchors
4. Detailed section for every table in alphabetical order


## End-to-End Ruby Example

```ruby
require "postgres_docs"

dsn = "postgres://postgres:secret@localhost:5432/my_db"

schema = PostgresDocs::Database.new(dsn).extract_schema
markdown = PostgresDocs::Generator.new(schema).generate

File.write("docs/database.md", markdown)
puts "Documentation generated: docs/database.md"
```

## Output Example (fragment)

#### Documentation PostreSQL database

> Generated automaticly by gem `postgres_docs`.
> Count of tables: **6**

## Scheme of database (ER-diagram)

```mermaid
erDiagram
    categories ||--o{ categories : "parent_id"
    categories {
        integer id PK
        integer parent_id FK
        character_varying name
        character_varying slug
        text description
    }
    orders ||--o{ order_items : "order_id"
    products ||--o{ order_items : "product_id"
    order_items {
        bigint id PK
        bigint order_id FK
        bigint product_id FK
        integer quantity
        numeric unit_price
    }
    users ||--o{ orders : "user_id"
    orders {
        bigint id PK
        bigint user_id FK
        character_varying status
        numeric total_amount
        text shipping_address
        timestamp_with_time_zone created_at
    }
    categories ||--o{ products : "category_id"
    products {
        bigint id PK
        integer category_id FK
        character_varying sku
        character_varying name
        numeric price
        integer stock_quantity
        timestamp_with_time_zone created_at
    }
    users ||--o{ user_profiles : "user_id"
    user_profiles {
        bigint user_id FK
        character_varying first_name
        character_varying last_name
        text bio
        jsonb preferences
    }
    users {
        bigint id PK
        character_varying username
        character_varying email
        character_varying password_hash
        boolean is_active
        timestamp_with_time_zone last_login
        timestamp_with_time_zone created_at
    }
```

## Error Handling

Common failure points:

- Invalid DSN / unreachable database
- PostgreSQL permissions insufficient to read catalog metadata
- Output file path is not writable

CLI prints human-readable error messages and exits with code `1`.

## License

Released under the MIT License. See `LICENSE.txt`.
