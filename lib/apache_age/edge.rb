module ApacheAge
  class Edge
    include ApacheAge::Entities::Edge

    class << self
      def age_type = 'edge'

      def ensure_query_builder!
        @query_builder ||= ApacheAge::Entities::QueryBuilder.new(self)
      end

      def cypher(edge_class, graph_name: nil)
        @query_builder = ApacheAge::Entities::QueryBuilder.new(edge_class, graph_name:)
        self
      end

      def match(match_string)
        ensure_query_builder!
        @query_builder.match(match_string)
        self
      end

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
    end
  end
end
