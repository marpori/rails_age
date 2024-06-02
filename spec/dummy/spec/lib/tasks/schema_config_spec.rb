# spec/dummy/lib/tasks/schema_config_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'apache_age:schema_config', type: :task do
  let(:destination_schema) { File.expand_path("#{Rails.root}/db/schema.rb", __FILE__) }

  let(:engine_root_path) { File.expand_path("#{Rails.root}/../../", __FILE__) }
  let(:source_schema) { File.expand_path("#{engine_root_path}/db/schema.rb", __FILE__) }
  let(:tasks_path) { File.expand_path("#{engine_root_path}/lib/tasks", __FILE__) }
  let(:task) { Rake::Task['apache_age:schema_config'] }

  before do
    # Load the Rake application and tasks
    Rake.application.rake_require('schema_config', [tasks_path.to_s])
    Rake::Task.define_task(:environment)

    # Re-enable the task to allow multiple invocations in the same spec run
    task.reenable

    # Mock the file existence and content
    allow(File).to receive(:exist?).with(destination_schema).and_return(destination_schema_exists)
    allow(File).to receive(:read).with(source_schema).and_return(source_schema_content)
    allow(File).to receive(:read).with(destination_schema).and_return(destination_schema_content)
    allow(File).to receive(:write).with(destination_schema, anything)
  end

  context 'when the destination schema.rb does not exist' do
    let(:destination_schema_exists) { false }
    let(:source_schema_content) { "" }
    let(:destination_schema_content) { "" }

    it 'prints an error message' do
      expect { task.invoke }.to output(/local db\/schema\.rb file not found. please run db:create and db:migrate first/).to_stdout
    end
  end

  context 'when the destination schema.rb exists' do
    let(:destination_schema_exists) { true }

    context 'when the schema is already properly configured' do
      let(:source_schema_content) { "ActiveRecord::Schema[7.0].define(version: 20220101010101) do\nend" }
      let(:destination_schema_content) do
        <<-RUBY
          ActiveRecord::Schema[7.0].define(version: 20220303030303) do
            execute("LOAD 'age';")
            enable_extension 'plpgsql'
            execute("SELECT create_graph('age_schema');")
            execute('CREATE EXTENSION IF NOT EXISTS age;')
            execute('SET search_path = ag_catalog, "$user", public;')
          end
        RUBY
      end

      it 'prints that the schema is ready' do
        expect { task.invoke }.to output(/The schema '#{destination_schema}' is ready to work with Apache Age./).to_stdout
      end
    end

    context 'when the schema is not properly configured' do
      let(:source_schema_content) { "ActiveRecord::Schema[7.0].define(version: 20220101010101) do\nend" }
      let(:destination_schema_content) do
        <<~RUBY
        # comment
        ActiveRecord::Schema[7.1].define(version: 2024_05_21_062349) do
        end
        RUBY
      end
      let(:expected_schema_content) do
        <<~RUBY
        # comment
        ActiveRecord::Schema[7.1].define(version: 2024_05_21_062349) do
          # These are extensions that must be enabled in order to support this database
          enable_extension 'plpgsql'

          # Allow age extension
          execute('CREATE EXTENSION IF NOT EXISTS age;')

          # Load the age code
          execute("LOAD 'age';")

          # Load the ag_catalog into the search path
          execute('SET search_path = ag_catalog, "$user", public;')

          # Create age_schema graph if it doesn't exist
          execute("SELECT create_graph('age_schema');")

        end
        RUBY
      end

      it 'modifies the schema.rb file and prints that the schema is ready' do
        expect(File).to receive(:write).with(destination_schema, expected_schema_content)
        expect { task.invoke }
          .to output(/The schema '#{destination_schema}' is ready to work with Apache Age./).to_stdout
      end
    end

    context 'when the schema has another migration' do
      let(:source_schema_content) { "ActiveRecord::Schema[7.0].define(version: 20220101010101) do\nend" }
      let(:destination_schema_content) do
        <<~RUBY
        ActiveRecord::Schema[7.1].define(version: 2024_06_02_104539) do
          create_schema "ag_catalog"
          create_schema "age_schema"

          # These are extensions that must be enabled in order to support this database
          enable_extension "age"
          enable_extension "plpgsql"

        # Could not dump table "_ag_label_edge" because of following StandardError
        #   Unknown type 'graphid' for column 'id'

        # Could not dump table "_ag_label_vertex" because of following StandardError
        #   Unknown type 'graphid' for column 'id'

        # Could not dump table "ag_graph" because of following StandardError
        #   Unknown type 'regnamespace' for column 'namespace'

        # Could not dump table "ag_label" because of following StandardError
        #   Unknown type 'regclass' for column 'relation'

          create_table "users", force: :cascade do |t|
            t.string "email"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
          end

          add_foreign_key "ag_label", "ag_graph", column: "graph", primary_key: "graphid", name: "fk_graph_oid"
        end
        RUBY
      end
      let(:expected_schema_content) do
        <<~RUBY
        ActiveRecord::Schema[7.1].define(version: 2024_06_02_104539) do
          # These are extensions that must be enabled in order to support this database
          enable_extension 'plpgsql'

          # Allow age extension
          execute('CREATE EXTENSION IF NOT EXISTS age;')

          # Load the age code
          execute("LOAD 'age';")

          # Load the ag_catalog into the search path
          execute('SET search_path = ag_catalog, "$user", public;')

          # Create age_schema graph if it doesn't exist
          execute("SELECT create_graph('age_schema');")

          create_table "users", force: :cascade do |t|
            t.string "email"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
          end

        end
        RUBY
      end

      it 'modifies the schema.rb file and prints that the schema is ready' do
        expect(File).to receive(:write).with(destination_schema, expected_schema_content)
        expect { task.invoke }
          .to output(/The schema '#{destination_schema}' is ready to work with Apache Age./).to_stdout
      end
    end
  end
end
