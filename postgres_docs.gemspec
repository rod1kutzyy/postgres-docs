# frozen_string_literal: true

require_relative "lib/postgres_docs/version"

Gem::Specification.new do |spec|
  spec.name = "postgres_docs"
  spec.version = PostgresDocs::VERSION
  spec.authors = ["Rodion Agutin, Sergei Yakovenko, Zhiteneva Arina"]
  spec.email = ["rodionagutin@gmail.com, ysazeka@gmail.com, arinajitineva@gmail.com"]

  spec.summary = "PostgreSQL database markdown-documentation generator."
  spec.description = "A Ruby tool to extract PostgreSQL schemas and generate Markdown documentation with Mermaid.js ER-diagrams."
  spec.homepage = "https://github.com/rod1kutzyy/postgres-docs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "pg", "~> 1.5"
  spec.add_dependency "thor", "~> 1.3"
  
end
