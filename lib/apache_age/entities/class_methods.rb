module ApacheAge
  module Entities
    module ClassMethods
      # for now we only allow one predertimed graph
      def create(attributes)
        instance = new(**attributes)
        instance.save
        instance
      end

      def where(*attributes)
        query_builder = QueryBuilder.new(self)
        query_builder.where(*attributes)
      end

      def all = QueryBuilder.new(self).all
      def first = QueryBuilder.new(self).limit(1).first
      def find(id) = where(id: id).first

      def find_by(attributes)
        return nil if attributes.reject { |k, v| v.blank? }.empty?

        where(attributes).limit(1).first
      end

      # Private stuff

      # used? or dead code?
      def where_edge(attributes)
        where_attribs =
          attributes
            .compact
            .except(:end_id, :start_id, :end_node, :start_node)
            .map { |k, v| ActiveRecord::Base.sanitize_sql(["find.#{k} = ?", v]) }
            .join(' AND ')
        where_attribs = where_attribs.empty? ? nil : where_attribs

        end_id = attributes[:end_id] || attributes[:end_node]&.id
        start_id = attributes[:start_id] || attributes[:start_node]&.id
        where_end_id = end_id ? ActiveRecord::Base.sanitize_sql(["id(end_node) = ?", end_id]) : nil
        where_start_id = start_id ? ActiveRecord::Base.sanitize_sql(["id(start_node) = ?", start_id]) : nil

        where_clause = [where_attribs, where_start_id, where_end_id].compact.join(' AND ')
        return nil if where_clause.empty?

        cypher_sql = edge_sql(where_clause)

        execute_where(cypher_sql)
      end

      def age_graph = 'age_schema'
      def age_label = name.gsub('::', '__')
      def age_type = name.constantize.new.age_type

      def match_clause
        age_type == 'vertex' ? "(find:#{age_label})" : "(start_node)-[find:#{age_label}]->(end_node)"
      end

      def execute_sql(cypher_sql) = ActiveRecord::Base.connection.execute(cypher_sql)

      def execute_find(cypher_sql) = execute_where(cypher_sql).first

      def execute_where(cypher_sql)
        age_results = ActiveRecord::Base.connection.execute(cypher_sql)
        return [] if age_results.values.count.zero?

        age_results.values.map do |value|
          json_data = value.first.split('::').first
          hash = JSON.parse(json_data)
          attribs = hash.except('label', 'properties').merge(hash['properties']).symbolize_keys

          new(**attribs)
        end
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

      def node_sql(where_clause)
        <<-SQL
          SELECT *
          FROM cypher('#{age_graph}', $$
              MATCH #{match_clause}
              WHERE #{where_clause}
              RETURN find
          $$) as (#{age_label} agtype);
        SQL
      end

      def edge_sql(where_clause)
        <<-SQL
          SELECT *
          FROM cypher('#{age_graph}', $$
              MATCH #{match_clause}
              WHERE #{where_clause}
              RETURN find
          $$) as (#{age_label} agtype);
        SQL
      end

      private

      def where_node_clause(attributes)
        build_core_where_clause(attributes)
      end

      def where_edge_clause(attributes)
        core_attributes = attributes.except(:end_id, :start_id, :end_node, :start_node)
        core_clauses = core_attributes.empty? ? nil : build_core_where_clause(core_attributes)

        end_id =
          if attributes[:end_id]
            attributes[:end_id]
          elsif attributes[:end_node].is_a?(Node)
            attributes[:end_node]&.id
          end
        where_end_id = end_id ? ActiveRecord::Base.sanitize_sql(["id(end_node) = ?", end_id]) : nil

        start_id =
          if attributes[:start_id]
            attributes[:start_id]
          elsif attributes[:start_node].is_a?(Node)
            attributes[:start_node]&.id
          end
        where_start_id = start_id ? ActiveRecord::Base.sanitize_sql(["id(start_node) = ?", start_id]) : nil

        where_end_attrs =
          if attributes[:end_node].is_a?(Hash)
            attributes[:end_node].map { |k, v| ActiveRecord::Base.sanitize_sql(["end_node.#{k} = ?", v]) }
          end
        where_start_attrs =
          if attributes[:start_node].is_a?(Hash)
            attributes[:start_node].map { |k, v| ActiveRecord::Base.sanitize_sql(["start_node.#{k} = ?", v]) }
          end

        [core_clauses, where_start_id, where_end_id, where_start_attrs, where_end_attrs]
          .flatten.compact.join(' AND ')
      end


      def build_core_where_clause(attributes)
        attributes
          .compact
          .map do |k, v|
            query_string = k == :id ? "id(find) = #{v}" : "find.#{k} = '#{v}'"
            ActiveRecord::Base.sanitize_sql([query_string, v])
          end
          .join(' AND ')
      end
    end
  end
end
