require 'rails_helper'
require 'rails/generators'

require_relative "#{Rails.root}/../../lib/generators/apache_age/node/node_generator"

RSpec.describe ApacheAge::NodeGenerator, type: :generator do
  let(:node_name) { "TestNode"}
  let(:destination_root) { Rails.root.to_s }
  let(:types_config_path) { "#{destination_root}/config/initializers/types.rb" }
  let(:expected_node_path) { "#{destination_root}/app/nodes/#{node_name.underscore}.rb" }
  let(:config) { {behavior:, destination_root:} }
  let(:args) { [node_name, "name", "age:integer"] }
  let(:expected_node_content) {
    <<~NODE_FILE
    class #{node_name.split('/').join('::')}
      include ApacheAge::Entities::Vertex

      attribute :name, :string
      attribute :age, :integer

      validates :name, presence: true
      validates :age, presence: true

      # custom unique node validator (remove any attributes that are NOT important to uniqueness)
      validates_with(
        ApacheAge::Validators::UniqueVertex,
        attributes: [:name, :age]
      )
    end
    NODE_FILE
  }

  before { described_class.start([node_name], {behavior: :revoke, destination_root:}) }
  after { described_class.start([node_name], {behavior: :revoke, destination_root:}) }

  context 'when using invoke' do
    let(:behavior) { :invoke }

    context 'without namespace' do
      let(:node_name) { "TestNode"}

      it "inserts correct name and date" do
        described_class.start(args, config)

        expect(File.exist?(expected_node_path)).to be true
        node_content = File.read(expected_node_path)
        expect(node_content).to eq(expected_node_content)
        type_content = File.read(types_config_path)
        expect(type_content)
          .to include("require_dependency 'test_node'")
        expect(type_content)
          .to include(":test_node, ApacheAge::Types::AgeTypeGenerator.create_type_for(TestNode)")

        # ensure destroy works
        described_class.start([node_name], {behavior: :revoke, destination_root:})
        expect(File.exist?(expected_node_path)).to be false
        type_content = File.read(types_config_path)
        expect(type_content)
          .not_to include("require_dependency 'test_node'")
        expect(type_content)
          .not_to include(":test_node, ApacheAge::Types::AgeTypeGenerator.create_type_for(TestNode)")
      end
    end

    context 'with a namespace' do
      let(:node_name) { "Tests/TestNode"}

      it "inserts correct name and date" do
        described_class.start(args, config)
        expect(File.exist?(expected_node_path)).to be true

        # Compare the file content to the expected content
        file_content = File.read(expected_node_path)
        expect(file_content).to eq(expected_node_content)
        type_content = File.read(types_config_path)
        expect(type_content)
          .to include("require_dependency 'tests/test_node'")
        expect(type_content)
          .to include(
            ":tests_test_node, ApacheAge::Types::AgeTypeGenerator.create_type_for(Tests::TestNode)"
          )

        # ensure destroy works
        described_class.start([node_name], {behavior: :revoke, destination_root:})
        expect(File.exist?(expected_node_path)).to be false
        type_content = File.read(types_config_path)
        expect(type_content)
          .not_to include("require_dependency 'tests/test_node'")
        expect(type_content)
          .not_to include(
            ":tests_test_node, ApacheAge::Types::AgeTypeGenerator.create_type_for(Tests::TestNode)"
          )
      end
    end
  end
end
