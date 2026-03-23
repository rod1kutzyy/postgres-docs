# frozen_string_literal: true

require "thor"
require_relative "database"
require_relative "generator"

module PostgresDocs
  # Class for CLI API
  class CLI < Thor
    # Ensures that Thor returns a non-zero exit status code upon failure.
    def self.exit_on_failure?
      true
    end

    desc "generate DSN", "Generate Markdown-documentation for PostgreSQL database"
    method_option :output,
                  type: :string,
                  aliases: "-o",
                  default: "database_docs.md",
                  desc: "Path for output file (example: docs/db.md)"

    default_task :generate

    # Main entry point for the CLI. Orchestrates the entire documentation
    # generation process.
    def generate(dsn)
      scheme_data = fetch_db(dsn)
      md_content = generate_data(scheme_data)
      write_to_file(options[:output], md_content)
    end

    private

    # Connects to the database and extracts its internal schema structure.
    def fetch_db(dsn)
      say "Connecting to database...", :cyan
      database = PostgresDocs::Database.new(dsn)
      scheme = database.extract_schema

      say "Scheme was successfully extracted. Tables founded: #{scheme.keys.size}", :green
      scheme
    rescue StandardError => e
      say "Error while working with database. More info: #{e.message}", :red
      exit 1
    end

    # Transforms the raw database schema into formatted Markdown text.
    def generate_data(scheme)
      say "Generating MD & Mermaid-scheme...", :cyan
      generator = PostgresDocs::Generator.new(scheme)
      generator.generate
    rescue StandardError => e
      say "Generation error: #{e.message}", :red
      exit 1
    end

    # Writes the generated documentation payload to the specified file path.
    def write_to_file(path, content)
      File.write(path, content)
      say "Documentation successfully saved into: #{path}", :green
    rescue StandardError => e
      say "Writing to file error: #{e.message}", :red
      exit 1
    end
  end
end
