module ApacheAge
  class Node
    include ApacheAge::Entities::Node

    attribute :label, :string
    attribute :properties
    # attribute :properties, :hash

    # def display = [label, properties&.values&.first].compact.join(' - ')
    def display
      info = properties&.values&.first
      info.blank? ? "#{label} (#{id})" : "#{info} (#{label})"
    end

    class << self
      def age_type = 'vertex'

      def ensure_query_builder!
        @query_builder ||= ApacheAge::Entities::QueryBuilder.new(@node_class || self)
      end

      def cypher(node_class: nil, graph_name: nil)
        @node_class = node_class || self
        @query_builder = ApacheAge::Entities::QueryBuilder.new(@node_class, graph_name:)
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
