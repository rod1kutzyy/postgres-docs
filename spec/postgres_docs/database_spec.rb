# frozen_string_literal: true

# spec/postgres_docs/database_spec.rb
require "spec_helper"

RSpec.describe PostgresDocs::Database do
  let(:dsn) { "postgres://user:pass@localhost/db" }
  subject(:db) { described_class.new(dsn) }

  let(:mock_connection) { instance_double(PG::Connection) }
  let(:mock_result) { double("PG::Result", each: []) }

  before do
    allow(PG).to receive(:connect).with(dsn).and_yield(mock_connection)
    allow(mock_connection).to receive(:exec).and_return(mock_result)
  end

  describe "#extract_schema" do
    context "when there are tables" do
      let(:tables_data) do
        [
          { "table_name" => "users", "comment" => "User accounts" },
          { "table_name" => "posts", "comment" => nil }
        ]
      end

      let(:columns_data) do
        [
          { "table_name" => "users", "column_name" => "id", "data_type" => "integer",
            "is_nullable" => "f", "comment" => nil, "default_value" => nil },
          { "table_name" => "users", "column_name" => "name", "data_type" => "text",
            "is_nullable" => "t", "comment" => "Full name", "default_value" => nil },
          { "table_name" => "posts", "column_name" => "id", "data_type" => "integer",
            "is_nullable" => "f", "comment" => nil, "default_value" => nil },
          { "table_name" => "posts", "column_name" => "user_id", "data_type" => "integer",
            "is_nullable" => "f", "comment" => nil, "default_value" => nil }
        ]
      end

      let(:pk_data) do
        [
          { "table_name" => "users", "column_name" => "id" },
          { "table_name" => "posts", "column_name" => "id" }
        ]
      end

      let(:fk_data) do
        [
          { "table_name" => "posts", "column_name" => "user_id",
            "foreign_table_name" => "users", "foreign_column_name" => "id" }
        ]
      end

      before do
        # Первый запрос: таблицы
        allow(mock_connection).to receive(:exec).with(/#{Regexp.escape("FROM pg_class c")}/).and_return(tables_data)
        # Второй запрос: колонки
        allow(mock_connection).to receive(:exec).with(/#{Regexp.escape("FROM pg_attribute a")}/).and_return(columns_data)
        # Третий запрос: PK
        allow(mock_connection).to receive(:exec).with(/#{Regexp.escape("FROM pg_index i")}/).and_return(pk_data)
        # Четвёртый запрос: FK
        allow(mock_connection).to receive(:exec).with(/#{Regexp.escape("FROM information_schema.table_constraints")}/).and_return(fk_data)
      end

      it "returns a hash with tables" do
        schema = db.extract_schema
        expect(schema.keys).to contain_exactly("users", "posts")
      end

      it "includes comments for tables" do
        schema = db.extract_schema
        expect(schema["users"][:comment]).to eq("User accounts")
        expect(schema["posts"][:comment]).to be_nil
      end

      it "populates columns with correct attributes" do
        schema = db.extract_schema
        users_columns = schema["users"][:columns]
        expect(users_columns.size).to eq(2)

        id_col = users_columns.find { |c| c[:name] == "id" }
        expect(id_col).to include(
          name: "id",
          type: "integer",
          nullable: false,
          default: nil,
          comment: nil,
          is_pk: true
        )

        name_col = users_columns.find { |c| c[:name] == "name" }
        expect(name_col).to include(
          name: "name",
          type: "text",
          nullable: true,
          default: nil,
          comment: "Full name",
          is_pk: false
        )
      end

      it "populates foreign keys" do
        schema = db.extract_schema
        fks = schema["posts"][:foreign_keys]
        expect(fks.size).to eq(1)
        expect(fks.first).to include(
          column: "user_id",
          foreign_table: "users",
          foreign_column: "id"
        )
      end
    end

    context "when database error occurs" do
      before do
        allow(PG).to receive(:connect).and_raise(PG::Error, "connection refused")
      end

      it "raises a StandardError" do
        expect { db.extract_schema }.to raise_error(StandardError, /Database error: connection refused/)
      end
    end
  end
end
