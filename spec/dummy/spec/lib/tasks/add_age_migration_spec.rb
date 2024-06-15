# spec/tasks/install_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'apache_age:add_age_migration', type: :task do
  let(:engine_root_path) { File.expand_path("#{Rails.root}/../../", __FILE__) }
  # let(:source_path) { File.expand_path("#{engine_root_path}/db/migrate", __FILE__) }
  let(:tasks_path) { File.expand_path("#{engine_root_path}/lib/tasks", __FILE__) }
  let(:destination_path) { Dir.mktmpdir }
  let(:task) { Rake::Task['apache_age:copy_migrations'] }

  before do
    # Load the Rake application
    Rake.application.rake_require('copy_migrations', [tasks_path.to_s])
    Rake::Task.define_task(:environment)

    # Re-enable the task to allow multiple invocations in the same spec run
    task.reenable
    destination_path
  end

  after { FileUtils.rm_rf(destination_path) }

  it 'skips the copy to the project default location' do
    expect { task.invoke }.to output(/Skipping migration/).to_stdout
  end

  it 'copies migrations to an empty custom destination' do
    expect { task.invoke(destination_path.to_s) }.to output(/Created migration/).to_stdout
    migration_file = Dir.glob("#{destination_path}/*_add_apache_age.rb").first
    migration_contents = File.read(migration_file)

    # within up method
    expect(migration_contents).to include('CREATE EXTENSION IF NOT EXISTS age;')
    expect(migration_contents).to include("LOAD 'age';")
    expect(migration_contents).to include('SET search_path = ag_catalog, "$user", public;')
    expect(migration_contents).to include("SELECT create_graph('age_schema');")

    # within down method
    expect(migration_contents).to include("SELECT drop_graph('age_schema', true);")
    expect(migration_contents).to include('DROP SCHEMA IF EXISTS ag_catalog CASCADE;')
    expect(migration_contents).to include('DROP EXTENSION IF EXISTS age;')
  end

  it 'skips the migrations that already exist' do
    # Copy a migration from the source to the destination
    base_name = 'add_apache_age'
    migration_version = Time.now.utc.strftime("%Y%m%d%H%M%S")
    file_version = migration_version.delete('_')
    new_filename = "#{file_version}_#{base_name}.rb"
    destination_file = File.join(destination_path, new_filename)
    FileUtils.touch(destination_file)

    expect { task.invoke(destination_path.to_s) }.to output(/Skipping migration/).to_stdout
  end
end
