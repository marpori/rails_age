# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::Entities::Edge do
  context 'with minimal namespacing' do
    let(:bamm) { Nodes::CavePerson.new(name: 'Bamm-Bamm Rubble') }
    let(:pebbles) { Nodes::CavePerson.create(name: 'Pebbles Flintstone') }

    before do
      module Nodes
        class CavePerson
          include ApacheAge::Entities::Node

          attribute :name, :string

          validates :name, presence: true
        end
      end

      module Edges
        class MarriedTo
          include ApacheAge::Entities::Edge

          attribute :role, :string
          attribute :since_year, :integer

          validates :role, :since_year, presence: true
        end
      end
    end

    after do
      # Remove the Nodes::Person class
      Nodes.send(:remove_const, :CavePerson)
      # Remove the Nodes::Person class
      Edges.send(:remove_const, :MarriedTo)

      # Optionally remove the Nodes module if it's no longer needed
      Object.send(:remove_const, :Nodes) if Nodes.constants.empty?
      # Optionally remove the Nodes module if it's no longer needed
      Object.send(:remove_const, :Edges) if Edges.constants.empty?
    end

    context 'with incomplete attributes' do
      subject { Edges::MarriedTo.new(start_node: bamm, since_year: 1963) }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:role]).to include("can't be blank")
        # expect(subject.errors.messages[:end_id]).to include("can't be blank")
        expect(subject.errors.messages[:end_node]).to include("can't be blank")
      end
    end

    context 'with invalid nodes' do
      subject { Edges::MarriedTo.new(start_node: bamm, end_node: pebbles, since_year: 1963, role: 'husband') }

      let(:bamm) { Nodes::CavePerson.new() }
      let(:pebbles) {
        pebbles = Nodes::CavePerson.create(name: 'Pebbles Flintstone')
        pebbles.name = ''
        pebbles
      }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:start_node]).to include("invalid")
        expect(subject.errors.messages[:end_node]).to include("invalid")
      end
    end

    context '.create' do
      subject { Edges::MarriedTo.create(start_node: bamm, end_node: pebbles, since_year: 1963, role: 'husband') }

      let(:bamm) { Nodes::CavePerson.create(name: 'Bamm-Bamm Rubble') }
      let(:pebbles) { Nodes::CavePerson.create(name: 'Pebbles Flintstone') }

      it { expect(subject.age_type).to eq('edge') }
      it { expect(subject.role).to eq('husband') }
      it { expect(subject.since_year).to eq(1963) }

      # Check if edge is persisted with ID
      it { expect(subject.id).not_to be_nil }
      it { expect(subject).to be_persisted }
    end

    context 'persistence and retrieval' do
      let(:bamm) { Nodes::CavePerson.create(name: 'Bamm-Bamm Rubble') }
      let(:pebbles) { Nodes::CavePerson.create(name: 'Pebbles Flintstone') }

      before do
        # Create an edge to test retrieval
        @edge = Edges::MarriedTo.create(
          start_node: bamm,
          end_node: pebbles,
          since_year: 1963,
          role: 'husband'
        )
      end

      it 'returns the edge when finding by id' do
        found = Edges::MarriedTo.find(@edge.id)
        expect(found).not_to be_nil
        expect(found.id).to eq(@edge.id)
        expect(found.role).to eq('husband')
      end

      it 'returns the edge when using find_by' do
        found = Edges::MarriedTo.find_by(role: 'husband')
        expect(found).not_to be_nil
        expect(found.id).to eq(@edge.id)
      end

      it 'returns the edge when using all' do
        all_edges = Edges::MarriedTo.all
        expect(all_edges).to include(an_object_having_attributes(id: @edge.id))
      end

      it 'returns the edge when querying by start node' do
        found = Edges::MarriedTo.find_by(start_node: bamm)
        expect(found).not_to be_nil
        expect(found.id).to eq(@edge.id)
      end

      it 'has a valid id' do
        expect(@edge.id).to be_present
      end

      it 'is persisted' do
        expect(@edge).to be_persisted
      end

      it 'has the correct end node' do
        expect(@edge.end_node.id).to eq(pebbles.id)
      end

      it 'has the correct start node' do
        expect(@edge.start_node.id).to eq(bamm.id)
      end

      it 'has the correct end class' do
        expect(@edge.end_class).to eq(Nodes::CavePerson)
      end

      it 'has the correct start class' do
        expect(@edge.start_class).to eq(Nodes::CavePerson)
      end
    end

    context '.new' do
      subject { Edges::MarriedTo.new(start_node: bamm, end_node: pebbles, since_year: 1963, role: 'husband') }

      it { expect(subject).to be_valid }
      it { expect(subject.age_type).to eq('edge') }
      it { expect(subject.since_year).to eq(1963) }
      it { expect(subject.role).to eq('husband') }
      it { expect(subject.start_node).to eq(bamm) }
      it { expect(subject.end_node).to eq(pebbles) }
      it { expect(subject.end_class).to eq(Nodes::CavePerson) }
      it { expect(subject.start_class).to eq(Nodes::CavePerson) }
    end
  end

  context 'node definition within a module namespace' do
    let(:bamm) { Flintstones::Nodes::CavePerson.new(name: 'Bamm-Bamm Rubble') }
    let(:pebbles) { Flintstones::Nodes::CavePerson.create(name: 'Pebbles Flintstone') }

    before do
      module Flintstones
        module Nodes
          class CavePerson
            include ApacheAge::Entities::Node
            attribute :name, :string
            validates :name, presence: true
          end
        end

        module Edges
          class MarriedTo
            include ApacheAge::Entities::Edge
            attribute :role, :string
            attribute :since_year, :integer
            validates :role, :since_year, presence: true
          end
        end
      end
    end

    after do
      # Remove the Nodes::Person class
      Flintstones::Nodes.send(:remove_const, :CavePerson)
      # Remove the Nodes::Person class
      Flintstones::Edges.send(:remove_const, :MarriedTo)

      # Optionally remove the Nodes module if it's no longer needed
      Object.send(:remove_const, :Nodes) if Nodes.constants.empty?
      # Optionally remove the Nodes module if it's no longer needed
      Object.send(:remove_const, :Edges) if Edges.constants.empty?
      # Optionally remove the Nodes module if it's no longer needed
      Object.send(:remove_const, :Flintstones) if Flintstones.constants.empty?
    end

    context 'with incomplete attributes' do
      subject { Flintstones::Edges::MarriedTo.new(start_node: bamm, since_year: 1963) }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:role]).to include("can't be blank")
        # expect(subject.errors.messages[:end_id]).to include("can't be blank")
        expect(subject.errors.messages[:end_node]).to include("can't be blank")
      end
    end

    context '.create' do
      subject do
        Flintstones::Edges::MarriedTo.create(start_node: bamm, end_node: pebbles, since_year: 1963, role: 'husband')
      end

      let(:bamm) { Flintstones::Nodes::CavePerson.create(name: 'Bamm-Bamm Rubble') }
      let(:pebbles) { Flintstones::Nodes::CavePerson.create(name: 'Pebbles Flintstone') }

      it { expect(subject.age_type).to eq('edge') }
      it { expect(subject.role).to eq('husband') }
      it { expect(subject.since_year).to eq(1963) }
      it { expect(subject.id).to be_present }
      it { expect(subject).to be_persisted }
    end

    context '.new' do
      subject do
        Flintstones::Edges::MarriedTo.new(start_node: bamm, end_node: pebbles, since_year: 1963, role: 'husband')
      end

      it { expect(subject).to be_valid }
      it { expect(subject.age_type).to eq('edge') }
      it { expect(subject.since_year).to eq(1963) }
      it { expect(subject.role).to eq('husband') }
      it { expect(subject.start_node).to eq(bamm) }
      it { expect(subject.end_node).to eq(pebbles) }
    end
  end
end
