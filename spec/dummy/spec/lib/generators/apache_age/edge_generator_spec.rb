require 'rails/generators'
require_relative "#{Rails.root}/../../lib/generators/apache_age/edge/edge_generator"

RSpec.describe ApacheAge::EdgeGenerator, type: :generator do
  let(:edge_name) { "TestEdge"}
  let(:destination_root) { Rails.root.to_s }
  let(:types_config_path) { "#{destination_root}/config/initializers/types.rb" }
  let(:expected_edge_path) { "#{destination_root}/app/edges/#{edge_name.underscore}.rb" }
  let(:config) { {behavior:, destination_root:} }
  let(:args) { [edge_name, "employee_role", "begin_date:date"] }
  let(:expected_edge_content) {
    <<~EDGE_FILE
    class #{edge_name.split('/').join('::')}
      include ApacheAge::Entities::Edge

      attribute :employee_role, :string
      attribute :begin_date, :date
      # recommendation for (start_node and end_node): change `:vertex` with the 'node' type
      # see `config/initializers/apache_age.rb` for the list of available node types
      attribute :start_node, :vertex
      attribute :end_node, :vertex

      validates :employee_role, presence: true
      validates :begin_date, presence: true
      validates :start_node, presence: true
      validates :end_node, presence: true

      validate :validate_unique_edge

      private

      # custom unique edge validator (remove any attributes that are NOT important to uniqueness)
      def validate_unique_edge
        ApacheAge::Validators::UniqueEdge
          .new(attributes: [:employee_role, :begin_date, :start_node, :end_node])
          .validate(self)
      end
    end
    EDGE_FILE
  }

  before { described_class.start([edge_name], {behavior: :revoke, destination_root:}) }
  after { described_class.start([edge_name], {behavior: :revoke, destination_root:}) }

  context 'when using invoke' do
    let(:behavior) { :invoke }

    context 'without namespace' do
      let(:edge_name) { "TestEdge"}

      it "inserts correct name and date" do
        described_class.start(args, config)

        expect(File.exist?(expected_edge_path)).to be true
        edge_content = File.read(expected_edge_path)
        expect(edge_content).to eq(expected_edge_content)

        # type_content = File.read(types_config_path)
        # expect(type_content)
        #   .to include("require_dependency 'test_edge'")
        # expect(type_content)
        #   .to include(":test_node, ApacheAge::Types::AgeTypeGenerator.create_type_for(TestEdge)")

        # ensure destroy works
        described_class.start([edge_name], {behavior: :revoke, destination_root:})
        expect(File.exist?(expected_edge_path)).to be false

        # type_content = File.read(types_config_path)
        # expect(type_content)
        #   .not_to include("require_dependency 'test_edge'")
        # expect(type_content)
        #   .not_to include(":test_edge, ApacheAge::Types::AgeTypeGenerator.create_type_for(TestEdge)")
      end
    end

    context 'with a namespace' do
      let(:edge_name) { "Tests/TestEdge"}

      it "inserts correct name and date" do
        described_class.start(args, config)
        expect(File.exist?(expected_edge_path)).to be true

        # Compare the file content to the expected content
        file_content = File.read(expected_edge_path)
        expect(file_content).to eq(expected_edge_content)

        # type_content = File.read(types_config_path)
        # expect(type_content)
        #   .to include("require_dependency 'tests/test_edge'")
        # expect(type_content)
        #   .to include(
        #     ":tests_test_node, ApacheAge::Types::AgeTypeGenerator.create_type_for(Tests::TestNode)"
        #   )

        # ensure destroy works
        described_class.start([edge_name], {behavior: :revoke, destination_root:})
        expect(File.exist?(expected_edge_path)).to be false

        # type_content = File.read(types_config_path)
        # expect(type_content)
        #   .not_to include("require_dependency 'tests/test_node'")
        # expect(type_content)
        #   .not_to include(
        #     ":tests_test_node, ApacheAge::Types::AgeTypeGenerator.create_type_for(Tests::TestEdge)"
        #   )
      end
    end
  end
end
