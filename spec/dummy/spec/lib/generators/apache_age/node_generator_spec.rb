require 'rails/generators'
require_relative "#{Rails.root}/../../lib/generators/apache_age/node/node_generator"

RSpec.describe ApacheAge::NodeGenerator, type: :generator do
  let(:node_name) { "TestNode"}
  let(:destination_root) { Rails.root.to_s }
  let(:expected_path) { "#{destination_root}/app/nodes/#{node_name.underscore}.rb" }
  let(:config) { {behavior:, destination_root:} }
  let(:args) { [node_name, "name", "age:integer"] }

  let(:expected_content) {
  <<~NODEFILE
  class #{node_name.split('/').join('::')}
    include ApacheAge::Entities::Vertex

    attribute :name, :string
    attribute :age, :integer

    validates :name, presence: true
    validates :age, presence: true

    # unique node validator (remove any attributes that are not important to uniqueness)
    validates_with(
      ApacheAge::Validators::UniqueVertexValidator,
      attributes: [:name, :age]
    )
  end
  NODEFILE
  }

  after { described_class.start([node_name], {behavior: :revoke, destination_root:}) }

  context 'when using invoke' do
    let(:behavior) { :invoke }

    context 'without namespace' do
      let(:node_name) { "TestNode"}

      it "inserts correct name and date" do
        described_class.start(args, config)

        expect(File.exist?(expected_path)).to be true

        # Read the file content
        file_content = File.read(expected_path)

        # Compare the file content to the expected content
        expect(file_content).to eq(expected_content)

        File.delete(expected_path)
        expect(File.exist?(expected_path)).to be false
      end
    end

    context 'with a namespace' do
      let(:node_name) { "Test/TestNode"}

      it "inserts correct name and date" do
        described_class.start(args, config)
        expect(File.exist?(expected_path)).to be true

        # Compare the file content to the expected content
        file_content = File.read(expected_path)
        expect(file_content).to eq(expected_content)

        File.delete(expected_path)
        expect(File.exist?(expected_path)).to be false
      end
    end
  end

  context 'when using revoke' do
    let(:behavior) { :revoke }

    it "removes the node file" do
      # Ensure the file is created first
      File.new(expected_path, 'w')
      expect(File.exist?(expected_path)).to be true

      # Now test the revoke behavior deletes the file
      described_class.start([node_name], config)
      expect(File.exist?(expected_path)).to be false
    end
  end
end
