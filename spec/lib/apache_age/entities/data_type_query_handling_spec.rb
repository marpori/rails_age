# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apache AGE Data Type Handling' do
  before do
    # Define test node classes with various data types
    class TypeTestNode
      include ApacheAge::Entities::Node

      attribute :string_attr, :string
      attribute :integer_attr, :integer
      attribute :decimal_attr, :decimal
      attribute :date_attr, :date
      attribute :datetime_attr, :datetime
      attribute :boolean_attr, :boolean
      # attribute :array_attr, :array
      # attribute :hash_attr, :hash
      # attribute :json_attr, :json
    end

    class TypeTestEdge
      include ApacheAge::Entities::Edge

      attribute :string_attr, :string
      attribute :integer_attr, :integer
      attribute :decimal_attr, :decimal
      attribute :date_attr, :date
      attribute :datetime_attr, :datetime
      attribute :boolean_attr, :boolean
      # attribute :array_attr, :array
      # attribute :hash_attr, :hash
      # attribute :json_attr, :json
      attribute :start_node
      attribute :end_node
    end

    # Create test data with various types
    @today = Date.today
    @now = DateTime.now
    @node1 = TypeTestNode.create(
      string_attr: 'test string',
      integer_attr: 42,
      decimal_attr: 3.14159,
      date_attr: @today,
      datetime_attr: @now,
      boolean_attr: true,
      # array_attr: [1, 2, 3],
      # hash_attr: { key: 'value', nested: { data: [1, 2, 3] } }
      # hash_attr: { key: 'value', nested: { data: [1, 2, 3] } }
    )

    @node2 = TypeTestNode.create(
      string_attr: 'another string',
      integer_attr: 100,
      decimal_attr: 2.71828,
      date_attr: @today - 1,
      datetime_attr: @now - 1,
      boolean_attr: false,
      # array_attr: [4, 5, 6],
      # hash_attr: { different: 'data' }
      # json_attr: { different: 'data' }
    )

    @edge = TypeTestEdge.create(
      start_node: @node1,
      end_node: @node2,
      string_attr: 'edge string',
      integer_attr: 123,
      decimal_attr: 9.8765,
      date_attr: @today,
      datetime_attr: @now,
      boolean_attr: true,
      # array_attr: %w[Nyima Pema Tenzin],
      # hash_attr: { edge: 'data' }
      # json_attr: { edge: 'data' }
    )
  end

  after do
    Object.send(:remove_const, :TypeTestNode) if Object.const_defined?(:TypeTestNode)
    Object.send(:remove_const, :TypeTestEdge) if Object.const_defined?(:TypeTestEdge)
  end

  context 'Node queries with type-specific filtering' do
    it 'correctly filters by string attributes' do
      result = TypeTestNode.where(string_attr: 'test string').all
      expect(result).not_to be_empty
      expect(result.first.string_attr).to eq('test string')

      # Verify SQL has proper string quoting
      sql = TypeTestNode.where(string_attr: 'test string').to_sql
      expect(sql).to include("find.string_attr = 'test string'")
    end

    it 'correctly filters by integer attributes' do
      result = TypeTestNode.where(integer_attr: 42).all
      expect(result).not_to be_empty
      expect(result.first.integer_attr).to eq(42)

      # Verify SQL has numeric format without quotes
      sql = TypeTestNode.where(integer_attr: 42).to_sql
      expect(sql).to include('find.integer_attr = 42')
      expect(sql).not_to include('\'42\'')
    end

    it 'correctly filters by decimal attributes' do
      result = TypeTestNode.where(decimal_attr: 3.14159).all
      expect(result).not_to be_empty
      expect(result.first.decimal_attr).to be_within(0.00001).of(3.14159)

      # Verify SQL has numeric format without quotes
      sql = TypeTestNode.where(decimal_attr: 3.14159).to_sql
      expect(sql).to include('find.decimal_attr = 3.14159')
      expect(sql).not_to include('\'3.14159\'')
    end

    it 'correctly filters by date attributes' do
      result = TypeTestNode.where(date_attr: @today).all
      expect(result).not_to be_empty
      expect(result.first.date_attr).to eq(@today)

      # Verify SQL has proper date format
      sql = TypeTestNode.where(date_attr: @today).to_sql
      formatted_date = @today.strftime('%Y-%m-%d')
      expect(sql).to include("find.date_attr = '#{formatted_date}'")
    end

    it 'correctly filters by datetime attributes' do
      # Datetime precision can be an issue, so use a range or format properly
      formatted_datetime = @now.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')
      sql = TypeTestNode.where(datetime_attr: @now).to_sql
      expect(sql).to include("find.datetime_attr = '#{formatted_datetime}'")

      # Try querying with a properly formatted datetime
      result = TypeTestNode.where(datetime_attr: @now).all
      expect(result).not_to be_empty
    end

    it 'correctly filters by boolean attributes' do
      result = TypeTestNode.where(boolean_attr: true).all
      expect(result).not_to be_empty
      expect(result.first.boolean_attr).to eq(true)

      # Verify SQL has proper boolean format
      sql = TypeTestNode.where(boolean_attr: true).to_sql
      expect(sql).to include('find.boolean_attr = true')
      expect(sql).not_to include('\'true\'')
    end
  end

  context 'Edge queries with type-specific filtering' do
    it 'correctly filters by string attributes' do
      result = TypeTestEdge.where(string_attr: 'edge string').all
      expect(result).not_to be_empty
      expect(result.first.string_attr).to eq('edge string')
    end

    it 'correctly filters by integer attributes' do
      result = TypeTestEdge.where(integer_attr: 123).all
      expect(result).not_to be_empty
      expect(result.first.integer_attr).to eq(123)

      # Verify SQL has numeric format without quotes
      sql = TypeTestEdge.where(integer_attr: 123).to_sql
      expect(sql).to include('find.integer_attr = 123')
      expect(sql).not_to include('\'123\'')
    end

    it 'correctly filters edge by start_node properties' do
      # Test filtering by start node properties - this requires the special handling
      result = TypeTestEdge.where(start_node: { string_attr: 'test string' }).all
      expect(result).not_to be_empty
      expect(result.first.start_node.string_attr).to eq('test string')
    end
  end

  context 'Complex queries with multiple data types' do
    it 'correctly handles queries with multiple attribute types' do
      result = TypeTestNode.where(
        string_attr: 'test string',
        integer_attr: 42,
        boolean_attr: true
      ).all

      expect(result).not_to be_empty
      expect(result.first.string_attr).to eq('test string')
      expect(result.first.integer_attr).to eq(42)
      expect(result.first.boolean_attr).to eq(true)

      # Verify the SQL has proper types for each attribute
      sql = TypeTestNode.where(
        string_attr: 'test string',
        integer_attr: 42,
        boolean_attr: true
      ).to_sql

      expect(sql).to include("find.string_attr = 'test string'")
      expect(sql).to include('find.integer_attr = 42')
      expect(sql).to include('find.boolean_attr = true')
    end
  end
end
