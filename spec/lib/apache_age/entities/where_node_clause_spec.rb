# spec/lib/apache_age/entities/where_node_clause_spec.rb
require 'rails_helper'

RSpec.describe "where_node_clause special handling" do
  before do
    # Define test node classes
    class Person
      include ApacheAge::Entities::Node
      attribute :name, :string
    end

    class HasFriend
      include ApacheAge::Entities::Edge
      attribute :since_year, :integer
      attribute :start_node
      attribute :end_node
    end

    # Create test data
    @john = Person.create(name: 'John')
    @jane = Person.create(name: 'Jane')
    @bob = Person.create(name: 'Bob')

    @john_friend_jane = HasFriend.create(start_node: @john, end_node: @jane, since_year: 2020)
    @jane_friend_bob = HasFriend.create(start_node: @jane, end_node: @bob, since_year: 2021)
  end

  after do
    Object.send(:remove_const, :Person) if Object.const_defined?(:Person)
    Object.send(:remove_const, :HasFriend) if Object.const_defined?(:HasFriend)
  end

  context 'when querying edges with start_node hash properties' do
    it 'generates correct SQL for start_node property filtering' do
      # This query should find edges where the start node has name='John'
      query = HasFriend.where(start_node: { name: 'John' })

      # Convert to SQL to inspect the query
      sql = query.to_sql

      # The SQL should include proper filtering for start_node
      # If the special handling is needed, this would produce a query that searches
      # for start_node.name = 'John'
      expect(sql).to include('start_node.name')
      expect(sql).to include("'John'")
      # "SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:HasFriend]->(end_node) WHERE start_node.name = 'John' RETURN find $$) AS (find agtype);"

      # If special handling works, this should find our edge
      results = query.all
      expect(results).not_to be_empty
      expect(results.first.start_node.name).to eq('John')
    end
  end
end
