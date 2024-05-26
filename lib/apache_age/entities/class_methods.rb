module ApacheAge
  module Entities
    module ClassMethods
      # for now we only allow one predertimed graph
      def create(attributes)
        instance = new(**attributes)
        instance.save
        instance
      end

      def find_by(attributes)
        return nil if attributes.reject{ |k,v| v.blank? }.empty?

        edge_keys = [:start_id, :start_node, :end_id, :end_node]
        return find_edge(attributes) if edge_keys.any? { |key| attributes.include?(key) }

        where_clause = attributes.map { |k, v| "find.#{k} = '#{v}'" }.join(' AND ')
        cypher_sql = find_sql(where_clause)

        execute_find(cypher_sql)
      end

      def find(id)
        where_clause = "id(find) = #{id}"
        cypher_sql = find_sql(where_clause)
        execute_find(cypher_sql)
      end

      def all
        age_results = ActiveRecord::Base.connection.execute(all_sql)
        return [] if age_results.values.count.zero?

        age_results.values.map do |result|
          json_string = result.first.split('::').first
          hash = JSON.parse(json_string)
          attribs = hash.except('label', 'properties').merge(hash['properties']).symbolize_keys

          new(**attribs)
        end
      end

      # Private stuff

      def find_edge(attributes)
        where_attribs =
          attributes
          .compact
          .except(:end_id, :start_id, :end_node, :start_node)
          .map { |k, v| "find.#{k} = '#{v}'" }.join(' AND ')
        where_attribs = where_attribs.empty? ? nil : where_attribs

        end_id = attributes[:end_id] || attributes[:end_node]&.id
        start_id = attributes[:start_id] || attributes[:start_node]&.id
        where_end_id = end_id ? "id(end_node) = #{end_id}" : nil
        where_start_id = start_id ? "id(start_node) = #{start_id}" : nil

        where_clause = [where_attribs, where_start_id, where_end_id].compact.join(' AND ')
        return nil if where_clause.empty?

        cypher_sql = find_edge_sql(where_clause)

        execute_find(cypher_sql)
      end

      def age_graph = 'age_schema'
      def age_label = name.gsub('::', '__')
      def age_type = name.constantize.new.age_type

      def match_clause
        age_type == 'vertex' ? "(find:#{age_label})" : "(start_node)-[find:#{age_label}]->(end_node)"
      end

      def execute_find(cypher_sql)
        age_result = ActiveRecord::Base.connection.execute(cypher_sql)
        return nil if age_result.values.count.zero?

        age_type = age_result.values.first.first.split('::').last
        json_data = age_result.values.first.first.split('::').first

        hash = JSON.parse(json_data)
        attribs = hash.except('label', 'properties').merge(hash['properties']).symbolize_keys

        new(**attribs)
      end

      def all_sql
        <<-SQL
        SELECT *
        FROM cypher('#{age_graph}', $$
            MATCH #{match_clause}
            RETURN find
        $$) as (#{age_label} agtype);
        SQL
      end

      def find_sql(where_clause)
        <<-SQL
          SELECT *
          FROM cypher('#{age_graph}', $$
              MATCH #{match_clause}
              WHERE #{where_clause}
              RETURN find
          $$) as (#{age_label} agtype);
        SQL
      end

      def find_edge_sql(where_clause)
        <<-SQL
          SELECT *
          FROM cypher('#{age_graph}', $$
              MATCH #{match_clause}
              WHERE #{where_clause}
              RETURN find
          $$) as (#{age_label} agtype);
        SQL
      end
    end
  end
end
