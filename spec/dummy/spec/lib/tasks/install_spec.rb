# spec/dummy/lib/tasks/install_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'apache_age:install', type: :task do
  let(:engine_root_path) { File.expand_path("#{Rails.root}/../../", __FILE__) }
  let(:tasks_path) { File.expand_path("#{engine_root_path}/lib/tasks", __FILE__) }

  let(:install_task) { Rake::Task['apache_age:install'] }
  let(:add_migration_task) { Rake::Task['apache_age:add_age_migration'] }
  let(:config_database_task) { Rake::Task['apache_age:config_database'] }
  let(:config_schema_task) { Rake::Task['apache_age:config_schema'] }
  let(:config_types_task) { Rake::Task['apache_age:config_types'] }
  let(:migrate_task) { Rake::Task['db:migrate'] }

  before do
    # Load the Rails Rake tasks
    Rails.application.load_tasks

    # Load the tasks in your tasks_path
    Rake.application.rake_require('install', [tasks_path])

    # Re-enable the tasks to allow multiple invocations in the same spec run
    install_task.reenable
    add_migration_task.reenable
    migrate_task.reenable
    config_database_task.reenable
    config_schema_task.reenable
    config_types_task.reenable

    # Mock the tasks
    allow(add_migration_task).to receive(:invoke)
    allow(migrate_task).to receive(:invoke)
    allow(config_database_task).to receive(:invoke)
    allow(config_schema_task).to receive(:invoke)
    allow(config_types_task).to receive(:invoke)
  end

  it 'invokes apache_age:add_age_migration' do
    install_task.invoke
    expect(add_migration_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes db:migrate' do
    install_task.invoke
    expect(migrate_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes apache_age:schema_config' do
    install_task.invoke
    expect(config_schema_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes apache_age:database_config' do
    install_task.invoke
    expect(config_database_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes all tasks in sequence' do
    install_task.invoke
    expect(add_migration_task).to have_received(:invoke).at_least(:once)
    expect(migrate_task).to have_received(:invoke).at_least(:once)
    expect(config_schema_task).to have_received(:invoke).at_least(:once)
    expect(config_database_task).to have_received(:invoke).at_least(:once)
  end
end
