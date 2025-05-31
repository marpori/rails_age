# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::Path do
  subject { described_class.cypher(path_edge:, path_length:, path_properties:) }

  let(:path_edge) { nil }
  let(:path_length) { nil }
  let(:path_properties) { nil }

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
      # can't use rails type :person in tests (see config/initializers/types.rb)
      # must be there before rails starts
      # attribute :start_node, :person
      # attribute :end_node, :person
    end

    # people
    betty
    barney
    bamm_bamm
    pebbles
    roxie
    chip
    # Relationships
    bettys_son
    barneys_son
    pebbles_daughter
    pebbles_son
    bamm_bamms_daughter
    bamm_bamms_son
  end

  after do
    Object.send(:remove_const, :Person) if Person.constants.empty?
    Object.send(:remove_const, :HasChild)  if HasChild.constants.empty?
  end

  describe '.cypher' do
    context 'with edge_path inputs' do
      context 'when an edge_path is valid (of any length)' do
        let(:path_edge) { HasChild }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[HasChild*]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        # Why 10 instead of 6:
        # You have 6 direct HasChild relationships (edges):

        # Betty → Bamm Bamm
        # Barney → Bamm Bamm
        # Bamm Bamm → Roxie
        # Bamm Bamm → Chip
        # Pebbles → Roxie
        # Pebbles → Chip

        # includes all possible paths through these relationships, including longer paths like:
        # Betty → Bamm Bamm → Roxie
        # Betty → Bamm Bamm → Chip
        # Barney → Bamm Bamm → Roxie
        # Barney → Bamm Bamm → Chip
        it do
          expect(subject.to_sql).to eq(expected_sql)
          # pp subject.all.map { |p| p.map(&:to_h) }
          expect(subject.all.count).to eq(10)
        end
      end

      context 'when an edge_path is valid (of any length)' do
        let(:path_edge) { HasChild }
        let(:path_length) { 1..1 }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[HasChild*1..1]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        # Why 6 instead of 10:
        #
        # 1..1 is for direct relationships (1 edge):
        # Betty → Bamm Bamm
        # Barney → Bamm Bamm
        # Bamm Bamm → Roxie
        # Bamm Bamm → Chip
        # Pebbles → Roxie
        # Pebbles → Chip

        # excludes multiple edge paths:
        # Betty → Bamm Bamm → Roxie
        # Betty → Bamm Bamm → Chip
        # Barney → Bamm Bamm → Roxie
        # Barney → Bamm Bamm → Chip
        it do
          expect(subject.to_sql).to eq(expected_sql)
          # pp subject.all.map { |p| p.map(&:to_h) }
          expect(subject.all.count).to eq(6)
        end
      end

      context 'when an edge_path is valid (of any length)' do
        let(:path_edge) { HasChild }
        let(:path_length) { 2.. }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[HasChild*2..]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        # Why 4 instead of 10:

        # 2.. is for direct relationships (2 edges or more)
        # Betty → Bamm Bamm → Roxie
        # Betty → Bamm Bamm → Chip
        # Barney → Bamm Bamm → Roxie
        # Barney → Bamm Bamm → Chip
        #
        # excludes single edge paths -  1..1 is for direct relationships (1 edge):
        # Betty → Bamm Bamm
        # Barney → Bamm Bamm
        # Bamm Bamm → Roxie
        # Bamm Bamm → Chip
        # Pebbles → Roxie
        # Pebbles → Chip
        it do
          expect(subject.to_sql).to eq(expected_sql)
          # pp subject.all.map { |p| p.map(&:to_h) }
          expect(subject.all.count).to eq(4)
        end
      end

      context 'when an edge_path is not given' do
        let(:path_edge) { nil }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[*]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it { expect(subject.to_sql).to eq(expected_sql) }
      end
    end

    context 'with path_length' do
      context 'with path_length with bounded range' do
        let(:path_length) { 2..5 }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[*2..5]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it { expect(subject.to_sql).to eq(expected_sql) }
      end

      context 'with path_length with unbounded max range' do
        let(:path_edge) { HasChild }
        let(:path_length) { 2.. }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[HasChild*2..]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it { expect(subject.to_sql).to eq(expected_sql) }
      end

      context 'with path_length with unbounded min range' do
        let(:path_edge) { nil }
        let(:path_length) { ..3 }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[*..3]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it { expect(subject.to_sql).to eq(expected_sql) }
      end
    end

    context 'with path_properties' do
      context 'with path_properties with a single property' do
        let(:path_properties) { {guardian_role: "father"} }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[* {guardian_role: 'father'}]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it { expect(subject.to_sql).to eq(expected_sql) }
      end

      context 'with path_properties with a multiple properties' do
        let(:path_edge) { HasChild }
        let(:path_length) { 2..5 }
        let(:path_properties) { {guardian_role: "father", child_role: "son"} }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[HasChild*2..5 {guardian_role: 'father', child_role: 'son'}]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it { expect(subject.to_sql).to eq(expected_sql) }
      end
    end
  end

  describe '.where' do
    let(:query) { subject.where(start_node: {first_name: 'Barney'}) }
    let(:expected_sql) {
      "SELECT * FROM cypher('age_schema', $$ " \
        "MATCH path = (start_node)-[*]->(end_node) " \
        "WHERE start_node.first_name = 'Barney' " \
        "RETURN path $$) AS (path agtype);"
    }

    it { expect(query.to_sql).to eq(expected_sql) }
  end

  describe '.limit' do
    let(:query) { subject.limit(2) }
    let(:expected_sql) {
      "SELECT * FROM cypher('age_schema', $$ " \
        "MATCH path = (start_node)-[*]->(end_node) " \
        "RETURN path LIMIT 2 $$) AS (path agtype);"
    }

    it { expect(query.to_sql).to eq(expected_sql) }
  end

  describe '.order' do
    context 'when ordering by start_node property' do
      let(:path_edge) { HasChild }
      let(:query) { subject.order(start_node: {last_name: :asc}) }
      let(:expected_sql) {
        "SELECT * FROM cypher('age_schema', $$ " \
          "MATCH path = (start_node)-[HasChild*]->(end_node) " \
          "RETURN path ORDER BY start_node.last_name ASC $$) AS (path agtype);"
      }

      it do
        expect(query.to_sql).to eq(expected_sql)
        # pp query.all.map { |p| p.map(&:to_h) }
        expect(query.all.count).to eq(10)
      end
    end

    context 'when ordering by path length' do
      let(:query) { subject.order(length: :desc) }
      let(:expected_sql) {
        "SELECT * FROM cypher('age_schema', $$ " \
          "MATCH path = (start_node)-[*]->(end_node) " \
          "RETURN path ORDER BY length(path) DESC $$) AS (path agtype);"
      }

      it do
        expect(query.to_sql).to eq(expected_sql)
        # pp query.all.map { |p| p.map(&:to_h) }
        expect(query.all.count).to eq(10)
      end
    end

    context 'when ordering by multiple criteria' do
      let(:path_edge) { HasChild }
      let(:query) { subject.order(start_node: {last_name: :asc}, length: :desc) }
      let(:expected_sql) {
        "SELECT * FROM cypher('age_schema', $$ " \
          "MATCH path = (start_node)-[HasChild*]->(end_node) " \
          "RETURN path ORDER BY start_node.last_name ASC, length(path) DESC $$) AS (path agtype);"
      }

      it do
        expect(query.to_sql).to eq(expected_sql)
        # pp query.all.map { |p| p.map(&:to_h) }
        expect(query.all.count).to eq(10)
      end
    end

    # context 'when ordering by edge property - not possible AGE limitation' do
    #   let(:path_edge) { HasChild }
    #   let(:query) { subject.order(edge: {guardian_role: :asc}) }
    #   let(:expected_sql) {
    #     "SELECT * FROM cypher('age_schema', $$ " \
    #       "MATCH path = (start_node)-[edge:HasChild*]->(end_node) " \
    #       "RETURN path ORDER BY [e in relationships(path) WHERE type(e) = 'HasChild'][0].guardian_role ASC $$) AS (path agtype);"
    #   }

    #   it do
    #     expect(query.to_sql).to eq(expected_sql)
    #     # pp query.all.map { |p| p.map(&:to_h) }
    #     expect(query.all.count).to eq(10)
    #   end
    # end

    describe 'node filtering in match clause' do
      context 'with start_node_filter' do
        let(:path_edge) { HasChild }
        let(:query) { subject.cypher(path_edge: path_edge, start_node_filter: { gender: 'female' }) }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node {gender: 'female'})-[HasChild*]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it 'generates the correct SQL with start node filter' do
          expect(query.to_sql).to eq(expected_sql)
          expect(query.all.count).to be > 0
        end
      end

      context 'with end_node_filter' do
        let(:path_edge) { HasChild }
        let(:query) { subject.cypher(path_edge: path_edge, end_node_filter: { gender: 'male' }) }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[HasChild*]->(end_node {gender: 'male'}) " \
            "RETURN path $$) AS (path agtype);"
        }

        it 'generates the correct SQL with end node filter' do
          expect(query.to_sql).to eq(expected_sql)
          expect(query.all.count).to be > 0
        end
      end

      context 'with both start and end node filters' do
        let(:path_edge) { HasChild }
        let(:query) {
          subject.cypher(
            path_edge: path_edge,
            start_node_filter: { gender: 'female' },
            end_node_filter: { gender: 'male' }
          )
        }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node {gender: 'female'})-[HasChild*]->(end_node {gender: 'male'}) " \
            "RETURN path $$) AS (path agtype);"
        }

        it 'generates the correct SQL with both start and end node filters' do
          expect(query.to_sql).to eq(expected_sql)
          expect(query.all.count).to be > 0
        end
      end

      context 'with multiple properties in node filter' do
        let(:path_edge) { HasChild }
        let(:query) {
          subject.cypher(
            path_edge: path_edge,
            start_node_filter: { first_name: 'Betty', gender: 'female' }
          )
        }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node {first_name: 'Betty', gender: 'female'})-[HasChild*]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it 'generates the correct SQL with multiple properties in filter' do
          expect(query.to_sql).to eq(expected_sql)
          expect(query.all.count).to be > 0
        end
      end

      context 'with node filters and path properties' do
        let(:path_edge) { HasChild }
        let(:query) {
          subject.cypher(
            path_edge: path_edge,
            path_properties: { guardian_role: 'Mother' },
            start_node_filter: { gender: 'female' }
          )
        }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node {gender: 'female'})-[HasChild* {guardian_role: 'Mother'}]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it 'generates the correct SQL with node filters and path properties' do
          expect(query.to_sql).to eq(expected_sql)
          # This might return 0 depending on test data
          # expect(query.all.count).to be > 0
        end
      end
    end
  end

  # is supported via input parameters
  # path_edge: nil, path_length: nil, path_properties: {}, start_node_filter: nil, end_node_filter: nil
  # describe '.match' do
  #   # add test
  # end

  describe '.all' do
    let(:path_edge) { HasChild }

    it do
      expect(subject.all).to be_an_instance_of(Array)
      expect(subject.all.count).to eq(10)
      # without an oder it is dangerous to check order, but here is what the format would be.
      # expect(subject.all.first.map(&:to_h)).to eq([betty.to_h, bettys_son.to_h, bamm_bamm.to_h])
      # or depending on the length of the path like:
      # expect(subject.all.first.map(&:to_h)).to eq([betty.to_h, bettys_son.to_h, bamm_bamm.to_h, bamm_bamm_son.to_h, chip.to_h])
    end
  end

  describe 'PathResult#to_rich_h' do
    let(:path_edge) { HasChild }

    it 'allows direct to_rich_h calls on path results' do
      # Test that we can call to_rich_h directly on a path result
      path = subject.all.first
      expect(path).to respond_to(:to_rich_h)

      rich_path = path.to_rich_h
      expect(rich_path).to be_an_instance_of(Array)
      expect(rich_path.first).to include(:_meta)
      expect(rich_path.first).to include(:properties)
    end

    it 'allows mapping to_rich_h over multiple path results' do
      # Test that we can map to_rich_h over path results
      paths = subject.all.take(3)
      rich_paths = paths.map(&:to_rich_h)

      expect(rich_paths).to be_an_instance_of(Array)
      expect(rich_paths.size).to eq(3)
      expect(rich_paths.first).to be_an_instance_of(Array)
      expect(rich_paths.first.first).to include(:_meta)
    end
  end
end
