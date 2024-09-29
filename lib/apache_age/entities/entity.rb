module ApacheAge
  module Entities
    class Entity
      class << self
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
