module ApacheAge
  module Entities
    class Entity
      class << self
        def ensure_query_builder!
          @query_builder ||= ApacheAge::Entities::QueryBuilder.new(self)
        end

        def find_by(attributes)
          where_clause =
            attributes
              .map do |k, v|
                if k == :id
                  ActiveRecord::Base.sanitize_sql(["id(find) = ?", v])
                else
                  ActiveRecord::Base.sanitize_sql(["find.#{k} = ?", v])
                end
              end
              .join(' AND ')
          handle_find(where_clause)
        end

        def find(id) = find_by(id: id)

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

        private

        def age_graph = 'age_schema'

        def handle_find(where_clause)
          # try to find a vertex
          match_node = '(find)'
          cypher_sql = find_sql(match_node, where_clause)
          age_response = execute_find(cypher_sql)

          if age_response.nil?
            # if not a vertex try to find an edge
            match_edge = '()-[find]->()'
            cypher_sql = find_sql(match_edge, where_clause)
            age_response = execute_find(cypher_sql)
            return nil if age_response.nil?
          end

          instantiate_result(age_response)
        end

        def execute_find(cypher_sql)
          age_result = ActiveRecord::Base.connection.execute(cypher_sql)
          return nil if age_result.values.first.nil?

          age_result
        end

        def instantiate_result(age_response)
          age_type = age_response.values.first.first.split('::').last
          json_string = age_response.values.first.first.split('::').first
          json_data = JSON.parse(json_string)

          age_label = json_data['label']
          attribs =
            json_data
              .except('label', 'properties')
              .merge(json_data['properties'])
              .symbolize_keys

          "#{json_data['label'].gsub('__', '::')}".constantize.new(**attribs)
        end

        def find_sql(match_clause, where_clause)
          sanitized_match_clause = ActiveRecord::Base.sanitize_sql(match_clause)
          sanitized_where_clause = where_clause # Already sanitized in `find_by` or `find`

          <<-SQL
            SELECT *
            FROM cypher('#{age_graph}', $$
                MATCH #{sanitized_match_clause}
                WHERE #{sanitized_where_clause}
                RETURN find
            $$) as (found agtype);
          SQL
        end
      end
    end
  end
end
