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

    private

    def build_header
      <<~MARKDOWN
        # Documentation PostreSQL database

        > Generated automaticly by gem `postgres_docs`.
        > Count of tables: **#{@schema.keys.size} **
      MARKDOWN
    end
  end
end
