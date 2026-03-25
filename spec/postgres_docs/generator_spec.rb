# spec/postgres_docs/generator_spec.rb
require 'spec_helper'

RSpec.describe PostgresDocs::Generator do
  let(:schema) do
    {
      'users' => {
        comment: 'User accounts',
        columns: [
          { name: 'id', type: 'integer', nullable: false, default: nil, comment: nil, is_pk: true },
          { name: 'name', type: 'text', nullable: true, default: nil, comment: 'Full name', is_pk: false }
        ],
        foreign_keys: []
      },
      'posts' => {
        comment: nil,
        columns: [
          { name: 'id', type: 'integer', nullable: false, default: nil, comment: nil, is_pk: true },
          { name: 'user_id', type: 'integer', nullable: false, default: nil, comment: nil, is_pk: false }
        ],
        foreign_keys: [
          { column: 'user_id', foreign_table: 'users', foreign_column: 'id' }
        ]
      }
    }
  end

  subject(:generator) { described_class.new(schema) }

  describe '#generate' do
    let(:output) { generator.generate }

    it 'includes the header' do
      expect(output).to include('# Documentation PostreSQL database')
      expect(output).to include('Count of tables: **2**')
    end

    it 'includes a Mermaid ER diagram' do
      expect(output).to include('```mermaid')
      expect(output).to include('erDiagram')
      expect(output).to include('users ||--o{ posts : "user_id"')
      expect(output).to include('users {')
      expect(output).to include('    integer id PK')
      expect(output).to include('    text name')
      expect(output).to include('posts {')
      expect(output).to include('    integer id PK')
      expect(output).to include('    integer user_id FK')
      expect(output).to include('```')
    end

    it 'includes a table of contents' do
      expect(output).to include('## Table of contents')
      expect(output).to include('* [users](#users)')
      expect(output).to include('* [posts](#posts)')
    end

    it 'includes detailed table descriptions' do
      expect(output).to include('## users')
      expect(output).to include('> User accounts')
      expect(output).to include('| Name of column | Data type | Nullable | Default value | Description |')
      expect(output).to include('| **id** *(PK)* | `integer` | ⨉ | `` |  |')
      expect(output).to include('| name | `text` | ✔ | `` | Full name |')
      expect(output).to include('## posts')
      expect(output).to include('| user_id | `integer` | ⨉ | `` |  |')
    end

    it 'escapes pipe characters in comments' do
      schema['users'][:columns] << {
        name: 'bio', type: 'text', nullable: true, default: nil,
        comment: 'Bio with | pipe', is_pk: false
      }
      expect(output).to include('| bio | `text` | ✔ | `` | Bio with \\| pipe |')
    end
  end
end