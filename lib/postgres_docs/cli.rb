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
    method_option :output,
                  type: :string,
                  aliases: "-o",
                  default: "database_docs.md",
                  desc: "Path for output file (example: docs/db.md)"
    
    
    def generate(dsn)
      # All blocks of generating
    rescue StandardError => e
        say "Failed: #{e.message}", :red
        exit 1   
    end

    private 
    
    def fetch_db(dsn)
      say "Connecting to database...", :cyan
      #logic of getting info from db
      say "Scheme was successfully extracted. Tables founded: #{}", :green
    rescue StandardError => e
      say "Error while working with database. More info: #{e.message}", :red
      exit 1
    end
      
    def generate_data(scheme)
      say "Generating MD & Mermaid-scheme...", :cyan
      #logic of generation
    rescue => e
      say "Generation error: #{e.message}", :red
      exit 1
    end
     
    def write_to_file(path,content) 
      File.write(options[:output], md_content)
      say "Documentation successfully saved into: #{options[:output]}", :green
    rescue => e
      say "Writing to file error: #{e.message}", :red
      exit 1
    end

  end
end