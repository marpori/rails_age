# spec/tasks/override_db_migrate_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'apache_age:override_db_migrate', type: :task do
  let(:destination_path) { Dir.mktmpdir }
  let(:bin_rails_path) { File.join(destination_path, 'bin/rails') }
  let(:task_name) { 'apache_age:override_db_migrate' }
  let(:original_content) { "#!/usr/bin/env ruby\nputs 'Hello, Rails!'\n" }
  let(:capture_rails_cmd) do
    <<~RUBY
      rails_cmd = ARGV.first # must be first (otherwise consumed by rails:commands)
    RUBY
  end
  let(:override_migrate) do
    <<~RUBY

      # ensure db:migrate is followed with: `Rake::Task["apache_age:config_schema"].invoke`
      # to the schema.rb file after the migration mangles it
      if rails_cmd == 'db:migrate'
        require 'rake'
        Rails.application.load_tasks
        Rake::Task['db:migrate'].invoke
        Rake::Task["apache_age:config_schema"].invoke
      end
    RUBY
  end

  before do
    # Create a temporary bin/rails file with original_content
    FileUtils.mkdir_p(File.dirname(bin_rails_path))
    File.write(bin_rails_path, original_content)

    # Re-enable the task to allow multiple invocations in the same spec run
    Rake::Task[task_name].reenable
  end

  after do
    # Clean up the temporary bin/rails file
    FileUtils.rm_rf(destination_path)
  end

  it 'adds the rails_cmd capture code to bin/rails' do
    Rake::Task[task_name].invoke(destination_path)
    content = File.read(bin_rails_path)
    expect(content).to include(capture_rails_cmd.strip)
  end

  it 'adds the migration hook to bin/rails' do
    Rake::Task[task_name].invoke(destination_path)
    content = File.read(bin_rails_path)
    expect(content).to include(override_migrate.strip)
  end

  it 'does not duplicate existing rails_cmd capture code' do
    Rake::Task[task_name].invoke(destination_path)
    Rake::Task[task_name].invoke(destination_path)
    content = File.read(bin_rails_path)
    expect(content.scan(capture_rails_cmd.strip).size).to eq(1)
  end

  it 'does not duplicate existing migration hook' do
    Rake::Task[task_name].invoke(destination_path)
    Rake::Task[task_name].invoke(destination_path)
    content = File.read(bin_rails_path)
    expect(content.scan(override_migrate.strip).size).to eq(1)
  end

  it 'does not modify the file if hooks are already present' do
    Rake::Task[task_name].invoke(destination_path)
    content_after_first_invoke = File.read(bin_rails_path)
    Rake::Task[task_name].invoke(destination_path)
    content_after_second_invoke = File.read(bin_rails_path)
    expect(content_after_first_invoke).to eq(content_after_second_invoke)
  end
end
