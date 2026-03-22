# frozen_string_literal: true

module PostgresDocs
  # Main genrator
  class Generator
    def initialize(schema)
      @schema = schema
    end

    def generate
      document_block = [
        build_header,
        build_mm_diagram,
        build_toc,
        build_table_datails
      ]

      "#{document_block.join("\n\n")}\\n"
    end
  end
end
