# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::Path do
  subject { described_class.cypher(path_edge:, path_length:, path_properties:) }

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
      attribute :start_node, :person
      attribute :end_node, :person
    end
  end

  after do
    Object.send(:remove_const, :Person) if Person.constants.empty?
    Object.send(:remove_const, :HasChild)  if HasChild.constants.empty?
  end

  let(:path_edge) { nil }
  let(:path_length) { nil }
  let(:path_properties) { nil }
  let(:barney) { Person.create(first_name: 'Barney', last_name: 'Rubble', gender: 'male') }
  let(:bamm_bamm) { Person.create(first_name: 'Bamm Bamm', last_name: 'Rubble', gender: 'male') }
  let(:barneys_child) {
    HasChild.create(start_node: barney, guardian_role: 'Father', end_node: bamm_bamm, child_role: 'son')
  }

  describe '.new' do
    context 'with edge_path inputs' do
      context 'when an edge_path is valid' do
        let(:path_edge) { HasChild }
        let(:expected_sql) {
          "SELECT * FROM cypher('age_schema', $$ " \
            "MATCH path = (start_node)-[HasChild*]->(end_node) " \
            "RETURN path $$) AS (path agtype);"
        }

        it { expect(subject.to_sql).to eq(expected_sql) }
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
  end

  describe '.match' do
  end

  describe '.all' do
    let(:path_edge) { HasChild }

    before do
      barney
      bamm_bamm
      barneys_child
    end

    it { expect(subject.all).to be_an_instance_of(Array) }
    xit { expect(subject.all.size).to eq(1) }
    xit { expect(subject.all.first.to_h).to eq(barney.to_h) }
    xit { expect(subject.all.second.to_h).to eq(barneys_cild.to_h) }
    xit { expect(subject.all.last.to_h).to eq(bamm_bamm.to_h) }
  end
end
