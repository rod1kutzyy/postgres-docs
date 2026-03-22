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
        build_mermaid_diagram,
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

    def build_mermaid_diagram # rubocop:disable Metrics/AbcSize
      lines = ["Scheme of database (ER-diagramm)", "", "```mermaid", "erDiagram"]
      @schema.each do |table_name, data|
        data[:foreign_keys].each do |fk|
          lines << "    #{fk[:foreign_table]} ||--o{ #{table_name} : \"#{fk[:column]}\""
        end

        lines << "    #{table_name} {"
        data[:columns].each do |col|
          key_mark = col[:is_pk] ? " PK" : ""
          key_mark = " FK" if data[:foreign_keys].any? { |fk| fk[:column] == col[:name] }

          safe_type = col[:type].gsub(/\s+/, "_")
          lines << "        #{safe_type} #{col[:name]}#{key_mark}"
        end
        lines << "    }"
      end

      lines << "```"
      lines.join("\n")
    end

    def build_toc
      lines = ["## Table of contents", ""]
      @schema.keys.sort.each do |table_name|
        lines << "* [#{table_name}](##{table_name})"
      end
      lines.join("\n")
    end
  end
end
