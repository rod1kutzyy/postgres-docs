# spec/postgres_docs/cli_spec.rb
require 'spec_helper'
require 'thor'

RSpec.describe PostgresDocs::CLI do
  let(:cli) { described_class.new }
  let(:dsn) { 'postgres://user:pass@localhost/db' }
  let(:output_path) { 'docs/db.md' }

  before do
    allow(cli).to receive(:say)
    allow(cli).to receive(:exit)
  end

  describe '#generate' do
    let(:schema) { { 'users' => { columns: [], foreign_keys: [] } } }
    let(:markdown) { '# Generated' }

    before do
      allow(cli).to receive(:options).and_return({ output: output_path })
    end

    it 'calls fetch_db, generate_data, write_to_file in order' do
      expect(cli).to receive(:fetch_db).with(dsn).and_return(schema)
      expect(cli).to receive(:generate_data).with(schema).and_return(markdown)
      expect(cli).to receive(:write_to_file).with(output_path, markdown)

      cli.generate(dsn)
    end

    it 'uses the output option from Thor' do
      allow(cli).to receive(:fetch_db).and_return(schema)
      allow(cli).to receive(:generate_data).and_return(markdown)

      expect(cli).to receive(:write_to_file).with(output_path, markdown)

      cli.generate(dsn)
    end
  end

  describe '#fetch_db' do
    let(:database_double) { instance_double(PostgresDocs::Database) }
    let(:schema) { { 'users' => {} } }

    before do
      allow(PostgresDocs::Database).to receive(:new).with(dsn).and_return(database_double)
    end

    it 'extracts schema and prints success message' do
      allow(database_double).to receive(:extract_schema).and_return(schema)

      expect(cli).to receive(:say).with(/Connecting to database.../, :cyan)
      expect(cli).to receive(:say).with(/Scheme was successfully extracted. Tables founded: 1/, :green)

      result = cli.send(:fetch_db, dsn)
      expect(result).to eq(schema)
    end

    it 'handles extraction errors and exits' do
      allow(database_double).to receive(:extract_schema).and_raise(StandardError, 'connection failed')

      expect(cli).to receive(:say).with(/Error while working with database. More info: connection failed/, :red)
      expect(cli).to receive(:exit).with(1)

      cli.send(:fetch_db, dsn)
    end
  end

  describe '#generate_data' do
    let(:generator_double) { instance_double(PostgresDocs::Generator) }
    let(:schema) { { 'users' => {} } }
    let(:markdown) { 'Generated markdown' }

    before do
      allow(PostgresDocs::Generator).to receive(:new).with(schema).and_return(generator_double)
    end

    it 'generates markdown and prints message' do
      allow(generator_double).to receive(:generate).and_return(markdown)

      expect(cli).to receive(:say).with(/Generating MD & Mermaid-scheme.../, :cyan)

      result = cli.send(:generate_data, schema)
      expect(result).to eq(markdown)
    end

    it 'handles generation errors' do
      allow(generator_double).to receive(:generate).and_raise(StandardError, 'template error')

      expect(cli).to receive(:say).with(/Generation error: template error/, :red)
      expect(cli).to receive(:exit).with(1)

      cli.send(:generate_data, schema)
    end
  end

  describe '#write_to_file' do
    let(:path) { 'docs/db.md' }
    let(:content) { '# Content' }

    it 'writes content and prints success' do
      expect(File).to receive(:write).with(path, content)
      expect(cli).to receive(:say).with(/Documentation successfully saved into: #{path}/, :green)

      cli.send(:write_to_file, path, content)
    end

    it 'handles write errors' do
      allow(File).to receive(:write).and_raise(StandardError, 'permission denied')

      expect(cli).to receive(:say).with(/Writing to file error: permission denied/, :red)
      expect(cli).to receive(:exit).with(1)

      cli.send(:write_to_file, path, content)
    end
  end
end
