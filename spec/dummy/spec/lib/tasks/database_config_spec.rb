# spec/dummy/lib/tasks/database_config_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'apache_age:database_config', type: :task do
  let(:db_config_file) { File.expand_path("#{Rails.root}/config/database.yml", __FILE__) }

  let(:engine_root_path) { File.expand_path("#{Rails.root}/../../", __FILE__) }
  let(:tasks_path) { File.expand_path("#{engine_root_path}/lib/tasks", __FILE__) }
  let(:task) { Rake::Task['apache_age:database_config'] }

  before do
    # Load the Rake application
    Rake.application.rake_require('database_config', [tasks_path.to_s])
    Rake::Task.define_task(:environment)

    # Re-enable the task to allow multiple invocations in the same spec run
    task.reenable

    # Mock the database.yml file content
    allow(File).to receive(:readlines).with(db_config_file).and_return(db_config_lines)
    allow(File).to receive(:open).with(db_config_file, 'w')
  end

  context 'when schema_search_path is already properly set' do
    let(:db_config_lines) do
      [
        "default: &default\n",
        "  adapter: postgresql\n",
        "  encoding: unicode\n",
        "  schema_search_path: ag_catalog,age_schema,public\n"
      ]
    end

    it 'prints that the schema_search_path is already properly set' do
      expect { task.invoke }.to output(/the schema_search_path in config\/database.yml is already properly set/).to_stdout
    end
  end

  context 'when schema_search_path exists but is not properly set' do
    let(:db_config_lines) do
      [
        "default: &default\n",
        "  adapter: postgresql\n",
        "  encoding: unicode\n",
        "  schema_search_path: public\n"
      ]
    end

    it 'updates the schema_search_path' do
      expect(File).to receive(:open).with(db_config_file, 'w')
      expect { task.invoke }.to output(/added ag_catalog,age_schema to schema_search_path/).to_stdout
    end
  end

  context 'when schema_search_path does not exist but default section is present' do
    let(:db_config_lines) do
      [
        "default: &default\n",
        "  adapter: postgresql\n",
        "  encoding: unicode\n",
        "development:\n",
        "  <<: *default\n",
        "  database: my_app_development\n"
      ]
    end

    it 'adds the schema_search_path to the default section' do
      expect(File).to receive(:open).with(db_config_file, 'w')
      expect { task.invoke }.to output(/the schema_search_path in config\/database.yml is now properly set/).to_stdout
    end
  end

  context 'when default section does not exist' do
    let(:db_config_lines) do
      [
        "development:\n",
        "  adapter: postgresql\n",
        "  encoding: unicode\n",
        "  database: my_app_development\n"
      ]
    end

    it 'prints instructions to add schema_search_path' do
      expect { task.invoke }.to output(/didn't find a default section in database.yml, please add the following line/).to_stdout
    end
  end
end
