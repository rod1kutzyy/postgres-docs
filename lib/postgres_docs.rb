# frozen_string_literal: true

require_relative "postgres_docs/version"
require_relative "postgres_docs/database"
require_relative "postgres_docs/generator"
require_relative "postgres_docs/cli"

module PostgresDocs
  class Error < StandardError; end
end
