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
        build_table_details
      ]

      document_block.join("\n\n") + "\n"
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
      lines = ["Scheme of database (ER-diagram)", "", "```mermaid", "erDiagram"]
      @schema.each do |table_name, data|
        data[:foreign_keys].each do |fk|
          lines << "    #{fk[:foreign_table]} ||--o{ #{table_name} : \"#{fk[:column]}\""
        end

        lines << "    #{table_name} {"
        data[:columns].each do |col|
          key_mark = col[:is_pk] ? " PK" : ""
          key_mark = " FK" if data[:foreign_keys].any? { |fk| fk[:column] == col[:name] }

          safe_type = col[:type].split("(").first.strip.gsub(/\s+/, "_")
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

    def build_table_details # rubocop:disable Metrics/AbcSize
      tables_md = []

      @schema.sort.each do |table_name, data|
        lines = ["## #{table_name}"]

        lines << "> #{data[:comment]}" if data[:comment] && !data[:comment].empty?
        lines << ""

        lines << "| Name of column | Data type | Nullable | Default value | Description |"
        lines << "|---|---|:---:|---|---|"

        data[:columns].each do |col|
          name_display = col[:is_pk] ? "**#{col[:name]}** *(PK)*" : col[:name]
          nullable_display = col[:nullable] ? "✔" : "⨉"

          safe_default = escape_md_table(col[:default])
          safe_comment = escape_md_table(col[:comment])

          lines << "| #{name_display} | `#{col[:type]}` | #{nullable_display} | `#{safe_default}` | #{safe_comment} |"
        end

        tables_md << lines.join("\n")
      end
      tables_md.join("\n\n---\n\n")
    end

    def escape_md_table(text)
      return "" if text.nil? || text.to_s.strip.empty?

      text.to_s.gsub("|", "\\|").gsub("\n", " ").strip
    end
  end
end
