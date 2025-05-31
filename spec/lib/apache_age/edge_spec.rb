# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::Edge do
  subject { described_class.cypher }

  before do
    # Define test node classes
    class Person
      include ApacheAge::Entities::Node

      attribute :name, :string
    end

    # Define test edge classes
    class HasFriend
      include ApacheAge::Entities::Edge

      attribute :since_year, :integer
      attribute :start_node
      attribute :end_node
    end

    class HasPet
      include ApacheAge::Entities::Edge

      attribute :animal_type, :string
      attribute :start_node
      attribute :end_node
    end

    # Create test nodes
    @alice = Person.create(name: 'Alice')
    @bob = Person.create(name: 'Bob')
    @charlie = Person.create(name: 'Charlie')

    # Create test edges
    @alice_friend = HasFriend.create(start_node: @alice, end_node: @bob, since_year: 2020)
    @bob_friend = HasFriend.create(start_node: @bob, end_node: @charlie, since_year: 2021)
    @alice_pet = HasPet.create(start_node: @alice, end_node: @charlie, animal_type: 'dog')
  end

  after do
    Object.send(:remove_const, :Person) if Object.const_defined?(:Person)
    Object.send(:remove_const, :HasFriend) if Object.const_defined?(:HasFriend)
    Object.send(:remove_const, :HasPet) if Object.const_defined?(:HasPet)
  end

  describe '.all' do
    it 'returns all edges across different edge classes' do
      # Test that calling all on the base Edge class returns edges from all subclasses
      all_edges = ApacheAge::Edge.all

      # Should find all edges we created in before block
      expect(all_edges).not_to be_empty

      # Should include edges from different classes
      edge_classes = all_edges.map(&:class).uniq
      expect(edge_classes).to include(HasFriend)
      expect(edge_classes).to include(HasPet)

      # Should find at least as many edges as we created
      expect(all_edges.size).to be >= 3 # We created 3 edges in the before block

      # Verify contents include the edges we explicitly created
      has_friend_edges = all_edges.select { |e| e.is_a?(HasFriend) }
      has_pet_edges = all_edges.select { |e| e.is_a?(HasPet) }

      expect(has_friend_edges.map(&:to_rich_h).map { |h| h[:properties][:since_year] }).to include(2020, 2021)
      expect(has_pet_edges.map(&:to_rich_h).map { |h| h[:properties][:animal_type] }).to include('dog')
    end
  end

  describe 'edge querying' do
    it 'can find edges by specific class' do
      # Verify individual edge classes work correctly
      has_friend_edges = HasFriend.all
      has_pet_edges = HasPet.all

      expect(has_friend_edges.size).to eq(2)
      expect(has_pet_edges.size).to eq(1)

      # Verify we can use to_rich_h on individual edges
      expect(has_friend_edges.first.to_rich_h[:properties][:since_year]).to be_present
      expect(has_pet_edges.first.to_rich_h[:properties][:animal_type]).to eq('dog')
    end
  end
end
