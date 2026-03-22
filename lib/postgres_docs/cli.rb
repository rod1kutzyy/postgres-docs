# frozen_string_literal: true
require "thor"
require_relative "database"
require_relative "generator"

module PostgresDocs
  class CLI < Thor
    def self.exit_on_failure?
      true
    end
    
    desc "generate DSN", "Generate Markdown-documintation for PostgreSQL data-base"
    method_optin :output,
                  type: :string,
                  aliases: "-o",
                  default: "database_docs.md"
                  desc: "Path for output file (example: docs/db.md)"
    
    
    def generate(dsn)
      say "Connecting to database...", :cyan
      begin
        #logic of getting info from db
        say "Scheme was successfully extracted. Tables founded: #{}", :green
      rescue StandartError => e
        say "Error while working with database. More info: #{}", :red
        exit 1
    end            
  end
end