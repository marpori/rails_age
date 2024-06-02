# spec/tasks/install_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'apache_age:copy_migrations', type: :task do
  let(:engine_root_path) { File.expand_path("#{Rails.root}/../../", __FILE__) }
  let(:source_path) { File.expand_path("#{engine_root_path}/db/migrate", __FILE__) }
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
    expect { task.invoke }.to output(/Skipping migration:/).to_stdout
  end

  it 'copies migrations to an empty custom destination' do
    expect { task.invoke(destination_path.to_s) }.to output(/Created migration:/).to_stdout
  end

  it 'skips the migrations that already exist' do
    # Copy a migration from the source to the destination
    source_file = Dir.glob("#{source_path}/*.rb").first
    destination_file = File.join(destination_path, File.basename(source_file))
    FileUtils.cp(source_file, destination_file)

    expect { task.invoke(destination_path.to_s) }.to output(/Skipping migration:/).to_stdout
  end
end
