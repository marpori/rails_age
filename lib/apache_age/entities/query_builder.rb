# query =
#   Person.
#     cypher('age_schema')
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
                    :graph_name, :return_clause, :return_names, :return_variables

      def initialize(model_class, graph_name: nil)
        @model_class = model_class
        @where_clauses = []
        @return_names = ['find']
        @return_clause = 'find'
        @return_variables = []
        @order_clause = nil
        @limit_clause = nil
        @match_clause = model_class.match_clause
        @graph_name = graph_name || model_class.age_graph
      end

      # def cypher(graph_name = 'age_schema')
      #   return self if graph_name.blank?

      #   @graph_name = graph_name
      #   self
      # end

      def match(match_string)
        @match_clause = match_string
        self
      end

      # TODO: need to handle string inputs too: instead of: \
      # "id(find) = #{id}" & "find.name = #{name}"
      # we can have: "id(find) = ?", id & "find.name = ?", name
      # ActiveRecord::Base.sanitize_sql([query_string, v])
      def where(attributes)
        return self if attributes.blank?

        @where_clauses <<
          if attributes.is_a?(String)
            if attributes.include?('id(') || attributes.include?('find.')
              attributes
            else
              "find.#{attributes}"
            end
          else
            edge_keys = [:start_id, :start_node, :end_id, :end_node]
            if edge_keys.any? { |key| attributes.include?(key) }
              model_class.send(:where_edge_clause, attributes)
            else
              model_class.send(:where_node_clause, attributes)
            end
          end

        self
      end

      # New return method
      def return(*variables)
        return self if variables.blank?

        @return_variables = variables
        # @return_names = variables.empty? ? ['find'] : variables
        # @return_clause = variables.empty? ? 'find' : "find.#{variables.join(', find.')}"
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
      # def build_query(_extra_clause = nil)
      #   sanitized_where_sql = where_clauses.any? ? "WHERE #{where_clauses.map { |clause| ActiveRecord::Base.sanitize_sql_like(clause) }.join(' AND ')}" : ''
      #   sanitized_order_by = order_clause.present? ? ActiveRecord::Base.sanitize_sql_like(order_clause) : ''
      #   sanitized_limit_clause = limit_clause.present? ? ActiveRecord::Base.sanitize_sql_like(limit_clause) : ''

      #   <<-SQL.squish
      #     SELECT *
      #     FROM cypher('#{graph_name}', $$
      #         MATCH #{ActiveRecord::Base.sanitize_sql_like(match_clause)}
      #         #{sanitized_where_sql}
      #         RETURN #{ActiveRecord::Base.sanitize_sql_like(return_clause)}
      #         #{sanitized_order_by}
      #         #{sanitized_limit_clause}
      #     $$) AS (#{return_names.map { |name| "#{ActiveRecord::Base.sanitize_sql_like(name)} agtype" }.join(', ')});
      #   SQL
      # end
    end
  end
end
