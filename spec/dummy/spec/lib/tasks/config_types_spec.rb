# spec/dummy/lib/tasks/config_types_spec.rb
require 'rails_helper'
require 'rake'

# Load the Rake tasks
Rails.application.load_tasks

RSpec.describe 'apache_age:config_types' do
  let(:task_name) { 'apache_age:config_types' }
  let(:types_file_path) { Rails.root.join('config', 'initializers', 'types.rb').to_s }
  let(:required_file_content) { "require 'apache_age/types/age_type_generator'" }
  let(:node_type_content) do
<<-RUBY
  require_dependency 'apache_age/node'
  ActiveModel::Type.register(
    :node, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Node)
  )
RUBY
  end
  let(:edge_type_content) do
<<-RUBY
  require_dependency 'apache_age/edge'
  ActiveModel::Type.register(
    :edge, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Edge)
  )
RUBY
  end
  let(:initial_content) {
    <<~RUBY
    # config/initializers/types.rb
    Rails.application.config.to_prepare do
    end
    RUBY
  }

  before do
    allow(File).to receive(:exist?).with("#{Rails.root}/config/environment.rb").and_return(true)
    allow(File).to receive(:exist?).with(types_file_path).and_return(file_exists)
    allow(File).to receive(:read).with(types_file_path).and_return(file_content)
    allow(File).to receive(:open).with(types_file_path, 'w').and_yield(double('file', write: nil))

    Rake::Task[task_name].reenable
  end

  context 'when the file does not exist' do
    let(:file_exists) { false }
    let(:file_content) { '' }

    it 'creates the config file with the correct content' do
      expect(File).to receive(:open).with(types_file_path, 'w') do |_, _, &block|
        file_mock = double('file')
        expect(file_mock).to receive(:write) do |content|
          expect(content).to include(required_file_content)
          expect(content).to include(node_type_content)
          expect(content).to include(edge_type_content)
        end
        block.call(file_mock)
      end

      Rake::Task[task_name].invoke
    end
  end

  context 'when the file already exists' do
    let(:file_exists) { true }
    let(:file_content) { initial_content }

    it 'adds the required file path if it does not exist' do
      expect(File).to receive(:open).with(types_file_path, 'w') do |_, _, &block|
        file_mock = double('file')
        expect(file_mock).to receive(:write) do |content|
          expect(content).to include(required_file_content)
        end
        block.call(file_mock)
      end

      Rake::Task[task_name].invoke
    end

    it 'adds the node type content if it does not exist' do
      expect(File).to receive(:open).with(types_file_path, 'w') do |_, _, &block|
        file_mock = double('file')
        expect(file_mock).to receive(:write) do |content|
          expect(content).to include(node_type_content)
        end
        block.call(file_mock)
      end

      Rake::Task[task_name].invoke
    end

    it 'adds the edge type content if it does not exist' do
      expect(File).to receive(:open).with(types_file_path, 'w') do |_, _, &block|
        file_mock = double('file')
        expect(file_mock).to receive(:write) do |content|
          expect(content).to include(edge_type_content)
        end
        block.call(file_mock)
      end

      Rake::Task[task_name].invoke
    end

    it 'does not duplicate the required file path or type content' do
      Rake::Task[task_name].invoke

      expect(File).not_to receive(:open).with(types_file_path, 'w')
      Rake::Task[task_name].reenable
      Rake::Task[task_name].invoke
    end
  end
end
