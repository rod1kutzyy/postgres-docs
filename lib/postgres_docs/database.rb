# frozen_string_literal: true

require "pg"

module PostgresDocs
  # Class for extracting tables info from database
  class Database
    def initialize(dsn)
      @dsn = dsn
    end

    def extract_schema
      PG.connect(@dsn) do |conn|
        schema = initialize_tables(conn)
        attach_columns!(conn, schema)
        attach_primary_keys!(conn, schema)
        attach_foreign_keys!(conn, schema)

        schema
      end
    rescue PG::Error => e
      raise StandardError, "Database error: #{e.message}"
    end

    private

    def initialize_tables(conn)
      schema = {}

      query = <<-SQL
        SELECT
          c.relname AS table_name,
          obj_description(c.oid) AS comment
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p')
        ORDER BY c.relname;
      SQL

      conn.exec(query).each do |row|
        schema[row["table_name"]] = {
          comment: row["comment"],
          columns: [],
          foreign_keys: []
        }
      end

      schema
    end

    def attach_columns!(conn, schema)
      query = <<-SQL
        SELECT
          c.relname AS table_name,
          a.attname AS column_name,
          pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
          NOT a.attnotnull AS is_nullable,
          col_description(a.attrelid, a.attnum) AS comment,
          pg_get_expr(d.adbin, d.adrelid) AS default_value
        FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
        WHERE n.nspname = 'public'
          AND c.relkind IN ('r', 'p')
          AND a.attnum > 0
          AND NOT a.attisdropped
        ORDER BY a.attnum;
      SQL

      conn.exec(query).each do |row|
        table_name = row["table_name"]

        next unless schema.key?(table_name)

        schema[table_name][:columns] << {
          name: row["column_name"],
          type: row["data_type"],
          nullable: ["t", true].include?(row["is_nullable"]),
          default: row["default_value"],
          comment: row["comment"],
          is_pk: false
        }
      end
    end

    def attach_primary_keys!(conn, schema)
      query = <<-SQL
        SELECT
          c.relname AS table_name,
          a.attname AS column_name
        FROM pg_index i
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
        JOIN pg_class c ON c.oid = i.indrelid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE i.indisprimary
          AND n.nspname = 'public';
      SQL

      conn.exec(query).each do |row|
        table_name = row["table_name"]
        column_name = row["column_name"]
        next unless schema.key?(table_name)

        column = schema[table_name][:columns].find { |c| c[:name] == column_name }

        column[:is_pk] = true if column
      end
    end

    def attach_foreign_keys!(conn, schema)
      query = <<-SQL
        SELECT
          tc.table_name,
          kcu.column_name,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = 'public';
      SQL

      conn.exec(query).each do |row|
        table_name = row["table_name"]
        next unless schema.key?(table_name)

        schema[table_name][:foreign_keys] << {
          column: row["column_name"],
          foreign_table: row["foreign_table_name"],
          foreign_column: row["foreign_column_name"]
        }
      end
    end
  end
end
