module ApacheAge
  module Entities
    module Path
      extend ActiveSupport::Concern

      included do
        extend ApacheAge::Entities::ClassMethods
        include ApacheAge::Entities::CommonMethods
      end

      def age_type = 'path'

      def match_clause
        "path = (start_node)-[#{path_edge}#{path_length}#{path_properties}]->(end_node)"
      end

      def match(match_string)
        @match_clause = match_string
        self
      end

      # Delegate additional methods like `where`, `limit`, etc., to `QueryBuilder`
      def where(*args)
        @query_builder.where(*args)
        self
      end

      def order(ordering)
        @query_builder.order(ordering)
        self
      end

      def limit(limit_value)
        @query_builder.limit(limit_value)
        self
      end

      def return(*variables)
        @query_builder.return(*variables)
        self
      end

      # Executes the query and returns results
      def execute
        @query_builder.execute
      end

      def first
        @query_builder.first
      end

      def all
        @query_builder.all
      end

      # Build the final SQL query
      def to_sql
        @query_builder.to_sql
      end

      private

      def execute_where(cypher_sql)
        age_results = ActiveRecord::Base.connection.execute(cypher_sql)
        binding.irb
        return [] if age_results.values.count.zero?

        age_results.values.map do |value|
          json_data = value.first.split('::').first
          hash = JSON.parse(json_data)
          attribs = hash.except('label', 'properties').merge(hash['properties']).symbolize_keys

          new(**attribs)
        end
      end
    end
  end
end
