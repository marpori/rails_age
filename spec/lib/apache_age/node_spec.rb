# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::Node do
  subject { described_class.cypher(node_class:) }

  let(:node_class) { Person }

  let(:betty) { Person.create(first_name: 'Betty', last_name: 'Rubble', gender: 'female') }
  let(:barney) { Person.create(first_name: 'Barney', last_name: 'Rubble', gender: 'male') }
  let(:pebbles) { Person.create(first_name: 'Pebbles', last_name: 'Flintstone', gender: 'female') }
  let(:bamm_bamm) { Person.create(first_name: 'Bamm Bamm', last_name: 'Rubble', gender: 'male') }
  let(:roxie) { Person.create(first_name: 'Roxie', last_name: 'Rubble', gender: 'female') }
  let(:chip) { Person.create(first_name: 'Chip', last_name: 'Rubble', gender: 'male') }

  let(:bettys_son) {
    HasChild.create(start_node: betty, guardian_role: 'Mother', end_node: bamm_bamm, child_role: 'son')
  }
  let(:barneys_son) {
    HasChild.create(start_node: barney, guardian_role: 'Father', end_node: bamm_bamm, child_role: 'son')
  }

  let(:pebbles_daughter) {
    HasChild.create(guardian_role: 'mother', start_node: pebbles, end_node: roxie, child_role: 'dauhter')
  }

  let(:bamm_bamms_daughter) {
    HasChild.create(guardian_role: 'father', start_node: bamm_bamm, end_node: roxie, child_role: 'dauhter')
  }

  let(:pebbles_son) {
    HasChild.create(guardian_role: 'mother', start_node: pebbles, end_node: chip, child_role: 'son')
  }

  let(:bamm_bamms_son) {
    HasChild.create(guardian_role: 'father', start_node: bamm_bamm, end_node: chip, child_role: 'son')
  }

  before do
    class Person
      include ApacheAge::Entities::Node

      attribute :first_name, :string
      attribute :last_name, :string
      attribute :gender, :string
    end

    class HasChild
      include ApacheAge::Entities::Edge

      attribute :child_role, :string
      attribute :guardian_role, :string
      attribute :start_node
      attribute :end_node
      # should ideally be :person, but to complex to add `config/initializers/types.rb` to the tests
      # attribute :start_node, :person
      # attribute :end_node, :person
    end

    # Person nodes
    betty
    barney
    bamm_bamm
    pebbles
    roxie
    chip

    # HasChild edges
    bettys_son
    barneys_son
    pebbles_daughter
    bamm_bamms_daughter
    pebbles_son
    bamm_bamms_son
  end

  after do
    Object.send(:remove_const, :Person) if Person.constants.empty?
    Object.send(:remove_const, :HasChild) if Object.const_defined?(:HasChild) && HasChild.constants.empty?
  end

  describe '.all' do
    it 'returns all nodes across different node classes' do
      # Test that calling all on the base Node class returns nodes from all subclasses
      all_nodes = ApacheAge::Node.all

      # Should find all Person nodes we created in before block
      expect(all_nodes).not_to be_empty
      expect(all_nodes.map(&:class).uniq).to include(Person)

      # Should find at least as many nodes as we have Person instances
      expect(all_nodes.size).to be >= Person.all.size

      # Verify contents include the nodes we explicitly created
      expect(all_nodes.map(&:to_rich_h).map { |h| h[:properties][:first_name] }).to include('Betty', 'Barney')
    end
  end

  describe 'HasChild edge persistence' do
    # Create edge directly with print statements
    it 'can create and retrieve edges' do
      # Create nodes and edge
      mom = Person.create(first_name: 'Test', last_name: 'Mother', gender: 'female')
      child = Person.create(first_name: 'Test', last_name: 'Child', gender: 'male')

      # Create edge with debugging
      edge = HasChild.new(
        start_node: mom,
        end_node: child,
        guardian_role: 'Mother',
        child_role: 'son'
      )

      # Save edge
      edge.save

      # Try to find the edge
      if edge.id
        found = HasChild.find(edge.id)
      end

      # Test all query
      all_edges = HasChild.all

      # Verify this works like our edge_spec test
      expect(edge.id).not_to be_nil
      expect(all_edges).not_to be_empty
    end
  end

  describe '.where' do
    let(:query) { subject.where(first_name: 'Barney') }
    let(:expected_sql) {
      "SELECT * FROM cypher('age_schema', $$ " \
        "MATCH (find:Person) " \
        "WHERE find.first_name = 'Barney' " \
        "RETURN find $$) AS (find agtype);"
    }

    it do
      expect(query.all.count).to eq(1)
      expect(query.to_sql).to eq(expected_sql)
    end
  end

  describe '.limit' do
    let(:query) { subject.limit(2) }
    let(:expected_sql) {
      "SELECT * FROM cypher('age_schema', $$ " \
        "MATCH (find:Person) " \
        "RETURN find LIMIT 2 $$) AS (find agtype);"
    }

    it do
      expect(query.to_sql).to eq(expected_sql)
      expect(query.all.count).to eq(2)
    end
  end

  # do not do paths in node queries - results are too complex, use path queries instead
  # describe '.match' do
  #   # add test
  # end

  # HasChild edges (we have 6 individual edges - some are linked together so the total number of paths is 10)
  describe '.all' do
    let(:path_edge) { HasChild }

    it do
      expect(subject.all).to be_an_instance_of(Array)
      expect(subject.all.count).to eq(6)
    end
  end
end
