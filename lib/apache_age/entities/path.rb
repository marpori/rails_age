module ApacheAge
  module Entities
    module Path
      extend ActiveSupport::Concern

      included do
        extend ApacheAge::Entities::ClassMethods
        include ApacheAge::Entities::CommonMethods
      end

      def age_type = 'path'

      def ensure_query_builder!
        @query_builder ||= ApacheAge::Entities::QueryBuilder.new(self.class)
      end

      def match_clause
        "path = (start_node)-[#{path_edge}#{path_length}#{path_properties}]->(end_node)"
      end

      def match(match_string)
        @match_clause = match_string
        self
      end

      # Delegate additional methods like `where`, `limit`, etc., to `QueryBuilder`
      def where(*args)
        ensure_query_builder!
        @query_builder.where(*args)
        self
      end

      def order(ordering)
        ensure_query_builder!
        @query_builder.order(ordering)
        self
      end

      def limit(limit_value)
        ensure_query_builder!
        @query_builder.limit(limit_value)
        self
      end

      def return(*variables)
        ensure_query_builder!
        @query_builder.return(*variables)
        self
      end

      # transforms the query and returns results
      def execute
        ensure_query_builder!
        @query_builder.execute
      end

      def first
        ensure_query_builder!
        @query_builder.first
      end

      def all
        ensure_query_builder!
        @query_builder.all
      end

      def to_sql
        ensure_query_builder!
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
