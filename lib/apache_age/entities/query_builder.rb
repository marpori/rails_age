# query =
#   Person
#     .cypher('age_schema')
#     .match("(a:Person), (b:Person)")
#     .where("a.name = 'Node A'", "b.name = 'Node B'")
#     .return("a.name", "b.name")
#     .as("name_a agtype, name_b agtype")
#     .execute
# def cypher(graph_name = 'age_schema')
#   ApacheAge::Cypher.new(graph_name)
#   self
# end

module ApacheAge
  module Entities
    class QueryBuilder
      attr_accessor :where_clauses, :order_clause, :limit_clause, :model_class, :match_clause,
                    :graph_name, :return_clause, :return_names, :return_variables,
                    :path_edge_name, :path_length, :path_properties

      def initialize(
        model_class, return_clause: nil, match_clause: nil, graph_name: nil
        # model_class, path_edge: nil, path_length: nil, path_properties: nil, return_clause: nil, match_clause: nil, graph_name: nil
      )
        # @path_edge = path_length
        # @path_length = path_length
        # @path_properties = path_properties
        @model_class = model_class
        @where_clauses = []
        @return_clause = return_clause ? return_clause : 'find'
        @return_names = [@return_clause]
        @return_variables = []
        @order_clause = nil
        @limit_clause = nil
        @match_clause = match_clause ? match_clause : model_class.match_clause
        @graph_name = graph_name || model_class.age_graph
      end

      def match(match_string)
        @match_clause = match_string
        self
      end

      def where(*args)
        return self if args.blank?

        @where_clauses <<
          # not able to sanitize the query string in this case: `["first_name = 'Barney'"]`
          if args.length == 1 && args.first.is_a?(String)
            raw_query_string = args.first
            transform_cypher_sql(raw_query_string)

          # Handling & sanitizing parameterized string queries
          elsif args.length > 1 && args.first.is_a?(String)
            raw_query_string = args.first
            # Replace `id = ?` with `id(find) = ?` and `first_name = ?` with `find.first_name = ?`
            query_string = transform_cypher_sql(raw_query_string)
            values = args[1..-1]
            # sanitize sql input values
            ActiveRecord::Base.sanitize_sql_array([query_string, *values])

          # Hashes are sanitized in the model class
          # [{:first_name=>"Barney", :last_name=>"Rubble", :gender=>"male"}]
          elsif args.first.is_a?(Hash)
            attributes = args.first
            edge_keys = [:start_id, :start_node, :end_id, :end_node]
            if edge_keys.any? { |key| attributes.include?(key) }
              model_class.send(:where_edge_clause, **attributes)
            else
              model_class.send(:where_node_clause, **attributes)
            end

          else
            raise ArgumentError, "Invalid arguments for `where` method"
          end

        self
      end

      # New return method
      def return(*variables)
        return self if variables.blank?

        @return_variables = variables
        self
      end

      def order(ordering)
        @order_clause = nil
        return self if ordering.blank?

        order_by_values = Array.wrap(ordering).map { |order| parse_ordering(order) }.join(', ')
        @order_clause = "ORDER BY #{order_by_values}"
        self
      end

      def limit(limit_value)
        @limit_clause = "LIMIT #{limit_value}"
        self
      end

      def all
        cypher_sql = build_query
        results = model_class.send(:execute_where, cypher_sql)
        return results if return_variables.empty?

        results.map(&:to_h).map { _1.slice(*return_variables) }
      end

      def execute
        cypher_sql = build_query
        model_class.send(:execute_sql, cypher_sql)
      end

      def first
        cypher_sql = build_query(limit_clause || "LIMIT 1")
        model_class.send(:execute_find, cypher_sql)
      end

      def to_sql
        build_query.strip
      end

      private

      # TODO: ensure ordering keys are present in the model
      def parse_ordering(ordering)
        if ordering.is_a?(Hash)
          ordering =
            ordering
              .map { |k, v| "find.#{k} #{ActiveRecord::Base.sanitize_sql_like(v.to_s)}" }
              .join(', ')
        elsif ordering.is_a?(Symbol)
          ordering = "find.#{ordering}"
        elsif ordering.is_a?(String)
          ordering
        elsif ordering.is_a?(Array)
          ordering = ordering.map do |order|
            if order.is_a?(Hash)
              order
                .map { |k, v| "find.#{k} #{ActiveRecord::Base.sanitize_sql_like(v.to_s)}" }
                .join(', ')
            elsif order.is_a?(Symbol)
              "find.#{order}"
            elsif order.is_a?(String)
              order
            else
              raise ArgumentError, 'Array elements must be a string, symbol, or hash'
            end
          end.join(', ')
        else
          raise ArgumentError, 'Ordering must be a string, symbol, hash, or array'
        end
      end

      def build_query(_extra_clause = nil)
        where_sql = where_clauses.any? ? "WHERE #{where_clauses.join(' AND ')}" : ''
        order_by = order_clause.present? ? order_clause : ''
        <<-SQL.squish
          SELECT *
          FROM cypher('#{graph_name}', $$
              MATCH #{match_clause}
              #{where_sql}
              RETURN #{return_clause}
              #{order_clause}
              #{limit_clause}
          $$) AS (#{return_names.join(' agtype, ')} agtype);
        SQL
      end

      def transform_cypher_sql(raw_sql_string)
        # Define the logical operators and order multi-word operators first to avoid partial splits
        operators = ['=', '>', '<', '<>', '>=', '<=', '=~', 'ENDS WITH', 'CONTAINS', 'STARTS WITH', 'IN', 'IS NULL', 'IS NOT NULL']
        separators = ["AND NOT", "OR NOT", "AND", "OR", "NOT"]

        # Combine the operators and separators into a regex pattern
        pattern = /(#{(operators + separators).map { |s| Regexp.escape(s) }.join('|')})/

        # Split the raw_sql_string string based on the pattern for operators and separators
        parts = raw_sql_string.split(pattern)

        # Process each part to identify and transform the attributes
        transformed_parts = parts.map do |part|
          # Skip transformation if part is one of the logical operators or separators
          next part if operators.include?(part.strip) || separators.include?(part.strip)

          # if string contains a dot or is an integer (plus or minus), skip transformation
          if part.include?(".") || !!(part.strip =~ /\A-?\d+\z/)
            part # Keep parts with prefixes as they are
          elsif part =~ /\s*(\w+)\s*$/
            attribute = $1
            if attribute == 'end_id'
              "id(end_node)"
            elsif attribute == 'start_id'
              "id(start_node)"
            elsif attribute == 'id'
              "id(find)"
            # attributes must start with a letter
            elsif attribute =~ /^[a-z]\w*$/
              "find.#{attribute}"
            else
              attribute
            end
          else
            part
          end
        end

        # Reassemble the string with the transformed parts
        transformed_parts.join(" ").gsub(/\s+/, ' ').strip
      end
    end
  end
end
