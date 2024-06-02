# spec/dummy/lib/tasks/install_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'apache_age:install', type: :task do
  let(:engine_root_path) { File.expand_path("#{Rails.root}/../../", __FILE__) }
  let(:tasks_path) { File.expand_path("#{engine_root_path}/lib/tasks", __FILE__) }

  let(:install_task) { Rake::Task['apache_age:install'] }
  let(:copy_migrations_task) { Rake::Task['apache_age:copy_migrations'] }
  let(:schema_config_task) { Rake::Task['apache_age:schema_config'] }
  let(:database_config_task) { Rake::Task['apache_age:database_config'] }
  let(:migrate_task) { Rake::Task['db:migrate'] }

  before do
    # Load the Rails Rake tasks
    Rails.application.load_tasks

    # Load the tasks in your tasks_path
    Rake.application.rake_require('install', [tasks_path])

    # Re-enable the tasks to allow multiple invocations in the same spec run
    install_task.reenable
    copy_migrations_task.reenable
    migrate_task.reenable
    schema_config_task.reenable
    database_config_task.reenable

    # Mock the tasks
    allow(copy_migrations_task).to receive(:invoke)
    allow(migrate_task).to receive(:invoke)
    allow(schema_config_task).to receive(:invoke)
    allow(database_config_task).to receive(:invoke)
  end

  it 'invokes apache_age:copy_migrations' do
    install_task.invoke
    expect(copy_migrations_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes db:migrate' do
    install_task.invoke
    expect(migrate_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes apache_age:schema_config' do
    install_task.invoke
    expect(schema_config_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes apache_age:database_config' do
    install_task.invoke
    expect(database_config_task).to have_received(:invoke).at_least(:once)
  end

  it 'invokes all tasks in sequence' do
    install_task.invoke
    expect(copy_migrations_task).to have_received(:invoke).at_least(:once)
    expect(migrate_task).to have_received(:invoke).at_least(:once)
    expect(schema_config_task).to have_received(:invoke).at_least(:once)
    expect(database_config_task).to have_received(:invoke).at_least(:once)
  end
end